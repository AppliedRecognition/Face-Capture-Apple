//
//  DepthDataConverter.swift
//  FaceCapture
//
//  Created by Jakub Dolejs on 02/10/2024.
//

import Foundation
import Accelerate
import simd
import AVFoundation

func pointCloudFromDepthData(_ depthData: AVDepthData) -> [simd_float3]? {
    guard #available(iOS 14, *) else {
        return nil
    }
    let depthDataMap = depthData.depthDataMap
    guard let cameraCalibrationData = depthData.cameraCalibrationData else {
        return nil
    }
    CVPixelBufferLockBaseAddress(depthDataMap, .readOnly)
    defer {
        CVPixelBufferUnlockBaseAddress(depthDataMap, .readOnly)
    }
    let width = CVPixelBufferGetWidth(depthDataMap)
    let height = CVPixelBufferGetHeight(depthDataMap)
    let baseAddress = CVPixelBufferGetBaseAddress(depthDataMap)!
    let format = CVPixelBufferGetPixelFormatType(depthDataMap)
    
    let depthPointer = baseAddress.assumingMemoryBound(to: Float32.self)
    
    let scaleX = Float(width) / Float(cameraCalibrationData.intrinsicMatrixReferenceDimensions.width)
    let scaleY = Float(height) / Float(cameraCalibrationData.intrinsicMatrixReferenceDimensions.height)
    
    let fx = cameraCalibrationData.intrinsicMatrix[0][0] * scaleX
    let fy = cameraCalibrationData.intrinsicMatrix[1][1] * scaleY
    let cx = cameraCalibrationData.intrinsicMatrix[2][0] * scaleX
    let cy = cameraCalibrationData.intrinsicMatrix[2][1] * scaleY
    
    var points = [simd_float3]()
    for y in 0..<height {
        for x in 0..<width {
            let depth = depthPointer[y * width + x]
            if depth <= 0 {
                continue
            }
            let X_camera = (Float(x) - cx) * depth / fx
            let Y_camera = (Float(y) - cy) * depth / fy
            let Z_camera = depth
            let pointCamera = simd_float3(X_camera, Y_camera, Z_camera)
            
            let pointWorld = cameraCalibrationData.extrinsicMatrix * simd_float4(pointCamera.x, pointCamera.y, pointCamera.z, 0.0)
            
            points.append(pointWorld)
        }
    }
    
    return points
}
