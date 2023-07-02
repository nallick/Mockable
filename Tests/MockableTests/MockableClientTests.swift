//
//  MockableClientTests.swift
//
//  Copyright © 2023 Purgatory Design. Licensed under the MIT License.
//

import MockableClient

import Mockable
import XCTest

final class MockableClientTests: XCTestCase {

    func testMyProtocolMock() {
        let mockMyProtocol = #Mock(MyProtocol, initializedWith: 11, 22)
        mockMyProtocol
            .function("foo() -> Int")
            .returns(123)

        let instance = mockMyProtocol.instance
        XCTAssertEqual(instance.a, 11, "Mock variable `a` initialization failed")
        XCTAssertEqual(instance.b, 22, "Mock variable `b` initialization failed")

        let result: Int = instance.foo()
        XCTAssertEqual(result, 123, "Mock function failed")
    }
}
