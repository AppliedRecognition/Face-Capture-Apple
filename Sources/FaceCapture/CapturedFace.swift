//
//  File.swift
//  
//
//  Created by Jakub Dolejs on 31/10/2023.
//

import Foundation
import UIKit
import VerIDCommonTypes

/// Face and image captured in a face capture session
/// - Since: 1.0.0
public struct CapturedFace: Hashable {
    
    /// Captured image
    /// - Since: 1.0.0
    public let image: Image
    /// Face detected in the image
    /// - Since: 1.0.0
    public let face: Face
    /// Bearing of the detected face
    /// - Since: 1.0.0
    public let bearing: Bearing
    /// Captured image cropped to the bounds of the detected face
    /// - Since: 1.0.0
    public lazy var faceImage: UIImage? = {
        guard let cgImage = try? self.image.convertToCGImage() else {
            return nil
        }
        let renderer = UIGraphicsImageRenderer(size: face.bounds.size)
        return renderer.image { context in
            UIImage(cgImage: cgImage).draw(at: CGPoint(x: 0-face.bounds.minX, y: 0-face.bounds.minY))
        }
    }()
}
