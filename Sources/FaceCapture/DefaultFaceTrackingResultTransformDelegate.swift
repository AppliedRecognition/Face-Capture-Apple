//
//  DefaultFaceTrackingResultTransformDelegate.swift
//
//
//  Created by Jakub Dolejs on 23/03/2026.
//

import Foundation

internal final class DefaultFaceTrackingResultTransformDelegate: SessionFaceTrackingDelegate {

    private let transformers: [FaceTrackingResultTransformer]

    init(_ transformers: [FaceTrackingResultTransformer]) {
        self.transformers = transformers
    }

    func transformFaceResult(_ faceTrackingResult: FaceTrackingResult) -> FaceTrackingResult {
        if self.transformers.isEmpty {
            if case .faceAligned(let trackedFaceSessionProperties) = faceTrackingResult {
                return .faceCaptured(trackedFaceSessionProperties)
            } else {
                return faceTrackingResult
            }
        } else {
            var result = faceTrackingResult
            for transformer in self.transformers {
                result = transformer.transformFaceResult(result)
            }
            return result
        }
    }
}
