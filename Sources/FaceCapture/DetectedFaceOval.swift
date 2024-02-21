//
//  DetectedFaceOval.swift
//
//
//  Created by Jakub Dolejs on 20/02/2024.
//

import SwiftUI

struct DetectedFaceOval: Shape {
    
    let faceTrackingResult: FaceTrackingResult
    
    func path(in rect: CGRect) -> Path {
        if case .faceFound(let properties) = faceTrackingResult {
            return Path(ellipseIn: properties.smoothedFace.bounds)
        } else if let expectedFaceBounds = faceTrackingResult.expectedFaceBounds {
            return Path(ellipseIn: expectedFaceBounds)
        } else {
            return Path()
        }
    }
}
