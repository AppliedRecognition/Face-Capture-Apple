//
//  File.swift
//  
//
//  Created by Jakub Dolejs on 24/10/2023.
//

import Foundation
import Vision

public class AppleFaceDetection: FaceDetection {
    
    public init() {
        
    }
    
    public func detectFacesInImage(_ image: Image, limit: Int=1) throws -> [Face] {
        let cgImage = try image.convertToCGImage()
        let handler = VNImageRequestHandler(cgImage: cgImage)
        let faceLandmarksRequest = VNDetectFaceLandmarksRequest()
        faceLandmarksRequest.revision = VNDetectFaceLandmarksRequestRevision3
        let faceQualityRequest = VNDetectFaceCaptureQualityRequest()
        try handler.perform([faceLandmarksRequest, faceQualityRequest])
        guard let landmarkResults = faceLandmarksRequest.results, let qualityResults = faceQualityRequest.results else {
            return []
        }
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let transform = CGAffineTransform(scaleX: CGFloat(cgImage.width), y: CGFloat(0-cgImage.height)).concatenating(CGAffineTransform(translationX: 0, y: CGFloat(cgImage.height)))
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
            return Face(bounds: landmarkFace.boundingBox.applying(transform), angle: angle, quality: qualityFace.faceCaptureQuality ?? 1, landmarks: landmarkFace.landmarks?.allPoints?.pointsInImage(imageSize: imageSize))
        }
        return faces.sorted()
    }
    
    private func detectFacesInImageBoundsFirst(_ image: Image, limit: Int=1) throws -> [Face] {
        let cgImage = try image.convertToCGImage()
        let handler = VNImageRequestHandler(cgImage: cgImage)
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
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let transform = CGAffineTransform(scaleX: CGFloat(cgImage.width), y: CGFloat(0-cgImage.height)).concatenating(CGAffineTransform(translationX: 0, y: CGFloat(cgImage.height)))
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
            return Face(bounds: landmarkFace.boundingBox.applying(transform), angle: angle, quality: qualityFace.faceCaptureQuality ?? 1, landmarks: landmarkFace.landmarks?.allPoints?.pointsInImage(imageSize: imageSize))
        }
        return faces.sorted()
    }
}
