//
//  FaceOval.swift
//  
//
//  Created by Jakub Dolejs on 20/02/2024.
//

import SwiftUI

struct FaceOval: Shape {
    
    let faceTrackingResult: FaceTrackingResult
    
    func path(in rect: CGRect) -> Path {
        if let faceBounds = faceTrackingResult.expectedFaceBounds {
            return Path(ellipseIn: faceBounds)
        } else {
            return Path()
        }
    }
}
