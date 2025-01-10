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
    
    var times: [TimeInterval]
    
    public init() {
        self.times = []
    }
    
    public func processFaceTrackingResult(_ faceTrackingResult: FaceTrackingResult) throws -> FPSMeasurement {
        guard let time = faceTrackingResult.time else {
            throw FaceCaptureError.invalidFaceTrackingResult
        }
        self.times.append(time)
        let oneSecAgo = time - 1.0
        let sinceStart: Double
        if let earliest = self.times.min() {
            let duration = time - earliest
            sinceStart = Double(self.times.count) / duration
        } else {
            sinceStart = 0
        }
        let lastSecond = Double(self.times.filter { $0 >= oneSecAgo }.count)
        return FPSMeasurement(lastSecond: lastSecond, sinceStart: sinceStart)
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
