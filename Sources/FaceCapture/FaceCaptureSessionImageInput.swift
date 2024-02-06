//
//  FaceCaptureSessionImageInput.swift
//  
//
//  Created by Jakub Dolejs on 29/01/2024.
//

import Foundation
import ImageIO

public struct FaceCaptureSessionImageInput: Hashable {
    
    let serialNumber: UInt64
    let time: Double
    let image: Image
}
