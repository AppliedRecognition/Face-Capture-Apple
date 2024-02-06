//
//  File.swift
//  
//
//  Created by Jakub Dolejs on 23/10/2023.
//

import Foundation
import CoreGraphics

public struct Face: Comparable, Hashable {
    
    public let bounds: CGRect
    public let angle: EulerAngle<Float>
    public let quality: Float
    public let landmarks: [CGPoint]?
    
    public static func < (lhs: Face, rhs: Face) -> Bool {
        return lhs.bounds.width * lhs.bounds.height * CGFloat(lhs.quality) > rhs.bounds.width * rhs.bounds.height * CGFloat(rhs.quality)
    }
    
    public static func == (lhs: Face, rhs: Face) -> Bool {
        return lhs.bounds == rhs.bounds && lhs.angle == rhs.angle && lhs.quality == rhs.quality && lhs.landmarks == rhs.landmarks
    }
    
    public func withBoundsSetToAspectRatio(_ aspectRatio: CGFloat) -> Face {
        var faceBounds = self.bounds
        let faceAspectRatio = faceBounds.width / faceBounds.height
        if faceAspectRatio > aspectRatio {
            let newHeight = faceBounds.width / aspectRatio
            faceBounds.origin.y = faceBounds.midY - newHeight / 2
            faceBounds.size.height = newHeight
        } else {
            let newWidth = faceBounds.height * aspectRatio
            faceBounds.origin.x = faceBounds.midX - newWidth / 2
            faceBounds.size.width = newWidth
        }
        return Face(bounds: faceBounds, angle: self.angle, quality: self.quality, landmarks: self.landmarks)
    }
    
    public func applying(_ transform: CGAffineTransform) -> Face {
        let faceBounds = self.bounds.applying(transform)
        let landmarks = self.landmarks?.map { $0.applying(transform) }
        return Face(bounds: faceBounds, angle: self.angle, quality: self.quality, landmarks: landmarks)
    }
}

extension CGRect: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.origin)
        hasher.combine(self.size)
    }
}

extension CGPoint: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.x)
        hasher.combine(self.y)
    }
}

extension CGSize: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.width)
        hasher.combine(self.height)
    }
}
