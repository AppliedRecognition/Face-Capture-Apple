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
            let points3d = self.points3Dfrom2D([depthFace.leftEye, depthFace.rightEye, depthFace.mouthCentre!, depthFace.noseTip!] + depthFace.landmarks, depthData: depthData.depthDataMap)
            if !points3d[3].z.isNaN && points3d[3].z > 1.5 {
                throw FaceCaptureError.passiveLivenessCheckFailed("Face is not within the expected camera range")
            }
            let planePoints = Array(points3d[0..<3]).filter({ !$0.z.isNaN })
            let testPoints = points3d.dropFirst(3).filter { !$0.z.isNaN && !planePoints.contains($0) }
            return try self.checkFaceIs3D(planePoints: planePoints, testPoints: testPoints)
        default:
            return false
        }
    }
    
    public func createSummaryFromResults(_ results: [FaceTrackingPluginResult<Bool>]) async -> String {
        if !results.contains(where: { $0.result }) {
            return "Liveness check not performed"
        }
        return "Liveness check passed"
    }
    
    public typealias Element = Bool
    
    private func checkFaceIs3D(planePoints: [Point3D], testPoints: [Point3D], planeDistThreshold: CGFloat = 0.02) throws -> Bool {
        if (planePoints.count != 3 || testPoints.isEmpty) {
            return false
        }
        let p1 = planePoints[0]
        let p2 = planePoints[1]
        let p3 = planePoints[2]
        let v1 = Point3D(x: p2.x - p1.x, y: p2.y - p1.y, z: p2.z - p1.z)
        let v2 = Point3D(x: p3.x - p1.x, y: p3.y - p1.y, z: p3.z - p1.z)
        let normal = Point3D(
            x: v1.y * v2.z - v1.z * v2.y,
            y: v1.z * v2.x - v1.x * v2.z,
            z: v1.x * v2.y - v1.y * v2.x
        )
        func distanceToPlane(_ pt: Point3D) -> CGFloat {
            let d = (normal.x * (pt.x - p1.x)
                     + normal.y * (pt.y - p1.y)
                     + normal.z * (pt.z - p1.z))
            let normLen = sqrt(normal.x*normal.x + normal.y*normal.y + normal.z*normal.z)
            return abs(d) / normLen
        }
        if testPoints.count == 1 {
            if distanceToPlane(testPoints[0]) > planeDistThreshold {
                return true
            }
        } else {
            let distances = testPoints.map { Double(distanceToPlane($0)) }
            let mean = vDSP.mean(distances)
            let variance = vDSP.mean(distances.map { ($0 - mean) * ($0 - mean) })
            let stdDev = sqrt(variance)
            if stdDev > planeDistThreshold {
                return true
            }
        }
        throw FaceCaptureError.passiveLivenessCheckFailed("Face doesn't match expected topography")
    }
    
    private func points3Dfrom2D(_ points: [CGPoint], depthData: CVPixelBuffer) -> [Point3D] {
        let rowLength = CVPixelBufferGetBytesPerRow(depthData) / 4
        let height = CVPixelBufferGetHeight(depthData)
        CVPixelBufferLockBaseAddress(depthData, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(depthData, .readOnly)
        }
        guard let depthBuffer = CVPixelBufferGetBaseAddress(depthData)?.assumingMemoryBound(to: Float32.self) else {
            return points.map { pt in Point3D(x: pt.x, y: pt.y, z: .nan)}
        }
        return points.map { pt in
            let index = Int(pt.y) * rowLength + Int(pt.x)
            guard index >= 0 && index < height * rowLength else {
                return Point3D(x: pt.x, y: pt.y, z: .nan)
            }
            let depth = depthBuffer[index]
            return Point3D(x: pt.x, y: pt.y, z: CGFloat(depth))
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

fileprivate struct Point3D: Hashable {
    let x: CGFloat
    let y: CGFloat
    let z: CGFloat
}
