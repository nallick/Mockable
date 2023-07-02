//
//  MockMacro.swift
//
//  Copyright © 2023 Purgatory Design. Licensed under the MIT License.
//

import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `Mock` macro, which creates a test double instance to mock a Swift protocol.
/// For example:
///
///     @Mockable
///     protocol MyProtocol {
///         func foo()
///     }
///
///     let mock = #Mock(MyProtocol)
///
public struct MockMacro: ExpressionMacro {

    public static func expansion(of node: some FreestandingMacroExpansionSyntax, in context: some MacroExpansionContext) throws -> ExprSyntax {
        guard let firstArgument = node.argumentList.first?.expression else { throw CompilerDiagnostic.testNoProtocolSpecified }
        let mockClassName = MockableMacro.mockClassName(for: firstArgument.description)
        let initArgumentList = node.argumentList.dropFirst().map { $0.expression.description }
        return "Mock.Wrapper<\(raw: firstArgument.description)>(instance: \(raw: mockClassName)(\(raw: initArgumentList.joined(separator: ", "))))"
    }
}

extension MockMacro {

    public enum CompilerDiagnostic: String, DiagnosticMessage, Error {
        case testNoProtocolSpecified

        public var diagnosticID: MessageID { MessageID(domain: "MockableMacro", id: rawValue) }

        public var message: String {
            switch self {
                case .testNoProtocolSpecified: "#Mock requires a protocol to mock"
            }
        }

        public var severity: DiagnosticSeverity {
            switch self {
                case .testNoProtocolSpecified: .error
            }
        }
    }
}
