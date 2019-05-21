//
//  AtomicTests.swift
//  AtomicTests
//
//  Created by Adlai Holler on 12/5/15.
//  Copyright © 2015 Adlai Holler. All rights reserved.
//

import XCTest
@testable import Atomic

class AtomicTests: XCTestCase {

    func testModify() {
        let atomic = Atomic(0)
        atomic.modify { $0 + 7 }
        XCTAssertEqual(atomic._value, 7)
    }

    func testWithValue() {
        let atomic = Atomic(0)
        let result = atomic.withValue { $0 + 7 }
        XCTAssertEqual(atomic._value, 0)
        XCTAssertEqual(result, 7)
    }

    func testSetProperty() {
        let atomic = Atomic(0)
        atomic.value = 25
        XCTAssertEqual(atomic._value, 25)
    }

    func testGetProperty() {
        let atomic = Atomic(0)
        atomic._value = 25
        XCTAssertEqual(atomic.value, 25)
    }

    func testSwap() {
        let atomic = Atomic(1)
        let oldValue = atomic.swap(25)
        XCTAssertEqual(oldValue, 1)
        XCTAssertEqual(atomic._value, 25)
    }

    func testRethrowFromWithValue() {
        let atomic = Atomic(10)
        var didCatch = false
        do {
            try atomic.withValue { value in
                throw NSError(domain: NSCocoaErrorDomain, code: value, userInfo: nil)
            }
            XCTFail()
        } catch let error as NSError {
            didCatch = true
            XCTAssertEqual(error, NSError(domain: NSCocoaErrorDomain, code: 10, userInfo: nil))
        }
        if atomic.lock.tryLock() == 0 {
            atomic.lock.unlock()
        } else {
            XCTFail()
        }
        XCTAssert(didCatch)
    }

    func testRethrowFromModify() {
        let atomic = Atomic(10)
        var didCatch = false
        do {
            try atomic.modify { value in
                throw NSError(domain: NSCocoaErrorDomain, code: value, userInfo: nil)
            }
            XCTFail()
        } catch let error as NSError {
            didCatch = true
            XCTAssertEqual(error, NSError(domain: NSCocoaErrorDomain, code: 10, userInfo: nil))
        }
        if atomic.lock.tryLock() == 0 {
            atomic.lock.unlock()
        } else {
            XCTFail()
        }
        XCTAssert(didCatch)
    }

    func testHighlyContestedLocking() {
        let contestedAtomic = Atomic(0)
        let concurrentQueue = DispatchQueue.global()
        let dispatchGroup = DispatchGroup()
        let count = 100_000
        for _ in 0..<count {
            dispatchGroup.enter()
            concurrentQueue.async() {
                contestedAtomic.modify { $0 + 1 }
                dispatchGroup.leave()
            }
        }
        let aExpectation = expectation(description: "Dispatch Group Completion")
        dispatchGroup.notify(queue: concurrentQueue) {
            aExpectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)

        XCTAssertEqual(contestedAtomic._value, count)
    }
    
}
