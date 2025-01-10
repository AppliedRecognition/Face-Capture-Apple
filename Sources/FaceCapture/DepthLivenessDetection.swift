//
//  DepthLivenessDetection.swift
//  FaceCapture
//
//  Created by Jakub Dolejs on 13/11/2024.
//

import Foundation
import AVFoundation
import Accelerate

public class DepthLivenessDetection: FaceTrackingPlugin {
    public var name: String {
        "Depth-based liveness detection"
    }
    
    public init() {}
    
    public func processFaceTrackingResult(_ faceTrackingResult: FaceTrackingResult) async throws -> Bool {
        switch faceTrackingResult {
        case .faceAligned(let trackedFaceSessionProperties), .faceCaptured(let trackedFaceSessionProperties):
            guard let depthData = trackedFaceSessionProperties.input.image.depthData else {
                return false
            }
            let face = trackedFaceSessionProperties.face.withBoundsSetToAspectRatio(4/5)
            guard face.noseTip != nil, face.mouthCentre != nil else {
                return false
            }
            let imageSize = trackedFaceSessionProperties.input.image.size
            let depthSize = CGSize(width: CVPixelBufferGetWidth(depthData.depthDataMap), height: CVPixelBufferGetHeight(depthData.depthDataMap))
            let scaleX = depthSize.width/imageSize.width
            let scaleY = depthSize.height/imageSize.height
            let scaleTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)
            let depthFace = face.applying(scaleTransform)
            if let landmarkDepths = self.depthAtPoints([depthFace.leftEye, depthFace.rightEye, depthFace.noseTip!, depthFace.mouthCentre!], depthData: depthData.depthDataMap), !landmarkDepths[0...3].contains(where: { depth in depth.isNaN || depth.isInfinite || depth <= 0 }) {
                if landmarkDepths[2] < 0.015 {
                    throw FaceCaptureError.passiveLivenessCheckFailed("Face is close to the camera")
                } else if landmarkDepths[2] > 1.5 {
                    throw FaceCaptureError.passiveLivenessCheckFailed("Face is too far from the camera")
                }
                let mouthEyePlaneDepth = (landmarkDepths[0] + landmarkDepths[1] + landmarkDepths[3]) / 3
                if mouthEyePlaneDepth - landmarkDepths[2] < 0.02 {
                    throw FaceCaptureError.passiveLivenessCheckFailed("Face doesn't match expected topography")
                }
                return true
            }
        default:
            return false
        }
        return false
    }
    
    public func createSummaryFromResults(_ results: [FaceTrackingPluginResult<Bool>]) async -> String {
        if !results.contains(where: { $0.result }) {
            return "Liveness check not performed"
        }
        return "Liveness check passed"
    }
    
    public typealias Element = Bool
    
    private func depthAtPoints(_ points: [CGPoint], depthData: CVPixelBuffer) -> [Float]? {
        let rowLength = CVPixelBufferGetBytesPerRow(depthData) / 4
        let width = CVPixelBufferGetWidth(depthData)
        let height = CVPixelBufferGetHeight(depthData)
        CVPixelBufferLockBaseAddress(depthData, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(depthData, .readOnly)
        }
        guard let depthBuffer = CVPixelBufferGetBaseAddress(depthData)?.assumingMemoryBound(to: Float32.self) else {
            return nil
        }
        return points.map { pt in
            var depths: [Float] = []
            for y in Int(pt.y)-1...Int(pt.y)+1 {
                if y < 0 || y >= height {
                    continue
                }
                for x in Int(pt.x)-1...Int(pt.x)+1 {
                    if x < 0 || x >= width {
                        continue
                    }
                    let index = y * rowLength + x
                    let depth = depthBuffer[index]
                    if !depth.isNaN && depth.isFinite && depth > 0 {
                        depths.append(depth)
                    }
                }
            }
            if depths.isEmpty {
                return .nan
            }
            return vDSP.mean(depths)
//            let x = Int(pt.x)
//            let y = Int(pt.y)
//            let index = y * rowLength + x
//            if index >= depthBufferSize {
//                return .nan
//            }
//            let depth = depthBuffer[index]
//            return depth
        }
    }
    
    private func transformForOrientation(_ orientation: CGImagePropertyOrientation, width: CGFloat, height: CGFloat) -> CGAffineTransform {
        var transform = CGAffineTransform.identity
        switch orientation {
        case .up:
            // No transformation needed
            return transform
        case .upMirrored:
            // Flip horizontally
            transform = transform.translatedBy(x: width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .down:
            // Rotate 180 degrees
            transform = transform.translatedBy(x: width, y: height)
            transform = transform.rotated(by: .pi)
        case .downMirrored:
            // Flip vertically
            transform = transform.translatedBy(x: 0, y: height)
            transform = transform.scaledBy(x: 1, y: -1)
        case .left:
            // Rotate 90 degrees counterclockwise, then translate
            transform = transform.translatedBy(x: 0, y: height)
            transform = transform.rotated(by: -.pi / 2)
        case .leftMirrored:
            // Flip vertically, then rotate 90 degrees counterclockwise
            transform = transform.translatedBy(x: height, y: height)
            transform = transform.scaledBy(x: 1, y: -1)
            transform = transform.rotated(by: -.pi / 2)
        case .right:
            // Rotate 90 degrees clockwise, then translate
            transform = transform.translatedBy(x: width, y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .rightMirrored:
            // Flip horizontally, then rotate 90 degrees clockwise
            transform = transform.translatedBy(x: width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            transform = transform.rotated(by: .pi / 2)
        }
        return transform
    }
}
