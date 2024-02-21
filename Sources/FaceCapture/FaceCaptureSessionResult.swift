//
//  File.swift
//  
//
//  Created by Jakub Dolejs on 23/10/2023.
//

import Foundation

/// Face capture session result
/// - Since: 1.0.0
public enum FaceCaptureSessionResult: Hashable {
    
    /// Session succeeded
    /// - Parameters:
    ///   - faceCaptures: Face captures including the image and detected face
    ///   - metadata: Metadata collected by the session's face tracking plugins
    /// - Since: 1.0.0
    case success(faceCaptures: [CapturedFace], metadata: [String:TaskResults])
    /// Session failed
    /// - Parameters:
    ///   - faceCaptures: Face captures including the image and detected face
    ///   - metadata: Metadata collected by the session's face tracking plugins
    ///   - error: Error that caused the session to fail
    /// - Since: 1.0.0
    case failure(faceCaptures: [CapturedFace], metadata: [String:TaskResults], error: Error)
    
    /// Face captures collected in the session. Each face capture contains an image and the detected face.
    /// - Since: 1.0.0
    public var faceCaptures: [CapturedFace] {
        switch self {
        case .success(faceCaptures: let captures, metadata: _):
            return captures
        case .failure(faceCaptures: let captures, metadata: _, error: _):
            return captures
        }
    }
    
    /// Metadata collected by the session's face tracking plugins
    ///
    /// The metadata is a dictionary where each entry corresponds to a face tracking plugin. Entries are keyed by human-readable plugin name. The value is a ``TaskResults`` struct with a text summary of the plugin results and an array of plugin results that corresponds to each frame the plugin processed.
    /// - Since: 1.0.0
    public var metadata: [String:TaskResults] {
        switch self {
        case .success(faceCaptures: _, metadata: let metadata):
            return metadata
        case .failure(faceCaptures: _, metadata: let metadata, error: _):
            return metadata
        }
    }
    
    /// Equatable implementation
    public static func == (lhs: FaceCaptureSessionResult, rhs: FaceCaptureSessionResult) -> Bool {
        if case .success(let lhsFaceCaptures, _) = lhs, case .success(let rhsFaceCaptures, _) = rhs {
            return lhsFaceCaptures.elementsEqual(rhsFaceCaptures, by: ==)
        } else if case .failure(let lhsFaceCaptures, _, let lhsError) = lhs, case .failure(let rhsFaceCaptures, _, let rhsError) = rhs {
            return lhsError == rhsError && lhsFaceCaptures.elementsEqual(rhsFaceCaptures, by: ==)
        } else {
            return false
        }
    }
    
    /// Hashable implementation
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.faceCaptures)
        if case .failure(_, _, let error) = self {
            hasher.combine("\(error)")
        }
    }
}

fileprivate func == (lhs: Error, rhs: Error) -> Bool {
    guard type(of: lhs) == type(of: rhs) else { return false }
    let error1 = lhs as NSError
    let error2 = rhs as NSError
    return error1.domain == error2.domain && error1.code == error2.code && "\(lhs)" == "\(rhs)"
}

fileprivate extension Equatable where Self: Error {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs as Error == rhs as Error
    }
}
