//
//  FaceTrackingResult.swift
//  
//
//  Created by Jakub Dolejs on 29/01/2024.
//

import Foundation

public enum FaceTrackingResult: Hashable, Sendable {
    
    case created(Bearing)
    case started(StartedSessionProperties)
    case paused(StartedSessionProperties)
    case faceFound(TrackedFaceSessionProperties)
    case faceFixed(TrackedFaceSessionProperties)
    case faceAligned(TrackedFaceSessionProperties)
    case faceMisaligned(TrackedFaceSessionProperties)
    
    public var input: FaceCaptureSessionImageInput? {
        switch self {
        case .started(let props):
            return props.input
        case .paused(let props):
            return props.input
        case .faceFound(let props):
            return props.input
        case .faceFixed(let props):
            return props.input
        case .faceAligned(let props):
            return props.input
        case .faceMisaligned(let props):
            return props.input
        default:
            return nil
        }
    }
    
    public var requestedBearing: Bearing {
        switch self {
        case .created(let bearing):
            return bearing
        case .started(let props):
            return props.requestedBearing
        case .paused(let props):
            return props.requestedBearing
        case .faceFound(let props):
            return props.requestedBearing
        case .faceFixed(let props):
            return props.requestedBearing
        case .faceAligned(let props):
            return props.requestedBearing
        case .faceMisaligned(let props):
            return props.requestedBearing
        }
    }
    
    public var face: Face? {
        switch self {
        case .faceFound(let props):
            return props.face
        case .faceFixed(let props):
            return props.face
        case .faceAligned(let props):
            return props.face
        case .faceMisaligned(let props):
            return props.face
        default:
            return nil
        }
    }
    
    public var smoothedFace: Face? {
        switch self {
        case .faceFound(let props):
            return props.smoothedFace
        case .faceFixed(let props):
            return props.smoothedFace
        case .faceAligned(let props):
            return props.smoothedFace
        case .faceMisaligned(let props):
            return props.smoothedFace
        default:
            return nil
        }
    }
    
    var serialNumber: UInt64? {
        if let input = self.input {
            return input.serialNumber
        } else {
            return nil
        }
    }
    
    var faceCapture: FaceCapture? {
        if case .faceAligned(let props) = self {
            return FaceCapture(image: props.input.image, face: props.face, bearing: props.requestedBearing)
        } else {
            return nil
        }
    }
    
    var expectedFaceBounds: CGRect? {
        switch self {
        case .started(let props):
            return props.expectedFaceBounds
        case .paused(let props):
            return props.expectedFaceBounds
        case .faceFound(let props):
            return props.expectedFaceBounds
        case .faceFixed(let props):
            return props.expectedFaceBounds
        case .faceAligned(let props):
            return props.expectedFaceBounds
        case .faceMisaligned(let props):
            return props.expectedFaceBounds
        default:
            return nil
        }
    }
    
    public func scaledToFitViewSize(_ viewSize: CGSize, mirrored: Bool) -> FaceTrackingResult {
        let scale: CGFloat
        if let imageSize = self.input?.image.size {
            scale = viewSize.width / imageSize.width
        } else {
            scale = 1
        }
        let mirrorTransform = mirrored ? CGAffineTransform(scaleX: -1, y: 1).concatenating(CGAffineTransform(translationX: viewSize.width, y: 0)) : .identity
        let scaleTransform = CGAffineTransform(scaleX: scale, y: scale).concatenating(mirrorTransform)
        let expectedFaceBounds: CGRect = self.expectedFaceBounds?.applying(scaleTransform) ?? .null
        let expectedFaceAspectRatio = !expectedFaceBounds.isNull ? expectedFaceBounds.size.width / expectedFaceBounds.size.height : 1
        let smoothedFace: Face? = self.smoothedFace?.withBoundsSetToAspectRatio(expectedFaceAspectRatio).applying(scaleTransform)
        let face = self.face?.withBoundsSetToAspectRatio(expectedFaceAspectRatio).applying(scaleTransform)
        switch self {
        case .created(let bearing):
            return .created(bearing)
        case .started(let props):
            let updatedProps = StartedSessionProperties(input: props.input, requestedBearing: props.requestedBearing, expectedFaceBounds: expectedFaceBounds)
            return .started(updatedProps)
        case .faceFound(let props):
            let updatedProps = TrackedFaceSessionProperties(input: props.input, requestedBearing: props.requestedBearing, expectedFaceBounds: expectedFaceBounds, face: face!, smoothedFace: smoothedFace!)
            return .faceFound(updatedProps)
        case .faceFixed(let props):
            let updatedProps = TrackedFaceSessionProperties(input: props.input, requestedBearing: props.requestedBearing, expectedFaceBounds: expectedFaceBounds, face: face!, smoothedFace: smoothedFace!)
            return .faceFixed(updatedProps)
        case .faceAligned(let props):
            let updatedProps = TrackedFaceSessionProperties(input: props.input, requestedBearing: props.requestedBearing, expectedFaceBounds: expectedFaceBounds, face: face!, smoothedFace: smoothedFace!)
            return .faceAligned(updatedProps)
        case .faceMisaligned(let props):
            let updatedProps = TrackedFaceSessionProperties(input: props.input, requestedBearing: props.requestedBearing, expectedFaceBounds: expectedFaceBounds, face: face!, smoothedFace: smoothedFace!)
            return .faceMisaligned(updatedProps)
        case .paused(let props):
            let updatedProps = StartedSessionProperties(input: props.input, requestedBearing: props.requestedBearing, expectedFaceBounds: expectedFaceBounds)
            return .paused(updatedProps)
        }
    }
}

public struct StartedSessionProperties: Hashable {
    public let input: FaceCaptureSessionImageInput
    public let requestedBearing: Bearing
    public let expectedFaceBounds: CGRect
}

public struct TrackedFaceSessionProperties: Hashable {
    public let input: FaceCaptureSessionImageInput
    public let requestedBearing: Bearing
    public let expectedFaceBounds: CGRect
    public let face: Face
    public let smoothedFace: Face
}
