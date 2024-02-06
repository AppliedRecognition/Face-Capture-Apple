//
//  CircularBuffer.swift
//  VerIDCore
//
//  Created by Jakub Dolejs on 04/08/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import Foundation

public class CircularBuffer<T>: Sequence, IteratorProtocol {
    
    var currentIndex: Int = 0
    private let lock = NSLock()
    
    public func next() -> T? {
        self.lock.withLock {
            guard self.currentIndex < self.backingArray.count else {
                return nil
            }
            defer {
                self.currentIndex += 1
            }
            return self.backingArray[self.currentIndex]
        }
    }
    
    public typealias Element = T
        
    @Atomic public var capacity: Int
    private var backingArray: Array<T>
    public var array: Array<T> {
        return self.backingArray
    }
    
    public init(capacity: Int) {
        self.capacity = capacity
        self.backingArray = []
    }
    
    public func enqueue(_ element: T) {
        self.lock.withLock {
            if self.backingArray.count == self.capacity {
                self.backingArray.removeFirst()
            }
            self.backingArray.append(element)
        }
    }
    
    @discardableResult
    public func dequeue() -> T? {
        self.lock.withLock {
            guard !backingArray.isEmpty else {
                return nil
            }
            return backingArray.removeFirst()
        }
    }
    
    public subscript(index: Int) -> T? {
        self.lock.withLock {
            guard index < self.backingArray.count else {
                return nil
            }
            return self.backingArray[index]
        }
    }
    
    public var first: T? {
        self.lock.withLock {
            self.backingArray.first
        }
    }
    
    public var last: T? {
        self.lock.withLock {
            self.backingArray.last
        }
    }
    
    public var count: Int {
        self.lock.withLock {
            self.backingArray.count
        }
    }
    
    public func clear() {
        self.lock.withLock {
            self.backingArray.removeAll()
        }
    }
    
    public var isFull: Bool {
        self.lock.withLock {
            self.backingArray.count == self.capacity
        }
    }
    
    public var isEmpty: Bool {
        self.lock.withLock {
            self.backingArray.isEmpty
        }
    }
    
    public func allSatisfy(_ predicate: (T) -> Bool) -> Bool {
        self.lock.withLock {
            self.backingArray.allSatisfy(predicate)
        }
    }
    
    public func suffix(_ maxLenght: Int) -> [T] {
        self.lock.withLock {
            self.backingArray.suffix(maxLenght)
        }
    }
}
