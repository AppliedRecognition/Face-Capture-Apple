//
//  TimeConstrainedCircularBuffer.swift
//
//
//  Created by Jakub Dolejs on 04/02/2024.
//

import Foundation
import QuartzCore

class TimeConstrainedCircularBuffer<T>: Sequence, IteratorProtocol {
    
    private var buffer: [(element: T, timestamp: TimeInterval)] = []
    private let duration: TimeInterval
    private let lock = NSLock()
    private var currentIndex: Int = 0
    private(set) public var hasRemovedElements: Bool = false
    
    typealias Element = T
    
    init(duration: TimeInterval) {
        self.duration = duration
    }
    
    func next() -> T? {
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
    
    func append(_ element: T) {
        let timestamp = CACurrentMediaTime()
        self.lock.withLock {
            self.removeExpiredElements()
            self.buffer.append((element, timestamp))
        }
    }
    
    @discardableResult
    func removeFirst() -> T? {
        self.lock.withLock {
            guard !self.buffer.isEmpty else {
                return nil
            }
            return self.buffer.removeFirst().element
        }
    }
    
    subscript(index: Int) -> T? {
        self.lock.withLock {
            guard index > 0 && index < self.buffer.count else {
                return nil
            }
            return self.buffer[index].element
        }
    }
    
    var first: T? {
        self.lock.withLock {
            self.buffer.first?.element
        }
    }
    
    var last: T? {
        self.lock.withLock {
            self.buffer.last?.element
        }
    }
    
    var count: Int {
        self.lock.withLock {
            self.buffer.count
        }
    }
    
    func clear() {
        self.lock.withLock {
            self.hasRemovedElements = false
            self.buffer.removeAll()
        }
    }
    
    var isEmpty: Bool {
        self.lock.withLock {
            self.buffer.isEmpty
        }
    }
    
    func allSatisfy(_ predicate: (T) -> Bool) -> Bool {
        self.lock.withLock {
            self.buffer.map({ $0.element }).allSatisfy(predicate)
        }
    }
    
    func suffix(_ maxLength: Int) -> [T] {
        self.lock.withLock {
            self.buffer.map({ $0.element }).suffix(maxLength)
        }
    }
    
    var oldestElementTimestamp: Double? {
        self.lock.withLock {
            self.buffer.first?.timestamp
        }
    }
    
    func filter(_ predicate: (T) -> Bool) -> [T] {
        self.lock.withLock {
            self.buffer.map { $0.element }.filter(predicate)
        }
    }
    
    func min(_ predicate: (T, T) -> Bool) -> T? {
        self.lock.withLock {
            self.buffer.map { $0.element }.min(by: predicate)
        }
    }
    
    func max(_ predicate: (T, T) -> Bool) -> T? {
        self.lock.withLock {
            self.buffer.map { $0.element }.max(by: predicate)
        }
    }
    
    var oldestElement: T? {
        self.lock.withLock {
            self.buffer.min(by: { $0.timestamp < $1.timestamp })?.element
        }
    }
    
    private func removeExpiredElements() {
        let currentTime = CACurrentMediaTime()
        let startCount = self.buffer.count
        self.buffer.removeAll { element in
            let elapsedTime = currentTime - element.timestamp
            return elapsedTime >= self.duration
        }
        if startCount > self.buffer.count {
            self.hasRemovedElements = true
        }
    }
}
