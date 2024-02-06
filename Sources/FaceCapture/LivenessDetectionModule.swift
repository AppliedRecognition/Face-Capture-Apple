//
//  LivenessDetectionModule.swift
//
//
//  Created by Jakub Dolejs on 06/02/2024.
//

import Foundation
import UIKit
import LivenessDetection

class LivenessDetectionModule: FaceTrackingModule {
    let spoofDetection: SpoofDetection
    var maxPositiveFrameCount: Int = 3
    
    init() throws {
        guard let url = Bundle.module.url(forResource: "ARC_PSD-001_1.1.122_bst_yl80201_NMS_ult201_cml70", withExtension: "mlmodelc") else {
            throw "ARC_PSD-001_1.1.122_bst_yl80201_NMS_ult201_cml70 model not found in resource bundle"
        }
        let spoofDetector = try SpoofDeviceDetector(compiledModelURL: url, identifier: "Spoof device detector")
        self.spoofDetection = SpoofDetection(spoofDetector)
        super.init(name: "Passive liveness")
    }
    
    override func processFaceTrackingResult(_ faceTrackingResult: FaceTrackingResult) throws -> Encodable {
        guard let cgImage = try faceTrackingResult.input?.image.convertToCGImage(), let face = faceTrackingResult.face else {
            return 0.0
        }
        return try self.spoofDetection.detectSpoofInImage(UIImage(cgImage: cgImage), regionOfInterest: face.bounds)
    }
    
    override func checkResults(_ results: [UInt64:Encodable]) throws {
        if results.values.compactMap({ $0 as? Float }).filter({ $0 > self.spoofDetection.confidenceThreshold }).count > self.maxPositiveFrameCount {
            throw "Failed passive liveness test"
        }
    }
}
