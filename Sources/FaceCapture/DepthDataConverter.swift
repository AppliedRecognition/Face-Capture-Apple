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

class DepthDataConverter {
    
    static let `default` = DepthDataConverter()
    
    private init() {
    }
    
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
    
    func pixelBufferFromDepthData(_ depthData: AVDepthData) -> CVPixelBuffer {
        let convertedDepthData = depthData.depthDataType == kCVPixelFormatType_DisparityFloat32 ?
        depthData : depthData.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32)
        return convertedDepthData.depthDataMap
    }
    
    func transformCoordinate(x: Int, y: Int, radius: Int, from sourceSize: CGSize, to targetSize: CGSize) -> (Int, Int, Int) {
        let scaleX = targetSize.width / sourceSize.width
        let scaleY = targetSize.height / sourceSize.height
        
        let transformedX = Int(CGFloat(x) * scaleX)
        let transformedY = Int(CGFloat(y) * scaleY)
        
        return (transformedX, transformedY, Int(CGFloat(radius) * max(scaleX, scaleY)))
    }
    
    func median(of values: [Float32]) -> Float32? {
        if values.isEmpty {
            return nil
        }
        var sortedValues = values
        vDSP.sort(&sortedValues, sortOrder: .ascending)
        let count = sortedValues.count
        let midIndex = count / 2
        if count % 2 == 0 {
            // If the count is even, take the average of the two middle values
            return (sortedValues[midIndex - 1] + sortedValues[midIndex]) / 2
        } else {
            // If the count is odd, return the middle value
            return sortedValues[midIndex]
        }
    }
    
    func medianDepthInCircle(atX x: Int, y: Int, radius: Int, depthPixelBuffer: CVPixelBuffer) -> Float32? {
        CVPixelBufferLockBaseAddress(depthPixelBuffer, .readOnly)
        
        defer {
            CVPixelBufferUnlockBaseAddress(depthPixelBuffer, .readOnly)
        }
        
        let width = CVPixelBufferGetWidth(depthPixelBuffer)
        let height = CVPixelBufferGetHeight(depthPixelBuffer)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthPixelBuffer) else {
            return nil
        }
        
        let floatBuffer = baseAddress.assumingMemoryBound(to: Float32.self)
        var depthValues: [Float32] = []
        
        // Iterate over all the pixels within the bounding box of the circle
        for deltaY in -radius...radius {
            for deltaX in -radius...radius {
                let distanceSquared = deltaX * deltaX + deltaY * deltaY
                
                // Check if the point is within the circle
                if distanceSquared <= radius * radius {
                    let currentX = x + deltaX
                    let currentY = y + deltaY
                    
                    // Ensure the current point is within bounds of the depth map
                    if currentX >= 0, currentX < width, currentY >= 0, currentY < height {
                        let index = currentY * width + currentX
                        let depthValue = floatBuffer[index]
                        
                        // Ensure the depth value is valid
                        if depthValue.isFinite {
                            depthValues.append(depthValue)
                        }
                    }
                }
            }
        }
        
        // Calculate and return the median of the collected depth values
        return median(of: depthValues)
    }
    
    func medianDepthAtRGBCoordinate(x: Int, y: Int, radius: Int, ofCapture capture: Capture) -> Float32? {
        guard let depthData = capture.depth else {
            return nil
        }
        let depthPixelBuffer = pixelBufferFromDepthData(depthData)
        let colourSize = CGSize(width: CVPixelBufferGetWidth(capture.video), height: CVPixelBufferGetHeight(capture.video))
        let depthSize = CGSize(width: CVPixelBufferGetWidth(depthPixelBuffer), height: CVPixelBufferGetHeight(depthPixelBuffer))
        let (depthX, depthY, depthRadius) = transformCoordinate(x: x, y: y, radius: radius, from: colourSize, to: depthSize)
        return medianDepthInCircle(atX: depthX, y: depthY, radius: depthRadius, depthPixelBuffer: depthPixelBuffer)
    }
    
    func computeRealWorldCoordinates(
        pixelX: Double,
        pixelY: Double,
        depth: Double,
        intrinsicMatrix: [Double],
        lensDistortionCoefficients: [Double],
        inverseLensDistortionCoefficients: [Double],
        lensDistortionCenterOffsetX: Double,
        lensDistortionCenterOffsetY: Double
    ) -> (Double, Double, Double)? {
        
        // Check if the intrinsic matrix is valid
        guard intrinsicMatrix.count == 9 else {
            print("Invalid intrinsic matrix size")
            return nil
        }
        
        // Extract intrinsic matrix components
        let fx = intrinsicMatrix[0]
        let fy = intrinsicMatrix[4]
        let cx = intrinsicMatrix[6]
        let cy = intrinsicMatrix[7]
        
        // Step 1: Normalize pixel coordinates
        var x = (pixelX - cx) / fx
        var y = (pixelY - cy) / fy
        
        // Step 2: Correct for lens distortion
        let r2 = x * x + y * y
        let r4 = r2 * r2
        let r6 = r4 * r2
        
        // Apply distortion coefficients
        let radialDistortion = 1.0
        + lensDistortionCoefficients[0] * r2
        + lensDistortionCoefficients[1] * r4
        + lensDistortionCoefficients[2] * r6
        let tangentialX = 2.0 * lensDistortionCoefficients[3] * x * y
        + lensDistortionCoefficients[4] * (r2 + 2.0 * x * x)
        let tangentialY = lensDistortionCoefficients[3] * (r2 + 2.0 * y * y)
        + 2.0 * lensDistortionCoefficients[4] * x * y
        
        // Adjust coordinates using distortion model
        x = x * radialDistortion + tangentialX
        y = y * radialDistortion + tangentialY
        
        // Step 3: Compute real-world coordinates
        let realX = x * depth
        let realY = y * depth
        let realZ = depth
        
        return (realX, realY, realZ)
    }
    
//    // Example Usage:
//    
//    // Metadata values (from provided example)
//    let intrinsicMatrix = [
//        2734.900634765625, 0.0, 0.0,
//        0.0, 2734.900634765625, 0.0,
//        2041.6285400390625, 1134.53662109375, 1.0
//    ]
//    let lensDistortionCoefficients = [
//        0.00038521739770658314, 0.24750156700611115, -1.3644849061965942,
//        0.85955530405044556, -0.25958612561225891, 0.04474320262670517,
//        -0.0043115015141665936, 0.00017912888142745942
//    ]
//    let inverseLensDistortionCoefficients = [
//        -0.00066718010930344462, -0.24177467823028564, 1.35162353515625,
//         -0.86382251977920532, 0.26964312791824341, -0.048654448240995407,
//         0.004907932598143816, -0.00021185289369896054
//    ]
//    let lensDistortionCenterOffsetX = 2041.6285400390625
//    let lensDistortionCenterOffsetY = 1134.53662109375
//    
//    // Input pixel coordinates and depth value
//    let pixelX = 1500.0
//    let pixelY = 800.0
//    let depth = 2.0 // Meters

}
