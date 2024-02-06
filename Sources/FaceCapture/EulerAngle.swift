//
//  File.swift
//  
//
//  Created by Jakub Dolejs on 23/10/2023.
//

import Foundation

public struct EulerAngle<T>: Hashable where T: Numeric, T: Hashable {
    
    public var yaw: T
    public var pitch: T
    public var roll: T
    
    public init() {
        self.yaw = 0
        self.pitch = 0
        self.roll = 0
    }
    
    public init(yaw: T, pitch: T, roll: T) {
        self.yaw = yaw
        self.pitch = pitch
        self.roll = roll
    }
    
    public static func == (lhs: EulerAngle<T>, rhs: EulerAngle<T>) -> Bool {
        lhs.yaw == rhs.yaw && lhs.pitch == rhs.pitch && lhs.roll == rhs.roll
    }
}
