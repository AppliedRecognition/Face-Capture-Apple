//
//  File.swift
//  
//
//  Created by Jakub Dolejs on 30/10/2023.
//

import Foundation
import UIKit
import Accelerate

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
    var isFaceWithBoundsFixedInImageSize: (CGRect,CGRect) -> Bool
    var alignTime: Double?
    var angleHistory: [EulerAngle<Float>] = []
    var hasFaceBeenFixed: Bool = false
    
    init(faceDetection: FaceDetection, settings: FaceCaptureSessionSettings) {
        self.faceDetection = faceDetection
        self.settings = settings
        self.faces = TimeConstrainedCircularBuffer<AlignedFace>(duration: 0.5)
        self.angleBearingEvaluation = AngleBearingEvaluation(sessionSettings: settings)
        self.isFaceWithBoundsFixedInImageSize = { bounds, expectedBounds in
            let maxRect = expectedBounds.insetBy(dx: 0-expectedBounds.width*0.3, dy: 0-expectedBounds.height*0.3)
            let minRect = expectedBounds.insetBy(dx: expectedBounds.width*0.4, dy: expectedBounds.height*0.4)
            return bounds.contains(minRect) && maxRect.contains(bounds)
        }
    }
    
    func trackFace(in imageCapture: FaceCaptureSessionImageInput) throws -> FaceTrackingResult {
        let imageSize = CGSize(width: imageCapture.image.width, height: imageCapture.image.height)
        let expectedFaceBounds = self.expectedFaceBoundsInImageSize(imageSize)
        if let face = try self.faceDetection.detectFacesInImage(imageCapture.image).first {
            let alignedFace = AlignedFace(face)
            self.faces.append(alignedFace)
            let smoothedFace = self.smoothedFace!
            self.faces.last!.isAligned = self.angleBearingEvaluation.angle(smoothedFace.angle, matchesBearing: self.requestedBearing)
            self.faces.last!.isFixed = self.isFaceWithBoundsFixedInImageSize(smoothedFace.bounds, expectedFaceBounds)
//            NSLog("Face in frame %ld: aligned = %@, fixed = %@", imageCapture.serialNumber, self.faces.last!.isAligned ? "yes" : "no", self.faces.last!.isFixed ? "yes" : "no")
//            NSLog("In frame %ld there were %d faces in the buffer: %d aligned and %d fixed", imageCapture.serialNumber, self.faces.count, self.faces.filter { $0.isAligned }.count, self.faces.filter { $0.isFixed }.count)
            if self.settings.faceCaptureCount > 1 {
                self.angleHistory.append(face.angle)
                if let previousBearing = self.previousBearing, previousBearing != self.requestedBearing {
                    let previousAngle = self.angleBearingEvaluation.angle(forBearing: previousBearing)
                    let currentAngle = self.angleBearingEvaluation.angle(forBearing: self.requestedBearing)
                    let startYaw = min(previousAngle.yaw, currentAngle.yaw)
                    let endYaw = max(previousAngle.yaw, currentAngle.yaw)
                    let yawTolerance = self.angleBearingEvaluation.thresholdAngleTolerance(forAxis: .yaw)
                    var movedTooFast = self.angleHistory.count > 1
                    var movedOpposite = false
                    for angle in self.angleHistory {
                        if angle.yaw > startYaw + yawTolerance && angle.yaw < endYaw - yawTolerance {
                            movedTooFast = false
                        }
                        if !self.angleBearingEvaluation.angle(angle, isBetweenBearing: previousBearing, and: self.requestedBearing) {
                            movedOpposite = true
                        }
                    }
                    if movedTooFast {
                        throw "Moved too fast"
//                        throw FaceCaptureError.activeLivenessError(reason: .movedTooFast(bearing: requestedBearing))
                    }
                    if movedOpposite {
                        throw "Moved opposite"
//                        throw FaceCaptureError.activeLivenessError(reason: .movedOpposite(bearing: requestedBearing))
                    }
                }
            }
        } else {
            self.angleHistory.removeAll()
        }
        var result: FaceTrackingResult = .started(StartedSessionProperties(input: imageCapture, requestedBearing: self.requestedBearing, expectedFaceBounds: expectedFaceBounds))
        if !self.hasFaceBeenFixed && !self.faces.isEmpty && self.faces.allSatisfy({ $0.isFixed }) {
            self.hasFaceBeenFixed = true
            return .faceFixed(TrackedFaceSessionProperties(input: imageCapture, requestedBearing: self.requestedBearing, expectedFaceBounds: expectedFaceBounds, face: self.faces.last!.face, smoothedFace: self.smoothedFace!))
        }
        if self.hasFaceBeenFixed, let oldestFaceTime = self.faces.oldestElementTimestamp, CACurrentMediaTime() - oldestFaceTime > 0.4 {
            if self.faces.allSatisfy({ $0.isAligned }) {
                let now = CACurrentMediaTime()
                if let alignTime = self.alignTime, now-alignTime < self.settings.pauseDuration {
                    result = .paused(StartedSessionProperties(input: imageCapture, requestedBearing: self.requestedBearing, expectedFaceBounds: expectedFaceBounds))
                } else {
                    result = .faceAligned(TrackedFaceSessionProperties(input: imageCapture, requestedBearing: self.requestedBearing, expectedFaceBounds: expectedFaceBounds, face: self.faces.last!.face, smoothedFace: self.smoothedFace!))
                    self.alignTime = now
                    self.faces.clear()
                    if self.settings.faceCaptureCount > 0 && self.settings.availableBearings.count > 1 {
                        var bearings = Array(self.settings.availableBearings)
                        bearings.removeAll(where: { $0 == self.requestedBearing })
                        let rand = Int(arc4random_uniform(UInt32(bearings.count)))
                        let index = bearings.index(bearings.startIndex, offsetBy: rand)
                        self.requestedBearing = bearings[index]
                    }
                }
            } else {
                result = .faceMisaligned(TrackedFaceSessionProperties(input: imageCapture, requestedBearing: self.requestedBearing, expectedFaceBounds: expectedFaceBounds, face: self.faces.last!.face, smoothedFace: self.smoothedFace!))
            }
            return result
        }
        if self.faces.isEmpty && self.hasFaceBeenFixed {
            throw "Face lost"
//            throw FaceCaptureError.facePresenceError(reason: .faceLost(bearing: self.requestedBearing))
        }
        if !self.faces.isEmpty {
            return .faceFound(TrackedFaceSessionProperties(input: imageCapture, requestedBearing: self.requestedBearing, expectedFaceBounds: expectedFaceBounds, face: self.faces.last!.face, smoothedFace: self.smoothedFace!))
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
    }
    
    func expectedFaceBoundsInImageSize(_ imageSize: CGSize) -> CGRect {
        let imageAspectRatio: CGFloat = imageSize.width / imageSize.height
        let expectedFaceAspectRatio: CGFloat = 4 / 5
        var size: CGSize = .zero
        if imageAspectRatio > expectedFaceAspectRatio {
            size.height = imageSize.height * 0.85
            size.width = size.height * expectedFaceAspectRatio
        } else {
            size.width = imageSize.width * 0.65
            size.height = size.width / expectedFaceAspectRatio
        }
        return CGRect(x: imageSize.width / 2 - size.width / 2, y: imageSize.height / 2 - size.height / 2, width: size.width, height: size.height)
    }
    
    var smoothingBufferSize: Int = 3
    
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
        return Face(bounds: bounds, angle: angle, quality: quality, landmarks: landmarks)
    }
    
    private func meanLandmarks(from landmarks: [[CGPoint]]) -> [CGPoint]? {
        if landmarks.isEmpty {
            return nil
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
