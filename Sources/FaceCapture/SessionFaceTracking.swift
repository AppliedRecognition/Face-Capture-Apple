//
//  File.swift
//  
//
//  Created by Jakub Dolejs on 30/10/2023.
//

import Foundation
import UIKit
import Accelerate
import VerIDCommonTypes
import AVFoundation

final class SessionFaceTracking {
    
    let settings: FaceCaptureSessionSettings
    let faceDetection: FaceDetection
    
    var requestedBearing: Bearing = .straight {
        didSet {
            if self.previousBearing != oldValue {
                self.previousBearing = oldValue
            }
        }
    }
    var previousBearing: Bearing?
    let angleBearingEvaluation: AngleBearingEvaluation
    private var faces: TimeConstrainedCircularBuffer<AlignedFace>
    var hasBeenAligned: Bool = false
    var isFaceWithBoundsFixedInImageSize: (CGRect,CGRect, CGSize) -> Bool
    var alignTime: Double?
    var angleHistory: [EulerAngle<Float>] = []
    var hasFaceBeenFixed: Bool = false
    var launched: Bool = false
    var started: Bool = false
    weak var delegate: SessionFaceTrackingDelegate?
    
    init(faceDetection: FaceDetection, settings: FaceCaptureSessionSettings) {
        self.faceDetection = faceDetection
        self.settings = settings
        self.faces = TimeConstrainedCircularBuffer<AlignedFace>(duration: 0.5)
        self.angleBearingEvaluation = AngleBearingEvaluation(sessionSettings: settings)
        self.isFaceWithBoundsFixedInImageSize = { bounds, expectedBounds, imageSize in
            let maxRect = CGRect(origin: .zero, size: imageSize)
            let minRect = expectedBounds.insetBy(dx: expectedBounds.width*0.4, dy: expectedBounds.height*0.4)
            return bounds.contains(minRect) && maxRect.contains(bounds)
        }
    }
    
