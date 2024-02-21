//
//  CircularBuffer.swift
//  VerIDCore
//
//  Created by Jakub Dolejs on 04/08/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import Foundation

class CircularBuffer<T>: Sequence, IteratorProtocol {
    
    var currentIndex: Int = 0
    private let lock = NSLock()
    
    func next() -> T? {
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
    
    typealias Element = T
        
    @Atomic var capacity: Int
    private var backingArray: Array<T>
    var array: Array<T> {
        return self.backingArray
    }
    
    init(capacity: Int) {
        self.capacity = capacity
        self.backingArray = []
    }
    
    func enqueue(_ element: T) {
        self.lock.withLock {
            if self.backingArray.count == self.capacity {
                self.backingArray.removeFirst()
            }
            self.backingArray.append(element)
        }
    }
    
    @discardableResult
    func dequeue() -> T? {
        self.lock.withLock {
            guard !backingArray.isEmpty else {
                return nil
            }
            return backingArray.removeFirst()
        }
    }
    
    subscript(index: Int) -> T? {
        self.lock.withLock {
            guard index < self.backingArray.count else {
                return nil
            }
            return self.backingArray[index]
        }
    }
    
    var first: T? {
        self.lock.withLock {
            self.backingArray.first
        }
    }
    
    var last: T? {
        self.lock.withLock {
            self.backingArray.last
        }
    }
    
    var count: Int {
        self.lock.withLock {
            self.backingArray.count
        }
    }
    
    func clear() {
        self.lock.withLock {
            self.backingArray.removeAll()
        }
    }
    
    var isFull: Bool {
        self.lock.withLock {
            self.backingArray.count == self.capacity
        }
    }
    
    var isEmpty: Bool {
        self.lock.withLock {
            self.backingArray.isEmpty
        }
    }
    
    func allSatisfy(_ predicate: (T) -> Bool) -> Bool {
        self.lock.withLock {
            self.backingArray.allSatisfy(predicate)
        }
    }
    
    func suffix(_ maxLenght: Int) -> [T] {
        self.lock.withLock {
            self.backingArray.suffix(maxLenght)
        }
    }
}
