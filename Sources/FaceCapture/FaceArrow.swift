//
//  FaceArrow.swift
//
//
//  Created by Jakub Dolejs on 20/02/2024.
//

import SwiftUI

struct FaceArrow: Shape {
    
    let faceTrackingResult: FaceTrackingResult
    let angleBearingEvaluation: AngleBearingEvaluation
    
    func path(in rect: CGRect) -> Path {
        if case .faceMisaligned(let properties) = self.faceTrackingResult {
            let offsetAngle = self.angleBearingEvaluation.offsetFromAngle(properties.smoothedFace.angle, toBearing: properties.requestedBearing)
            let angle: CGFloat = atan2(CGFloat(0.0-offsetAngle.pitch), CGFloat(offsetAngle.yaw))
            let distance: CGFloat = CGFloat(hypot(offsetAngle.yaw, 0-offsetAngle.pitch) * 2)
            //            let scale = rect.width / CGFloat(properties.input.image.width)
            //            let faceBounds = properties.expectedFaceBounds.applying(CGAffineTransform(scaleX: scale, y: scale))
            let faceBounds = properties.expectedFaceBounds
            
            let arrowLength = faceBounds.width / 5
            let stemLength = min(max(arrowLength * distance, arrowLength * 0.75), arrowLength * 1.7)
            let arrowAngle = CGFloat(Measurement(value: 40, unit: UnitAngle.degrees).converted(to: .radians).value)
            let arrowTip = CGPoint(x: faceBounds.midX + cos(angle) * arrowLength / 2, y: faceBounds.midY + sin(angle) * arrowLength / 2)
            let arrowPoint1 = CGPoint(x: arrowTip.x + cos(angle + CGFloat.pi - arrowAngle) * arrowLength * 0.6, y: arrowTip.y + sin(angle + CGFloat.pi - arrowAngle) * arrowLength * 0.6)
            let arrowPoint2 = CGPoint(x: arrowTip.x + cos(angle + CGFloat.pi + arrowAngle) * arrowLength * 0.6, y: arrowTip.y + sin(angle + CGFloat.pi + arrowAngle) * arrowLength * 0.6)
            let arrowStart = CGPoint(x: arrowTip.x + cos(angle + CGFloat.pi) * stemLength, y: arrowTip.y + sin(angle + CGFloat.pi) * stemLength)
            
            return Path { path in
                path.move(to: arrowPoint1)
                path.addLine(to: arrowTip)
                path.addLine(to: arrowPoint2)
                path.move(to: arrowTip)
                path.addLine(to: arrowStart)
            }
        } else {
            return Path()
        }
    }
}
