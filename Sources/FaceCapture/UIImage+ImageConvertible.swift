//
//  File.swift
//  
//
//  Created by Jakub Dolejs on 25/10/2023.
//

import Foundation
import UIKit

extension UIImage: ImageConvertible {
    
    public func convertToImage() throws -> Image {
        return try self.convertToCGImage().convertToImage()
    }
    
    public func convertToCGImage() throws -> CGImage {
        UIGraphicsBeginImageContext(self.size)
        defer {
            UIGraphicsEndImageContext()
        }
        self.draw(at: .zero)
        if let img = UIGraphicsGetImageFromCurrentImageContext()?.cgImage {
            return img
        }
        throw "Image conversion failed"
    }
    
}
