//
//  FaceTrackingResultTransformer.swift
//
//
//  Created by Jakub Dolejs on 09/02/2024.
//

import Foundation

public protocol FaceTrackingResultTransformer {
    
    func transformFaceResult(_ faceTrackingResult: FaceTrackingResult) -> FaceTrackingResult
}
