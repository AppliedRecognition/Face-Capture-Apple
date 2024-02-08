//
//  File.swift
//  
//
//  Created by Jakub Dolejs on 23/10/2023.
//

import Foundation

public enum FaceCaptureSessionResult: Hashable {
    
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
    
    public static func == (lhs: FaceCaptureSessionResult, rhs: FaceCaptureSessionResult) -> Bool {
        if case .success(let lhsFaceCaptures, _) = lhs, case .success(let rhsFaceCaptures, _) = rhs {
            return lhsFaceCaptures.elementsEqual(rhsFaceCaptures, by: ==)
        } else if case .failure(let lhsFaceCaptures, _, let lhsError) = lhs, case .failure(let rhsFaceCaptures, _, let rhsError) = rhs {
            return lhsError == rhsError && lhsFaceCaptures.elementsEqual(rhsFaceCaptures, by: ==)
        } else {
            return false
        }
    }
    
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
