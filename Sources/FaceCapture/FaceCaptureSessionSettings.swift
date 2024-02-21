//
//  File.swift
//  
//
//  Created by Jakub Dolejs on 30/10/2023.
//

import Foundation
import VerIDCommonTypes

/// Face capture session settings
/// - Since: 1.0.0
public struct FaceCaptureSessionSettings {
    
    /// Face capture count
    ///
    /// Indicates how many faces the session should capture. Defaults to `1`.
    /// >  Note: Increasing the count will enable activa liveness check. It's recommended to keep the count under `3`.
    /// - Since: 1.0.0
    public var faceCaptureCount: Int = 1
    /// How many faces the session needs to capture before generating a face capture
    ///
    /// > Note: This parameter ensures that a face that briefly appears in the camera isn't captured.
    /// - Since: 1.0.0
    public var faceCaptureFaceCount: Int = 6
    /// Pause duration (in seconds) before subsequent face captures
    ///
    /// If ``faceCaptureCount`` is set to a value higher than `1`, the session will pause after each successful capture to allow the user to read the next prompt.
    /// - Since: 1.0.0
    public var pauseDuration: TimeInterval = 1.5
    /// Maximum session duration (in seconds)
    ///
    /// If the session duration exceeds the time specified by this property the session will fail with a timeout error.
    /// - Since: 1.0.0
    public var maxDuration: TimeInterval = 30
    /// Available face bearings
    ///
    /// Face bearings the session may prompt the user to assume if ``faceCaptureCount`` is set to a value higher than `1`.
    /// > Note: The array represents a pool of available bearings. The user will not be asked to assume each bearing in the array.
    /// - Since: 1.0.0
    public var availableBearings: Set<Bearing> = [.straight,.left,.right]
    /// Face pitch threshold
    ///
    /// When the session requests the user to assume a pose (bearing) this is the threshold between a straight and pitched face. For example, ``pitchThreshold`` of `15` means that a face pitched at an angle between -15º and  15º will be considered to be looking straight at the camera.
    /// - Since: 1.0.0
    public var pitchThreshold: Float = 15
    /// Face yaw threshold
    ///
    /// When the session requests the user to assume a pose (bearing) this is the threshold between a straight and turned face. For example, ``yawThreshold`` of `15` means that a face turned laterally at an angle between -15º and  15º will be considered to be looking straight at the camera.
    /// - Since: 1.0.0
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
            height = size.height * self.expectedFaceBoundsHeight
            width = height * self.faceAspectRatio
        } else {
            width = size.width * self.expectedFaceBoundsWidth
            height = width / self.faceAspectRatio
        }
        return CGRect(x: size.width / 2 - width / 2, y: size.height / 2 - height / 2, width: width, height: height)
    }
    
    /// Constructor
    /// - Since: 1.0.0
    public init() {
    }
}
