//
//  Errors.swift
//
//
//  Created by Jakub Dolejs on 20/02/2024.
//

import Foundation

/// Error thrown by the face capture library
/// - Since: 1.0.0
public enum FaceCaptureError: Error, CustomStringConvertible, LocalizedError {
    
    /// Another camera session is in progress
    /// - Since: 1.0.0
    case anotherCaptureSessionInProgress
    /// Session timed out
    /// - Since: 1.0.0
    case sessionTimedOut
    /// Missing a required file in a resource bundle
    /// - Since: 1.0.0
    case resourceBundleMissingFile(String)
    /// Active liveness check failed
    /// - Since: 1.0.0
    case activeLivenessCheckFailed(ActiveLivenessFailure)
    /// Passive liveness check failed
    /// - Since: 1.0.0
    case passiveLivenessCheckFailed(String)
    /// Expression requires a face tracking result with a property that's unavailable on that particular result
    /// - Since: 1.0.0
    case invalidFaceTrackingResult
    
    /// String description of the error
    /// - Since: 1.0.0
    public var description: String {
        switch self {
        case .anotherCaptureSessionInProgress:
            return "Another capture session in progress"
        case .sessionTimedOut:
            return "Session timed out"
        case .resourceBundleMissingFile(let file):
            return "Missing file \(file) in resource bundle"
        case .activeLivenessCheckFailed(let failure):
            return "Active liveness check failed: \(failure.rawValue)"
        case .passiveLivenessCheckFailed(let failure):
            return "Passive liveness check failed: \(failure)"
        case .invalidFaceTrackingResult:
            return "Invalid face tracking result"
        }
    }
    
    /// Localized description of the error
    /// - Since: 1.0.0
    public var localizedDescription: String {
        switch self {
        case .resourceBundleMissingFile(let file):
            String(format: NSLocalizedString("Missing file %@ in resource bundle", comment: ""), file)
        case .activeLivenessCheckFailed(let failure):
            String(format: NSLocalizedString("Active liveness check failed: %@", comment: ""), NSLocalizedString(failure.rawValue, comment: ""))
        case .passiveLivenessCheckFailed(let failure):
            String(format: NSLocalizedString("Passive liveness check failed: %@", comment: ""), NSLocalizedString(failure, comment: ""))
        default:
            NSLocalizedString(self.description, comment: "")
        }
    }
}

public enum ActiveLivenessFailure: String {
    case faceLost = "Face lost"
    case faceMovedOpposite = "Face moved in opposite direction"
}
