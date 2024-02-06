//
//  File.swift
//  
//
//  Created by Jakub Dolejs on 25/10/2023.
//

import Foundation
import CoreGraphics

public protocol ImageConvertible {
    
    func convertToImage() throws -> Image
    
    func convertToCGImage() throws -> CGImage
}
