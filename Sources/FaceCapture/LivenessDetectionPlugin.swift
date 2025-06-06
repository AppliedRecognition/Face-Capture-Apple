//
//  LivenessDetectionPlugin.swift
//
//
//  Created by Jakub Dolejs on 06/02/2024.
//

import Foundation
import UIKit
import VerIDCommonTypes

class LivenessDetectionPlugin: FaceTrackingPlugin {
    
    typealias Element = Bool
    let name: String = "Passive liveness detection"
    let spoofDetectors: [SpoofDetection]
    var maxPositiveFrameRatio: Float = 0.2
    var maxSuccessivePositiveFrameRatio: Float = 0.1
    
    init(spoofDetectors: [SpoofDetection]) throws {
        self.spoofDetectors = spoofDetectors
    }
    
    func processFaceTrackingResult(_ faceTrackingResult: FaceTrackingResult) async throws -> Bool {
        guard let image = faceTrackingResult.input?.image, let face = faceTrackingResult.face else {
            return false
        }
        let isSpoofed = try await withThrowingTaskGroup(of: Bool.self) { group in
            for spoofDetector in spoofDetectors {
                group.addTask {
                    return try await spoofDetector.isSpoofInImage(image, regionOfInterest: face.bounds)
                }
            }
            for try await isSpoofed in group {
                if isSpoofed {
                    return true
                }
            }
            return false
        }
        return isSpoofed
    }
    
    func processFinalResults(_ faceTrackingResults: [FaceTrackingPluginResult<Bool>]) async throws {
        let (longestSuccessiveFailureCount, _, totalFailureCount) = faceTrackingResults.reduce((currentStreak: 0, maxStreak: 0, totalFailureCount: 0)) { result, element in
            let currentStreak = element.result ? result.currentStreak + 1 : 0
            let maxStreak = max(result.maxStreak, currentStreak)
            let failureCount = element.result ? result.totalFailureCount + 1 : result.totalFailureCount
            return (currentStreak, maxStreak, failureCount)
        }
        let totalCount = faceTrackingResults.count
        if Float(totalFailureCount) / Float(totalCount) > self.maxPositiveFrameRatio {
            throw FaceCaptureError.passiveLivenessCheckFailed("Spoof device detector failed on \(totalFailureCount) of \(totalCount) input frames")
        }
        if Float(longestSuccessiveFailureCount) / Float(totalCount) > self.maxSuccessivePositiveFrameRatio {
            throw FaceCaptureError.passiveLivenessCheckFailed("Spoof device detector failed on \(longestSuccessiveFailureCount) successive input frames out of \(totalCount) input frames")
        }
    }
    
    func createSummaryFromResults(_ results: [FaceTrackingPluginResult<Bool>]) async -> String {
        let successCount = results.reduce(0, { result, element in
            if !element.result {
                return result + 1
            }
            return result
        })
        return "Liveness test passed on \(successCount) of \(results.count) captures"
    }
}
