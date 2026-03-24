//
//  FPSMeasurementPlugin.swift
//
//
//  Created by Jakub Dolejs on 09/02/2024.
//

import Foundation
import UIKit

public class FPSMeasurementPlugin: FaceTrackingPlugin {
    public typealias Element = FPSMeasurement
    public let name: String = "FPS measurement"
    
    var recentTimes: [TimeInterval]
    var startTime: TimeInterval?
    var totalCount: Int

    public init() {
        self.recentTimes = []
        self.startTime = nil
        self.totalCount = 0
    }

    public func processFaceTrackingResult(_ faceTrackingResult: FaceTrackingResult) throws -> FPSMeasurement {
        guard let time = faceTrackingResult.time else {
            throw FaceCaptureError.invalidFaceTrackingResult
        }
        if self.startTime == nil { self.startTime = time }
        self.totalCount += 1
        let oneSecAgo = time - 1.0
        self.recentTimes.removeAll(where: { $0 < oneSecAgo })
        self.recentTimes.append(time)
        let sinceStart: Double
        if let start = self.startTime {
            let duration = time - start
            sinceStart = duration > 0 ? Double(self.totalCount) / duration : 0
        } else {
            sinceStart = 0
        }
        return FPSMeasurement(lastSecond: Double(self.recentTimes.count), sinceStart: sinceStart)
    }
    
    public func createSummaryFromResults(_ results: [FaceTrackingPluginResult<FPSMeasurement>]) async -> String {
        if let fps = results.last?.result.sinceStart {
            return String(format: "%.01f frames per second", fps)
        } else {
            return "Unavailable"
        }
    }
}

public struct FPSMeasurement: Encodable {
    let lastSecond: Double
    let sinceStart: Double
}