    func trackFace(in imageCapture: FaceCaptureSessionImageInput) async throws -> FaceTrackingResult {
        let imageSize = imageCapture.image.size
        let rect = AVMakeRect(aspectRatio: imageCapture.viewSize, insideRect: CGRect(origin: .zero, size: imageSize))
        var expectedFaceBounds = self.settings.expectedFaceBoundsInSize(rect.size)
        expectedFaceBounds.origin.x += rect.minX
        expectedFaceBounds.origin.y += rect.minY
        if !self.launched {
            self.launched = true
            return .launched(WaitingSessionProperties(requestedBearing: requestedBearing, expectedFaceBounds: expectedFaceBounds))
        }
        if let face = try await self.faceDetection.detectFacesInImage(imageCapture.image, limit: 1).first?.normalizingBounds() {
            let alignedFace = AlignedFace(face)
            self.faces.append(alignedFace)
            let smoothedFace = self.smoothedFace!
            if imageCapture.time < Double(self.settings.countdownSeconds) {
                return .starting(StartedSessionProperties(input: imageCapture, requestedBearing: self.requestedBearing, expectedFaceBounds: expectedFaceBounds, smoothedFace: smoothedFace))
            } else if !self.started {
                self.started = true
                return .started(StartedSessionProperties(input: imageCapture, requestedBearing: self.requestedBearing, expectedFaceBounds: expectedFaceBounds, smoothedFace: smoothedFace))
            }
            self.faces.last!.isAligned = self.angleBearingEvaluation.angle(smoothedFace.angle, matchesBearing: self.requestedBearing)
            self.faces.last!.isFixed = self.isFaceWithBoundsFixedInImageSize(smoothedFace.bounds, expectedFaceBounds, imageSize)
            if self.settings.faceCaptureCount > 1 {
                self.angleHistory.append(smoothedFace.angle)
                if let previousBearing = self.previousBearing, previousBearing != self.requestedBearing {
                    var movedOpposite = false
                    for angle in self.angleHistory {
                        if !self.angleBearingEvaluation.angle(angle, isBetweenBearing: previousBearing, and: self.requestedBearing) {
                            movedOpposite = true
                            break
                        }
                    }
                    if movedOpposite {
                        throw FaceCaptureError.activeLivenessCheckFailed(.faceMovedOpposite)
                    }
                }
            }
        } else if imageCapture.time < Double(self.settings.countdownSeconds) {
            return .starting(StartedSessionProperties(input: imageCapture, requestedBearing: self.requestedBearing, expectedFaceBounds: expectedFaceBounds, smoothedFace: nil))
        } else {
            self.angleHistory.removeAll()
            self.faces.removeFirst()
        }
        var result: FaceTrackingResult = .started(StartedSessionProperties(input: imageCapture, requestedBearing: self.requestedBearing, expectedFaceBounds: expectedFaceBounds, smoothedFace: nil))
        if !self.hasFaceBeenFixed && self.faces.hasRemovedElements && !self.faces.isEmpty && self.faces.allSatisfy({ $0.isFixed }) {
            self.hasFaceBeenFixed = true
            return .faceFixed(TrackedFaceSessionProperties(input: imageCapture, requestedBearing: self.requestedBearing, expectedFaceBounds: expectedFaceBounds, face: self.faces.last!.face, smoothedFace: self.smoothedFace!))
        }
        if self.hasFaceBeenFixed && self.faces.hasRemovedElements && !self.faces.isEmpty {
            if self.faces.allSatisfy({ $0.isAligned }) {
                let now = CACurrentMediaTime()
                if let alignTime = self.alignTime, now-alignTime < self.settings.pauseDuration {
                    result = .paused(StartedSessionProperties(input: imageCapture, requestedBearing: self.requestedBearing, expectedFaceBounds: expectedFaceBounds, smoothedFace: nil))
                } else {
                    let props = TrackedFaceSessionProperties(input: imageCapture, requestedBearing: self.requestedBearing, expectedFaceBounds: expectedFaceBounds, face: self.faces.last!.face, smoothedFace: self.smoothedFace!)
                    if let delegate = self.delegate {
                        result = delegate.transformFaceResult(.faceAligned(props))
                    } else {
                        result = .faceCaptured(props)
                    }
                    if case .faceCaptured = result {
                        self.alignTime = now
                        self.faces.clear()
                        if self.settings.faceCaptureCount > 1 && self.settings.availableBearings.count > 1 {
                            var bearings = Array(self.settings.availableBearings)
                            bearings.removeAll(where: { $0 == self.requestedBearing })
                            self.requestedBearing = bearings[Int.random(in: 0..<bearings.count)]
                        }
                    } else {
                        result = .faceAligned(props)
                    }
                }
            } else {
                result = .faceMisaligned(TrackedFaceSessionProperties(input: imageCapture, requestedBearing: self.requestedBearing, expectedFaceBounds: expectedFaceBounds, face: self.faces.last!.face, smoothedFace: self.smoothedFace!))
            }
            return result
        }
        if self.faces.isEmpty && self.hasFaceBeenFixed {
            throw FaceCaptureError.activeLivenessCheckFailed(.faceLost)
        }
        if !self.faces.isEmpty {
            let properties = TrackedFaceSessionProperties(input: imageCapture, requestedBearing: self.requestedBearing, expectedFaceBounds: expectedFaceBounds, face: self.faces.last!.face, smoothedFace: self.smoothedFace!)
            if self.hasFaceBeenFixed {
                return .faceFixed(properties)
            }
            return .faceFound(properties)
        }
        return result
    }
    
    func reset() {
        self.faces.clear()
        self.hasBeenAligned = false
        self.hasFaceBeenFixed = false
        self.angleHistory.removeAll()
        self.alignTime = nil
        self.requestedBearing = .straight
        self.previousBearing = nil
        self.started = false
        self.launched = false
    }
    
    var smoothingBufferSize: Int = 10
    
