//
//  File.swift
//  
//
//  Created by Jakub Dolejs on 24/10/2023.
//

import Foundation
import Vision
import VerIDCommonTypes

/// ``FaceDetection`` protocol implementation using Apple's `Vision` framework
/// - Since: 1.0.0
public class AppleFaceDetection: FaceDetection {
    
    public init() {}
    
    /// Detect a face in image
    /// - Parameters:
    ///   - image: Image in which to detect the face
    ///   - limit: Maximum number of faces to detect
    /// - Returns: Array of detected faces
    /// - Since: 1.0.0
    public func detectFacesInImage(_ image: Image, limit: Int=1) throws -> [Face] {
        let handler = VNImageRequestHandler(cvPixelBuffer: image.videoBuffer)
        let faceLandmarksRequest = VNDetectFaceLandmarksRequest()
        faceLandmarksRequest.revision = VNDetectFaceLandmarksRequestRevision3
        let faceQualityRequest = VNDetectFaceCaptureQualityRequest()
        try handler.perform([faceLandmarksRequest, faceQualityRequest])
        guard let landmarkResults = faceLandmarksRequest.results, let qualityResults = faceQualityRequest.results else {
            return []
        }
        let imageSize = image.size
        let transform = CGAffineTransform(scaleX: CGFloat(image.width), y: CGFloat(0-image.height)).concatenating(CGAffineTransform(translationX: 0, y: CGFloat(image.height)))
        let faces: [Face] = zip(landmarkResults, qualityResults).compactMap { (landmarkFace, qualityFace) -> Face? in
            let pitch: NSNumber
            if #available(iOS 15, *) {
                pitch = landmarkFace.pitch ?? 0
            } else {
                pitch = 0
            }
            guard let yaw = landmarkFace.yaw, let roll = landmarkFace.roll else {
                return nil
            }
            let angle = EulerAngle<Float>(yaw: Float(Measurement(value: yaw.doubleValue, unit: UnitAngle.radians).converted(to: .degrees).value), pitch: Float(Measurement(value: pitch.doubleValue, unit: UnitAngle.radians).converted(to: .degrees).value), roll: Float(Measurement(value: roll.doubleValue, unit: UnitAngle.radians).converted(to: .degrees).value))
            let mouth: CGPoint?
            if let innerLips = landmarkFace.landmarks?.innerLips?.pointsInImage(imageSize: imageSize) {
                let averageX = innerLips.map({ $0.x }).reduce(0, +) / CGFloat(innerLips.count)
                let averageY = innerLips.map({ $0.y }).reduce(0, +) / CGFloat(innerLips.count)
                mouth = CGPoint(x: averageX, y: averageY)
            } else {
                mouth = nil
            }
            return Face(
                bounds: landmarkFace.boundingBox.applying(transform),
                angle: angle,
                quality: qualityFace.faceCaptureQuality ?? 1,
                landmarks: landmarkFace.landmarks?.allPoints?.pointsInImage(imageSize: imageSize) ?? [],
                leftEye: landmarkFace.landmarks?.leftPupil?.pointsInImage(imageSize: imageSize).first ?? .zero,
                rightEye: landmarkFace.landmarks?.rightPupil?.pointsInImage(imageSize: imageSize).first ?? .zero,
                noseTip: landmarkFace.landmarks?.noseCrest?.pointsInImage(imageSize: imageSize).max(by: { $0.y < $1.y }),
                mouthCentre: mouth
            )
        }
        return faces.sorted()
    }
    
    private func detectFacesInImageBoundsFirst(_ image: Image, limit: Int=1) throws -> [Face] {
        let handler = VNImageRequestHandler(cvPixelBuffer: image.videoBuffer)
        let faceBoundsRequest = VNDetectFaceRectanglesRequest()
        faceBoundsRequest.revision = VNDetectFaceRectanglesRequestRevision2
        try handler.perform([faceBoundsRequest])
        guard let results = faceBoundsRequest.results?.sorted(by: { face1, face2 in
            face1.boundingBox.size > face2.boundingBox.size
        }), !results.isEmpty else {
            return []
        }
        let faceLandmarksRequest = VNDetectFaceLandmarksRequest()
        faceLandmarksRequest.revision = VNDetectFaceLandmarksRequestRevision3
        faceLandmarksRequest.inputFaceObservations = Array(results[0..<limit])
        let faceQualityRequest = VNDetectFaceCaptureQualityRequest()
        faceQualityRequest.inputFaceObservations = Array(results[0..<limit])
        try handler.perform([faceLandmarksRequest, faceQualityRequest])
        guard let landmarkResults = faceLandmarksRequest.results, let qualityResults = faceQualityRequest.results else {
            return []
        }
        let imageSize = image.size
        let transform = CGAffineTransform(scaleX: imageSize.width, y: 0-imageSize.height).concatenating(CGAffineTransform(translationX: 0, y: imageSize.height))
        let faces: [Face] = zip(landmarkResults, qualityResults).compactMap { (landmarkFace: VNFaceObservation, qualityFace: VNFaceObservation) -> Face? in
            let pitch: NSNumber
            if #available(iOS 15, *) {
                pitch = landmarkFace.pitch ?? 0
            } else {
                pitch = 0
            }
            guard let yaw = landmarkFace.yaw, let roll = landmarkFace.roll else {
                return nil
            }
            let angle = EulerAngle<Float>(yaw: Float(Measurement(value: yaw.doubleValue, unit: UnitAngle.radians).converted(to: .degrees).value), pitch: Float(Measurement(value: pitch.doubleValue, unit: UnitAngle.radians).converted(to: .degrees).value), roll: Float(Measurement(value: roll.doubleValue, unit: UnitAngle.radians).converted(to: .degrees).value))
            let landmarks = landmarkFace.landmarks?.allPoints?.pointsInImage(imageSize: imageSize)
            let mouth: CGPoint?
            if let innerLips = landmarkFace.landmarks?.innerLips?.pointsInImage(imageSize: imageSize) {
                let averageX = innerLips.map({ $0.x }).reduce(0, +) / CGFloat(innerLips.count)
                let averageY = innerLips.map({ $0.y }).reduce(0, +) / CGFloat(innerLips.count)
                mouth = CGPoint(x: averageX, y: averageY)
            } else {
                mouth = nil
            }
            return Face(
                bounds: landmarkFace.boundingBox.applying(transform),
                angle: angle,
                quality: qualityFace.faceCaptureQuality ?? 1,
                landmarks: landmarks ?? [],
                leftEye: landmarkFace.landmarks?.leftPupil?.pointsInImage(imageSize: imageSize).first ?? .zero,
                rightEye: landmarkFace.landmarks?.rightPupil?.pointsInImage(imageSize: imageSize).first ?? .zero,
                noseTip: landmarkFace.landmarks?.noseCrest?.pointsInImage(imageSize: imageSize).max(by: { $0.y < $1.y }),
                mouthCentre: mouth
            )
        }
        return faces.sorted()
    }
}

extension CGSize: Comparable {
    public static func < (lhs: CGSize, rhs: CGSize) -> Bool {
        return lhs.width * lhs.height < rhs.width * rhs.height
    }
}
