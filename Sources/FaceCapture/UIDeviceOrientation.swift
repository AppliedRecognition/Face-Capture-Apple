//
//  File.swift
//  
//
//  Created by Jakub Dolejs on 30/01/2024.
//

import Foundation
import UIKit
import ImageIO
import AVFoundation

extension UIDeviceOrientation {
    
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch self {
        case .landscapeLeft:
            return .up
        case .landscapeRight:
            return .down
        case .portraitUpsideDown:
            return .left
        default:
            return .right
        }
//        CGImagePropertyOrientation(rawValue: UInt32(self.rawValue)) ?? .right
    }
    
    var videoOrientation: AVCaptureVideoOrientation {
        switch self {
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
}
