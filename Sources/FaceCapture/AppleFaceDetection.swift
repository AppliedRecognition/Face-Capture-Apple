//
//  File.swift
//  
//
//  Created by Jakub Dolejs on 24/10/2023.
//

import Foundation
import Vision

public class AppleFaceDetection: FaceDetection {
    
    public func detectFacesInImage(_ image: Image) throws -> [Face] {
        let cgImage = try image.convertToCGImage()
        let handler = VNImageRequestHandler(cgImage: cgImage)
        let faceBoundsRequest = VNDetectFaceCaptureQualityRequest()
        faceBoundsRequest.revision = VNDetectFaceRectanglesRequestRevision2
//        if #available(iOS 15, *) {
//            faceBoundsRequest.revision = VNDetectFaceRectanglesRequestRevision3
//        } else {
//            faceBoundsRequest.revision = VNDetectFaceRectanglesRequestRevision2
//        }
        try handler.perform([faceBoundsRequest])
        let transform = CGAffineTransform(scaleX: CGFloat(cgImage.width), y: CGFloat(0-cgImage.height)).concatenating(CGAffineTransform(translationX: 0, y: CGFloat(cgImage.height)))
        let faces: [Face] = faceBoundsRequest.results?.compactMap({ (face: VNFaceObservation) -> Face? in
            let pitch: NSNumber
            if #available(iOS 15, *) {
                pitch = face.pitch ?? 0
            } else {
                pitch = 0
            }
            if let yaw = face.yaw, let roll = face.roll {
                let angle = EulerAngle<Float>(yaw: Float(Measurement(value: yaw.doubleValue, unit: UnitAngle.radians).converted(to: .degrees).value), pitch: Float(Measurement(value: pitch.doubleValue, unit: UnitAngle.radians).converted(to: .degrees).value), roll: Float(Measurement(value: roll.doubleValue, unit: UnitAngle.radians).converted(to: .degrees).value))
                return Face(bounds: face.boundingBox.applying(transform), angle: angle, quality: face.faceCaptureQuality ?? 1, landmarks: nil)
            }
            return nil
        }) ?? []
        return faces.sorted()
    }
}
