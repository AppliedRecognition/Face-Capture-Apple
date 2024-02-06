//
//  File.swift
//  
//
//  Created by Jakub Dolejs on 02/02/2024.
//

import Foundation

extension CGAffineTransform {
    
    static func rect(_ src: CGRect, to dst: CGRect) -> CGAffineTransform {
        let scaleX = dst.width / src.width
        let scaleY = dst.height / src.height
        let translateX = dst.minX - src.minX * scaleX
        let translateY = dst.minY - src.minY * scaleY
        return CGAffineTransform(a: scaleX, b: 0, c: 0, d: scaleY, tx: translateX, ty: translateY)
    }
    
    static func horizontalMirror(in width: CGFloat) -> CGAffineTransform {
        CGAffineTransform(scaleX: -1, y: 1).concatenating(CGAffineTransform(translationX: width, y: 0))
    }
}
