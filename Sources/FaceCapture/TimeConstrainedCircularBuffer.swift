//
//  TimeConstrainedCircularBuffer.swift
//
//
//  Created by Jakub Dolejs on 04/02/2024.
//

import Foundation
import QuartzCore

public class TimeConstrainedCircularBuffer<T>: Sequence, IteratorProtocol {
    
    private var buffer: [(element: T, timestamp: TimeInterval)] = []
    private let duration: TimeInterval
    private let lock = NSLock()
    private var currentIndex: Int = 0
    
    public typealias Element = T
    
    public init(duration: TimeInterval) {
        self.duration = duration
    }
    
    public func next() -> T? {
        self.lock.withLock {
            guard self.currentIndex < self.buffer.count else {
                return nil
            }
            defer {
                self.currentIndex += 1
            }
            return self.buffer[self.currentIndex].element
        }
    }
    
    public func append(_ element: T) {
        let timestamp = CACurrentMediaTime()
        self.lock.withLock {
            self.buffer.append((element, timestamp))
            self.removeExpiredElements()
        }
    }
    
    @discardableResult
    public func removeFirst() -> T? {
        self.lock.withLock {
            guard !self.buffer.isEmpty else {
                return nil
            }
            return self.buffer.removeFirst().element
        }
    }
    
    public subscript(index: Int) -> T? {
        self.lock.withLock {
            guard index > 0 && index < self.buffer.count else {
                return nil
            }
            return self.buffer[index].element
        }
    }
    
    public var first: T? {
        self.lock.withLock {
            self.buffer.first?.element
        }
    }
    
    public var last: T? {
        self.lock.withLock {
            self.buffer.last?.element
        }
    }
    
    public var count: Int {
        self.lock.withLock {
            self.buffer.count
        }
    }
    
    public func clear() {
        self.lock.withLock {
            self.buffer.removeAll()
        }
    }
    
    public var isEmpty: Bool {
        self.lock.withLock {
            self.buffer.isEmpty
        }
    }
    
    public func allSatisfy(_ predicate: (T) -> Bool) -> Bool {
        self.lock.withLock {
            self.buffer.map({ $0.element }).allSatisfy(predicate)
        }
    }
    
    public func suffix(_ maxLength: Int) -> [T] {
        self.lock.withLock {
            self.buffer.map({ $0.element }).suffix(maxLength)
        }
    }
    
    public var oldestElementTimestamp: Double? {
        self.lock.withLock {
            self.buffer.first?.timestamp
        }
    }
    
    private func removeExpiredElements() {
        let currentTime = CACurrentMediaTime()
        self.buffer.removeAll { element in
            let elapsedTime = currentTime - element.timestamp
            return elapsedTime >= self.duration
        }
    }
}
