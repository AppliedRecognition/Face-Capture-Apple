//
//  File.swift
//  
//
//  Created by Jakub Dolejs on 31/10/2023.
//

import Foundation
import UIKit

public struct FaceCapture {
    
    public let image: Image
    public let face: Face
    public let bearing: Bearing
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
