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
    public var expectedFaceBoundsWidth: CGFloat = 0.55
    public var expectedFaceBoundsHeight: CGFloat = 0.7
    public var faceAspectRatio: CGFloat = 4/5
    public func expectedFaceBoundsInSize(_ size: CGSize) -> CGRect {
        let width: CGFloat
        let height: CGFloat
        if size.width / size.height > self.faceAspectRatio {
            height = size.height * self.expectedFaceBoundsHeight * 0.01
            width = height * self.faceAspectRatio
        } else {
            width = size.width * self.expectedFaceBoundsWidth * 0.01
            height = width / self.faceAspectRatio
        }
        return CGRect(x: size.width / 2 - width / 2, y: size.height / 2 - height / 2, width: width, height: height)
    }
    
    public init() {
    }
}
