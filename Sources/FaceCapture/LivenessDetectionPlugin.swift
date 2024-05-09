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
    
    typealias Element = Bool
    let name: String = "Passive liveness"
    let spoofDetectors: [SpoofDetector]
    var maxPositiveFrameCount: Int = 3
    var failureCount: Int = 0
    
    init(spoofDetectors: [SpoofDetector]) throws {
        self.spoofDetectors = spoofDetectors
    }
    
    func processFaceTrackingResult(_ faceTrackingResult: FaceTrackingResult) async throws -> Bool {
        guard let cgImage = try faceTrackingResult.input?.image.convertToCGImage(), let face = faceTrackingResult.face else {
            return false
        }
        let image = UIImage(cgImage: cgImage)
        let isSpoofed = try await withThrowingTaskGroup(of: Bool.self) { group in
            for spoofDetector in spoofDetectors {
                group.addTask {
                    return try await spoofDetector.isSpoofedImage(image, regionOfInterest: face.bounds)
                }
            }
            for try await isSpoofed in group {
                if isSpoofed {
                    return true
                }
            }
            return false
        }
        if isSpoofed {
            self.failureCount += 1
        }
        try self.checkFailureCount()
        return isSpoofed
    }
    
    func checkFailureCount() throws {
        if self.failureCount > self.maxPositiveFrameCount {
            throw FaceCaptureError.passiveLivenessCheckFailed("Spoof device detector failed on \(self.failureCount) input frames")
        }
    }
    
    func createSummaryFromResults(_ results: [FaceTrackingPluginResult<Bool>]) async -> String {
        do {
            try self.checkFailureCount()
            return "Liveness test passed"
        } catch {
            return "Liveness test failed"
        }
    }
}
