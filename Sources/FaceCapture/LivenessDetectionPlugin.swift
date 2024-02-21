//
//  LivenessDetectionPlugin.swift
//
//
//  Created by Jakub Dolejs on 06/02/2024.
//

import Foundation
import UIKit
import LivenessDetection

class LivenessDetectionPlugin: FaceTrackingPlugin {
    
    typealias Element = Float
    let name: String = "Passive liveness"
    let spoofDetection: SpoofDetection
    var maxPositiveFrameCount: Int = 3
    var failureCount: Int = 0
    
    init() throws {
        guard let url = Bundle.module.url(forResource: "ARC_PSD-001_1.1.122_bst_yl80201_NMS_ult201_cml70", withExtension: "mlmodelc") else {
            throw FaceCaptureError.resourceBundleMissingFile("ARC_PSD-001_1.1.122_bst_yl80201_NMS_ult201_cml70")
        }
        let spoofDetector = try SpoofDeviceDetector(compiledModelURL: url, identifier: "Spoof device detector")
        self.spoofDetection = SpoofDetection(spoofDetector)
    }
    
    func processFaceTrackingResult(_ faceTrackingResult: FaceTrackingResult) throws -> Float {
        guard let cgImage = try faceTrackingResult.input?.image.convertToCGImage(), let face = faceTrackingResult.face else {
            return 0.0
        }
        let score = try self.spoofDetection.detectSpoofInImage(UIImage(cgImage: cgImage), regionOfInterest: face.bounds)
        if score > self.spoofDetection.confidenceThreshold {
            self.failureCount += 1
        }
        try self.checkFailureCount()
        return score
    }
    
    func checkFailureCount() throws {
        if self.failureCount > self.maxPositiveFrameCount {
            throw FaceCaptureError.passiveLivenessCheckFailed("Spoof device detector failed on \(self.failureCount) input frames")
        }
    }
    
    func createSummaryFromResults(_ results: [FaceTrackingPluginResult<Float>]) -> String {
        do {
            try self.checkFailureCount()
            return "Liveness test passed"
        } catch {
            return "Liveness test failed"
        }
    }
}
