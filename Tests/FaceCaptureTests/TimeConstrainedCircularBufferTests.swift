import XCTest
@testable import FaceCapture

final class TimeConstrainedCircularBufferTests: XCTestCase {

    func testAppendedElementIsRetrievable() {
        let buffer = TimeConstrainedCircularBuffer<Int>(duration: 5)
        buffer.append(42)
        XCTAssertEqual(buffer.count, 1)
        XCTAssertEqual(buffer.last, 42)
        XCTAssertFalse(buffer.isEmpty)
    }

    func testElementsExpireAfterDuration() {
        let buffer = TimeConstrainedCircularBuffer<Int>(duration: 0.05)
        buffer.append(1)
        XCTAssertFalse(buffer.isEmpty)
        Thread.sleep(forTimeInterval: 0.1)
        buffer.append(2) // triggers removeExpiredElements
        XCTAssertEqual(buffer.count, 1)
        XCTAssertEqual(buffer.last, 2)
    }

    func testHasRemovedElementsSetAfterExpiry() {
        let buffer = TimeConstrainedCircularBuffer<Int>(duration: 0.05)
        buffer.append(1)
        XCTAssertFalse(buffer.hasRemovedElements)
        Thread.sleep(forTimeInterval: 0.1)
        buffer.append(2) // triggers removal of element 1
        XCTAssertTrue(buffer.hasRemovedElements)
    }

    func testClearResetsState() {
        let buffer = TimeConstrainedCircularBuffer<Int>(duration: 0.05)
        buffer.append(1)
        Thread.sleep(forTimeInterval: 0.1)
        buffer.append(2) // sets hasRemovedElements = true
        XCTAssertTrue(buffer.hasRemovedElements)
        buffer.clear()
        XCTAssertFalse(buffer.hasRemovedElements)
        XCTAssertTrue(buffer.isEmpty)
    }

    func testAllSatisfyReturnsTrueWhenAllMatch() {
        let buffer = TimeConstrainedCircularBuffer<Int>(duration: 5)
        buffer.append(2)
        buffer.append(4)
        buffer.append(6)
        XCTAssertTrue(buffer.allSatisfy { $0 % 2 == 0 })
    }

    func testAllSatisfyReturnsFalseWhenOneFails() {
        let buffer = TimeConstrainedCircularBuffer<Int>(duration: 5)
        buffer.append(2)
        buffer.append(3)
        buffer.append(6)
        XCTAssertFalse(buffer.allSatisfy { $0 % 2 == 0 })
    }

    // This test exposes the subscript bug: `guard index > 0` incorrectly excludes index 0.
    // It passes only after the fix changes `> 0` to `>= 0`.
    func testSubscriptAtIndexZeroReturnsFirstElement() {
        let buffer = TimeConstrainedCircularBuffer<Int>(duration: 5)
        buffer.append(99)
        XCTAssertEqual(buffer[0], 99)
    }
}
