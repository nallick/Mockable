//
//  MockTests.swift
//
//  Copyright © 2023 Purgatory Design. Licensed under the MIT License.
//

import Mockable
import MockableMacros

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class MockTests: XCTestCase {
    let testMacros: [String: Macro.Type] = [
        "Mock": MockMacro.self,
        "Mockable": MockableMacro.self,
    ]

    func testMockInstantiation() {
        assertMacroExpansion(
            """
            @Mockable
            protocol TestProtocol {
                var x: Int { get }
                var y: Int { get }
            }
            let mock = #Mock(TestProtocol, initializedWith: 1, 2)
            """,
            expandedSource: """
            protocol TestProtocol {
                var x: Int {
                    get
                }
                var y: Int {
                    get
                }
            }
            class _Mock_TestProtocol_: TestProtocol , MockTrackable {
                var _mock_tracker_ = Mock.Tracker(functionSignatures: [])
                var x: Int
                var y: Int
                init(_ x: Int , _ y: Int ) {
                    self.x = x
                    self.y = y
                }
            }
            let mock = Mock.Wrapper<TestProtocol>(instance: _Mock_TestProtocol_(1, 2))
            """,
            macros: testMacros
        )
    }

    func testNoProtocolSpecifiedError() {
        assertMacroExpansion(
            """
            let mock = #Mock()
            """,
            expandedSource: """
            let mock = #Mock()
            """,
            diagnostics: [
                DiagnosticSpec(message: "#Mock requires a protocol to mock", line: 1, column: 12)
            ],
            macros: testMacros
        )
    }
}
