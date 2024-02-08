//
//  File.swift
//  
//
//  Created by Jakub Dolejs on 08/02/2024.
//

import Foundation
import UIKit
import LivenessDetection

struct LivenessDetectionPlugin: FaceTrackingPlugin {
    typealias ResultType = Float
    
    let spoofDetection: SpoofDetection
    var maxPositiveFrameCount: Int = 3
    
    let name: String = "Passive liveness"
    
    init() throws {
        guard let url = Bundle.module.url(forResource: "ARC_PSD-001_1.1.122_bst_yl80201_NMS_ult201_cml70", withExtension: "mlmodelc") else {
            throw "ARC_PSD-001_1.1.122_bst_yl80201_NMS_ult201_cml70 model not found in resource bundle"
        }
        let spoofDetector = try SpoofDeviceDetector(compiledModelURL: url, identifier: "Spoof device detector")
        self.spoofDetection = SpoofDetection(spoofDetector)
    }
    
    
    func processFaceTrackingResult(_ faceTrackingResult: FaceTrackingResult) throws -> LivenessDetectionPluginResult? {
        guard let cgImage = try faceTrackingResult.input?.image.convertToCGImage(), let face = faceTrackingResult.face else {
            return nil
        }
        let score = try self.spoofDetection.detectSpoofInImage(UIImage(cgImage: cgImage), regionOfInterest: face.bounds)
        return LivenessDetectionPluginResult(serialNumber: faceTrackingResult.serialNumber!, time: faceTrackingResult.time!, result: score)
    }
    
    func checkResults(_ results: [LivenessDetectionPluginResult]) throws {
        if results.filter({ $0.result > self.spoofDetection.confidenceThreshold }).count > self.maxPositiveFrameCount {
            throw "Failed passive liveness test"
        }
    }
}

public struct LivenessDetectionPluginResult: FaceTrackingPluginResult {
    public typealias Result = Float
    public var serialNumber: UInt64
    public var time: Double
    public var result: Float
}
