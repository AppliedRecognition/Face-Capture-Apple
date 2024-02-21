//
//  AngleBearingEvaluation.swift
//  VerIDCore
//
//  Created by Jakub Dolejs on 03/04/2019.
//  Copyright © 2019 Applied Recognition. All rights reserved.
//

import UIKit
import VerIDCommonTypes

class AngleBearingEvaluation: NSObject {
    
    let sessionSettings: FaceCaptureSessionSettings

    init(sessionSettings: FaceCaptureSessionSettings) {
        self.sessionSettings = sessionSettings
    }
    
    func angle(forBearing bearing: Bearing) -> EulerAngle<Float> {
        let pitchDistance = self.thresholdAngle(forAxis: .pitch)
        let yawDistance = self.thresholdAngle(forAxis: .yaw)
        var angle = EulerAngle<Float>()
        switch bearing {
        case .up, .leftUp, .rightUp:
            angle.pitch = 0 - pitchDistance
        case .down, .leftDown, .rightDown:
            angle.pitch = pitchDistance
        default:
            angle.pitch = 0
        }
        switch bearing {
        case .left, .leftDown, .leftUp:
            angle.yaw = 0 - yawDistance
        case .right, .rightDown, .rightUp:
            angle.yaw = yawDistance
        default:
            angle.yaw = 0
        }
        return angle
    }
    
    /// Whether the angle can be considered to be matching the given bearing
    ///
    /// - Parameters:
    ///   - angle: Angle to evaluate against the bearing
    ///   - bearing: Bearing the angle should match
    /// - Returns: `true` if the angle can be considered to be matching the bearing
    func angle(_ angle: EulerAngle<Float>, matchesBearing bearing: Bearing) -> Bool {
        let minAngle = self.minAngle(forBearing: bearing)
        let maxAngle = self.maxAngle(forBearing: bearing)
        return angle.pitch > minAngle.pitch && angle.pitch < maxAngle.pitch && angle.yaw > minAngle.yaw && angle.yaw < maxAngle.yaw
    }
    
    /// Offset from the an angle to the given bearing.
    /// Used, for example, to calculate the arrow showing the user where to move
    ///
    /// - Parameters:
    ///   - from: Angle from which to calculate the offset to the bearing
    ///   - bearing: Bearing to which the offset should be calculated
    /// - Returns: Angle that represents the difference (offset) between the given angle to the bearing angle
    func offsetFromAngle(_ from: EulerAngle<Float>, toBearing bearing: Bearing) -> EulerAngle<Float> {
        var result = EulerAngle<Float>()
        if !self.angle(from, matchesBearing: bearing) {
            let bearingAngle = self.angle(forBearing: bearing)
            result.yaw = (bearingAngle.yaw - from.yaw) / (self.thresholdAngle(forAxis: .yaw) + self.thresholdAngleTolerance(forAxis: .yaw))
            result.pitch = (from.pitch - bearingAngle.pitch) / (self.thresholdAngle(forAxis: .pitch) + self.thresholdAngleTolerance(forAxis: .pitch))
        }
        return result
    }
    
    func isPoint(_ pt: CGPoint, toRightOfPlaneBetweenPoint start: CGPoint, and end: CGPoint) -> Bool {
        let d = (pt.x - start.x) * (end.y - start.y) - (pt.y - start.y) * (end.x - start.x)
        return d <= 0
    }
    
    func isPoint(_ pt: CGPoint, insideCircleCentredIn centre: CGPoint, withRadius radius: Float) -> Bool {
        return hypot(pt.x-centre.x, pt.y-centre.y) <= CGFloat(radius)
    }
    