    var smoothedFace: Face? {
        if self.faces.isEmpty {
            return nil
        }
        let tail = self.faces.suffix(self.smoothingBufferSize)
        let x = vDSP.mean(tail.map { Double($0.face.bounds.minX) })
        let y = vDSP.mean(tail.map { Double($0.face.bounds.minY) })
        let width = vDSP.mean(tail.map { Double($0.face.bounds.width) })
        let height = vDSP.mean(tail.map { Double($0.face.bounds.height) })
        let bounds = CGRect(x: x, y: y, width: width, height: height)
        let yaw = vDSP.mean(tail.map { $0.face.angle.yaw })
        let pitch = vDSP.mean(tail.map { $0.face.angle.pitch })
        let roll = vDSP.mean(tail.map { $0.face.angle.roll })
        let angle = EulerAngle(yaw: yaw, pitch: pitch, roll: roll)
        let quality = vDSP.mean(tail.map { $0.face.quality })
        let landmarks = self.meanLandmarks(from: tail.compactMap { $0.face.landmarks })
        let leftEyeX = vDSP.mean(tail.map { Double($0.face.leftEye.x) })
        let leftEyeY = vDSP.mean(tail.map { Double($0.face.leftEye.y) })
        let rightEyeX = vDSP.mean(tail.map { Double($0.face.rightEye.x) })
        let rightEyeY = vDSP.mean(tail.map { Double($0.face.rightEye.y) })
        let leftEye = CGPoint(x: leftEyeX, y: leftEyeY)
        let rightEye = CGPoint(x: rightEyeX, y: rightEyeY)
        let noseTipArray = tail.compactMap({ $0.face.noseTip })
        var noseTip: CGPoint? = nil
        if !noseTipArray.isEmpty {
            let noseTipX = vDSP.mean(noseTipArray.map { Double($0.x) })
            let noseTipY = vDSP.mean(noseTipArray.map { Double($0.y) })
            noseTip = CGPoint(x: noseTipX, y: noseTipY)
        }
        let mouthCentreArray = tail.compactMap({ $0.face.mouthCentre })
        var mouthCentre: CGPoint? = nil
        if !mouthCentreArray.isEmpty {
            let mouthCentreX = vDSP.mean(mouthCentreArray.map { Double($0.x) })
            let mouthCentreY = vDSP.mean(mouthCentreArray.map { Double($0.y) })
            mouthCentre = CGPoint(x: mouthCentreX, y: mouthCentreY)
        }
        return Face(bounds: bounds, angle: angle, quality: quality, landmarks: landmarks, leftEye: leftEye, rightEye: rightEye, noseTip: noseTip, mouthCentre: mouthCentre)
    }
    
    private func meanLandmarks(from landmarks: [[CGPoint]]) -> [CGPoint] {
        if landmarks.isEmpty {
            return []
        }
        let landmarkCount = UInt(landmarks.first!.count)
        let xs = landmarks.map { $0.map { $0.x }}.reduce([], +).map { Double($0) }
        let ys = landmarks.map { $0.map { $0.y }}.reduce([], +).map { Double($0) }
        let transposedXs: [Double] = [Double](unsafeUninitializedCapacity: xs.count) { buffer, cap in
            vDSP_mtransD(xs, 1, buffer.baseAddress!, 1, landmarkCount, UInt(landmarks.count))
            cap = xs.count
        }
        let transposedYs = [Double](unsafeUninitializedCapacity: ys.count) { buffer, cap in
            vDSP_mtransD(ys, 1, buffer.baseAddress!, 1, landmarkCount, UInt(landmarks.count))
            cap = ys.count
        }
        let meanXs = stride(from: 0, to: transposedXs.count, by: landmarks.count).map { i in
            vDSP.mean(transposedXs[i..<i+landmarks.count])
        }
        let meanYs = stride(from: 0, to: transposedYs.count, by: landmarks.count).map { i in
            vDSP.mean(transposedYs[i..<i+landmarks.count])
        }
        return zip(meanXs, meanYs).map { x, y in CGPoint(x: x, y: y) }
    }

}

fileprivate class AlignedFace {
    
    let face: Face
    var isAligned: Bool = false
    var isFixed: Bool = false
    
    init(_ face: Face) {
        self.face = face
    }
}

protocol SessionFaceTrackingDelegate: AnyObject {
    
    func transformFaceResult(_ faceTrackingResult: FaceTrackingResult) -> FaceTrackingResult
}
