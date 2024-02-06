//
//  File.swift
//  
//
//  Created by Jakub Dolejs on 23/10/2023.
//

import Foundation

public enum FaceCaptureSessionResult {
    
    case success(faceCaptures: [FaceCapture], metadata: [String:[UInt64:Encodable]])
    case failure(faceCaptures: [FaceCapture], metadata: [String:[UInt64:Encodable]], error: Error)
    
    public var faceCaptures: [FaceCapture] {
        switch self {
        case .success(faceCaptures: let captures, metadata: _):
            return captures
        case .failure(faceCaptures: let captures, metadata: _, error: _):
            return captures
        }
    }
    
    public var metadata: [String:[UInt64:Encodable]] {
        switch self {
        case .success(faceCaptures: _, metadata: let metadata):
            return metadata
        case .failure(faceCaptures: _, metadata: let metadata, error: _):
            return metadata
        }
    }
}
