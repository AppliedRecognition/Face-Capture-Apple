//
//  File.swift
//  
//
//  Created by Jakub Dolejs on 25/10/2023.
//

import Foundation

public enum ImageFormat {
    case rgb, bgr, argb, bgra, abgr, rgba, grayscale
    
    public var bitsPerPixel: Int {
        switch self {
        case .abgr, .argb, .bgra, .rgba:
            return 32
        case .rgb, .bgr:
            return 24
        default:
            return 8
        }
    }
    
    public var bytesPerPixel: Int {
        switch self {
        case .abgr, .argb, .bgra, .rgba:
            return 4
        case .rgb, .bgr:
            return 3
        default:
            return 1
        }
    }
}
