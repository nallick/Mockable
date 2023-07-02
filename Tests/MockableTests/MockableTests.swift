//
//  MockableTests.swift
//
//  Copyright © 2023 Purgatory Design. Licensed under the MIT License.
//

import Mockable
import MockableMacros

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class MockableTests: XCTestCase {
    let testMacros: [String: Macro.Type] = [
        "Mockable": MockableMacro.self,
    ]

    func testMockProtocol() {
        let commonSource = """
            public protocol TestProtocol {
                var x: Double {
                    get
                }
                var y: Double {
                    get
                }

                func foo()
                func foo() -> Int
                func foo(_ p1: Int, p2: Double) -> Double
            }
            """
        let expandedSource = #"""
            \#(commonSource)
            public class _Mock_TestProtocol_: TestProtocol , MockTrackable {
                public var _mock_tracker_ = Mock.Tracker(functionSignatures: ["foo()", "foo() -> Int", "foo(Int, Double) -> Double",])
                public var x: Double
                public var y: Double
                public init(_ x: Double , _ y: Double ) {
                    self.x = x
                    self.y = y
                }
                public func foo() {
                    let signature = "foo()"
                    guard let trace = _mock_tracker_.trace[signature] else {
                        fatalError("Mock function required for \(signature)")
                    }
                    trace.calls.append(())
                }
                public func foo() -> Int {
                    let signature = "foo() -> Int"
                    guard let trace = _mock_tracker_.trace[signature] else {
                        fatalError("Mock function required for \(signature)")
                    }
                    trace.calls.append(())
                    guard let result = trace.result as? Int else {
                        fatalError("Mock result required for \(signature)")
                    }
                    return result
                }
                public func foo(_ p1: Int, p2: Double) -> Double {
                    let signature = "foo(Int, Double) -> Double"
                    guard let trace = _mock_tracker_.trace[signature] else {
                        fatalError("Mock function required for \(signature)")
                    }
                    trace.calls.append((p1, p2))
                    guard let result = trace.result as? Double else {
                        fatalError("Mock result required for \(signature)")
                    }
                    return result
                }
            }
            """#

        assertMacroExpansion(
            """
            @Mockable
            \(commonSource)
            """,
            expandedSource: expandedSource,
            macros: testMacros
        )
    }

    func testDisabledMacro() {
        assertMacroExpansion(
            """
            @Mockable(when: false)
            protocol TestProtocol {
            }
            """,
            expandedSource: """
            protocol TestProtocol {
            }
            """,
            macros: testMacros
        )
    }

    func testNotAppliedToProtocolError() {
        assertMacroExpansion(
            """
            @Mockable
            class TestClass {
            }
            """,
            expandedSource: """
            class TestClass {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Mockable must be applied to a protocol", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
}
