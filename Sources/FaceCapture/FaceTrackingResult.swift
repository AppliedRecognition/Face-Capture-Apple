//
//  FaceTrackingResult.swift
//  
//
//  Created by Jakub Dolejs on 29/01/2024.
//

import Foundation
import VerIDCommonTypes

public enum FaceTrackingResult: Hashable, Sendable, CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .created:
            return "Created"
        case .waiting:
            return "Waiting"
        case .started:
            return "Started"
        case .paused:
            return "Paused"
        case .faceFound:
            return "Face found"
        case .faceFixed:
            return "Face fixed"
        case .faceAligned:
            return "Face aligned"
        case .faceMisaligned:
            return "Face misaligned"
        case .faceCaptured:
            return "Face captured"
        }
    }
    
    
    case created(Bearing)
    case waiting(WaitingSessionProperties)
    case started(StartedSessionProperties)
    case paused(StartedSessionProperties)
    case faceFound(TrackedFaceSessionProperties)
    case faceFixed(TrackedFaceSessionProperties)
    case faceAligned(TrackedFaceSessionProperties)
    case faceMisaligned(TrackedFaceSessionProperties)
    case faceCaptured(TrackedFaceSessionProperties)
    
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
        case .faceCaptured(let props):
            return props.input
        default:
            return nil
        }
    }
    
    public var requestedBearing: Bearing {
        switch self {
        case .created(let bearing):
            return bearing
        case .waiting(let props):
            return props.requestedBearing
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
        case .faceCaptured(let props):
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
        case .faceCaptured(let props):
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
        case .faceCaptured(let props):
            return props.smoothedFace
        default:
            return nil
        }
    }
    
    public var serialNumber: UInt64? {
        if let input = self.input {
            return input.serialNumber
        } else {
            return nil
        }
    }
    
    public var capturedFace: CapturedFace? {
        if case .faceCaptured(let props) = self {
            return CapturedFace(image: props.input.image, face: props.face, bearing: props.requestedBearing)
        } else {
            return nil
        }
    }
    
    public var expectedFaceBounds: CGRect? {
        switch self {
        case .started(let props):
            return props.expectedFaceBounds
        case .waiting(let props):
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
        case .faceCaptured(let props):
            return props.expectedFaceBounds
        default:
            return nil
        }
    }
    
    public var time: Double? {
        switch self {
        case .started(let props):
            return props.input.time
        case .paused(let props):
            return props.input.time
        case .faceFound(let props):
            return props.input.time
        case .faceFixed(let props):
            return props.input.time
        case .faceAligned(let props):
            return props.input.time
        case .faceMisaligned(let props):
            return props.input.time
        case .faceCaptured(let props):
            return props.input.time
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
        case .waiting(let props):
            let updatedProps = WaitingSessionProperties(requestedBearing: props.requestedBearing, expectedFaceBounds: expectedFaceBounds)
            return .waiting(updatedProps)
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
        case .faceCaptured(let props):
            let updatedProps = TrackedFaceSessionProperties(input: props.input, requestedBearing: props.requestedBearing, expectedFaceBounds: expectedFaceBounds, face: face!, smoothedFace: smoothedFace!)
            return .faceCaptured(updatedProps)
        }
    }
}

public struct WaitingSessionProperties: Hashable, Sendable {
    public let requestedBearing: Bearing
    public let expectedFaceBounds: CGRect
}

public struct StartedSessionProperties: Hashable, Sendable {
    public let input: FaceCaptureSessionImageInput
    public let requestedBearing: Bearing
    public let expectedFaceBounds: CGRect
}

public struct TrackedFaceSessionProperties: Hashable, Sendable {
    public let input: FaceCaptureSessionImageInput
    public let requestedBearing: Bearing
    public let expectedFaceBounds: CGRect
    public let face: Face
    public let smoothedFace: Face
}
