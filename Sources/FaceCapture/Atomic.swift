//
//  Atomic.swift
//  VerIDCore
//
//  Created by Jakub Dolejs on 30/07/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import Foundation

@propertyWrapper
public struct Atomic<T> {
    
    private let lock = NSLock()
    private var value: T
    
    public var wrappedValue: T {
        get {
            let val: T
            self.lock.lock()
            val = value
            self.lock.unlock()
            return val
        }
        set {
            self.lock.lock()
            self.value = newValue
            self.lock.unlock()
        }
    }
    
    public init(wrappedValue: T) {
        self.value = wrappedValue
    }
}