    func angle(_ angle: EulerAngle<Float>, isBetweenBearing fromBearing: Bearing, and toBearing: Bearing) -> Bool {
        if self.angle(angle, matchesBearing: fromBearing) || self.angle(angle, matchesBearing: toBearing) {
            return true
        }
        let fromAngle = self.angle(forBearing: fromBearing)
        let toAngle = self.angle(forBearing: toBearing)
        
        let start = CGPoint(x: CGFloat(fromAngle.yaw), y: CGFloat(fromAngle.pitch))
        let end = CGPoint(x: CGFloat(toAngle.yaw), y: CGFloat(toAngle.pitch))
        let pt = CGPoint(x: CGFloat(angle.yaw), y: CGFloat(angle.pitch))
        let radius = max(thresholdAngle(forAxis: .pitch), thresholdAngle(forAxis: .yaw))
        let angleRad = Float(atan2(end.y-start.y, end.x-start.x)) + Float.pi*0.5
        
        let cosRad = cos(angleRad) * radius
        let sinRad = sin(angleRad) * radius
        let startRight = CGPoint(x: start.x + CGFloat(cosRad), y: start.y + CGFloat(sinRad)),
            startLeft = CGPoint(x: start.x - CGFloat(cosRad), y: start.y - CGFloat(sinRad)),
            endRight = CGPoint(x: end.x + CGFloat(cosRad), y: end.y + CGFloat(sinRad)),
            endLeft = CGPoint(x: end.x - CGFloat(cosRad), y: end.y - CGFloat(sinRad))
        return !isPoint(pt, toRightOfPlaneBetweenPoint: startRight, and: endRight)
            && isPoint(pt, toRightOfPlaneBetweenPoint: startLeft, and: endLeft)
            && (isPoint(pt, toRightOfPlaneBetweenPoint: startRight, and: startLeft) || isPoint(pt, insideCircleCentredIn: start, withRadius: radius))
    }
    
    private func minAngle(forBearing bearing: Bearing) -> EulerAngle<Float> {
        let pitchDistance = self.thresholdAngle(forAxis: .pitch)
        let pitchTolerance = self.thresholdAngleTolerance(forAxis: .pitch)
        let yawDistance = self.thresholdAngle(forAxis: .yaw)
        let yawTolerance = self.thresholdAngleTolerance(forAxis: .yaw)
        var angle = EulerAngle<Float>()
        switch bearing {
        case .up, .leftUp, .rightUp:
            angle.pitch = 0 - Float.greatestFiniteMagnitude
        case .down, .leftDown, .rightDown:
            angle.pitch = pitchDistance - pitchTolerance
        default:
            angle.pitch = 0 - pitchDistance + pitchTolerance
        }
        switch bearing {
        case .left, .leftDown, .leftUp:
            angle.yaw = 0 - Float.greatestFiniteMagnitude
        case .right, .rightDown, .rightUp:
            angle.yaw = yawDistance - yawTolerance
        default:
            angle.yaw = 0 - yawDistance + yawTolerance
        }
        return angle
    }
    
    private func maxAngle(forBearing bearing: Bearing) -> EulerAngle<Float> {
        let pitchDistance = self.thresholdAngle(forAxis: .pitch)
        let pitchTolerance = self.thresholdAngleTolerance(forAxis: .pitch)
        let yawDistance = self.thresholdAngle(forAxis: .yaw)
        let yawTolerance = self.thresholdAngleTolerance(forAxis: .yaw)
        var angle = EulerAngle<Float>()
        switch bearing {
        case .up, .leftUp, .rightUp:
            angle.pitch = 0 - pitchDistance + pitchTolerance
        case .down, .leftDown, .rightDown:
            angle.pitch = Float.greatestFiniteMagnitude
        default:
            angle.pitch = pitchDistance - pitchTolerance
        }
        switch bearing {
        case .left, .leftDown, .leftUp:
            angle.yaw = 0 - yawDistance + yawTolerance
        case .right, .rightDown, .rightUp:
            angle.yaw = Float.greatestFiniteMagnitude
        default:
            angle.yaw = yawDistance - yawTolerance
        }
        return angle
    }
    
    func thresholdAngle(forAxis axis: Axis) -> Float {
        if axis == .pitch {
            return self.sessionSettings.pitchThreshold
        } else {
            return self.sessionSettings.yawThreshold
        }
    }
    
    func thresholdAngleTolerance(forAxis axis: Axis) -> Float {
        if axis == .pitch {
            return self.sessionSettings.pitchThresholdTolerance
        } else {
            return self.sessionSettings.yawThresholdTolerance
        }
    }
}

enum Axis: Int {
    case pitch, yaw
}
