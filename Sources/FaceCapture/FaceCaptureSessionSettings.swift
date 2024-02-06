//
//  File.swift
//  
//
//  Created by Jakub Dolejs on 30/10/2023.
//

import Foundation

public struct FaceCaptureSessionSettings {
    
    public var faceCaptureCount: Int = 1
    public var faceCaptureFaceCount: Int = 6
    public var pauseDuration: TimeInterval = 1.5
    public var maxDuration: TimeInterval = 30
    public var availableBearings: Set<Bearing> = [.straight,.left,.right]
    public var pitchThreshold: Float = 15
    public var yawThreshold: Float = 17
    public var pitchThresholdTolerance: Float = 5
    public var yawThresholdTolerance: Float = 5
    
    public init() {
    }
}
