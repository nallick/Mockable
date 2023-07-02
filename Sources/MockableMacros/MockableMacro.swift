//
//  MockableMacro.swift
//
//  Copyright © 2023 Purgatory Design. Licensed under the MIT License.
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `Mockable` macro, which creates a test double class to mock a Swift protocol.
/// For example:
///
///     @Mockable
///     protocol MyProtocol {
///         func foo()
///     }
///
public enum MockableMacro: PeerMacro {

    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard let protocolDeclaration = declaration.as(ProtocolDeclSyntax.self) else { throw CompilerDiagnostic.notAppliedToProtocol }

        if case .attribute(let firstAttribute) = protocolDeclaration.attributes?.first,
           case .argumentList(let argumentList) = firstAttribute.argument,
           let enabledArgument = argumentList.first(where: { $0.label?.text == "when" }) {
               if enabledArgument.expression.description == "false" { return [] }
        }

        let classDeclaration = try mockClassDeclaration(for: protocolDeclaration)
        return [DeclSyntax(classDeclaration)]
    }
}

extension MockableMacro {

    internal static func mockClassName(for protocolName: String) -> String {
        "_Mock_" + protocolName + "_"
    }

    private static func mockClassDeclaration(for protocolDeclaration: ProtocolDeclSyntax) throws -> ClassDeclSyntax {
        let identifier = TokenSyntax.identifier(self.mockClassName(for: protocolDeclaration.identifier.text))
        let variableDeclarations = protocolDeclaration.memberBlock.members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
        let functionDeclarations = protocolDeclaration.memberBlock.members.compactMap { $0.decl.as(FunctionDeclSyntax.self) }

        return try ClassDeclSyntax(
            modifiers: protocolDeclaration.modifiers,
            identifier: identifier,
            inheritanceClause: TypeInheritanceClauseSyntax {
                InheritedTypeSyntax(typeName: SimpleTypeIdentifierSyntax(name: protocolDeclaration.identifier))
                InheritedTypeSyntax(typeName: SimpleTypeIdentifierSyntax(name: "MockTrackable"))
            },
            memberBlockBuilder: {
                let functionSignatures = functionDeclarations.map { ArrayElementSyntax(expression: StringLiteralExprSyntax(content: $0.mockSignature), trailingComma: .commaToken()) }
                VariableDeclSyntax(
                    modifiers: protocolDeclaration.modifiers,
                    bindingKeyword: .keyword(.var),
                    bindingsBuilder: {
                        PatternBindingSyntax(
                            pattern: IdentifierPatternSyntax(identifier: "_mock_tracker_"),
                            initializer: InitializerClauseSyntax(value: FunctionCallExprSyntax(
                                    calledExpression: MemberAccessExprSyntax(base: IdentifierExprSyntax(identifier: "Mock"), dot: .periodToken(), name: .identifier("Tracker")),
                                    leftParen: .leftParenToken(),
                                    argumentList: TupleExprElementListSyntax([TupleExprElementSyntax(
                                        label: "functionSignatures",
                                        expression: ArrayExprSyntax(elements: ArrayElementListSyntax(functionSignatures)))
                                    ]),
                                    rightParen: .rightParenToken()
                            )))
                    }
                )

                for variable in variableDeclarations {
                    if let binding = variable.bindings.first {
                        VariableDeclSyntax(modifiers: protocolDeclaration.modifiers, bindingKeyword: .keyword(.var)) {
                            PatternBindingSyntax(
                                pattern: binding.pattern,
                                typeAnnotation: binding.typeAnnotation
                            )
                        }
                    }
                }

                let protocolVariables: [(String, TypeSyntax)] = variableDeclarations.compactMap {
                    guard let binding = $0.bindings.first, let typeAnnotation = binding.typeAnnotation else { return nil }
                    return (binding.pattern.description, typeAnnotation.type)
                }
                let initializerSignature = FunctionSignatureSyntax(input: ParameterClauseSyntax {
                    for variable in protocolVariables {
                        FunctionParameterSyntax(firstName: .wildcardToken(), secondName: TokenSyntax(stringLiteral: variable.0), type: variable.1)
                    }
                })
                InitializerDeclSyntax(modifiers: protocolDeclaration.modifiers, signature: initializerSignature) {
                    for variable in protocolVariables {
                        ExprSyntax("self.\(raw: variable.0) = \(raw: variable.0)")
                    }
                }

                for function in functionDeclarations {
                    try FunctionDeclSyntax(
                        attributes: function.attributes,
                        modifiers: protocolDeclaration.modifiers,
                        funcKeyword: function.funcKeyword,
                        identifier: function.identifier,
                        genericParameterClause: function.genericParameterClause,
                        signature: function.signature,
                        genericWhereClause: function.genericWhereClause,
                        bodyBuilder: {
                            VariableDeclSyntax(
                                bindingKeyword: .keyword(.let),
                                bindingsBuilder: {
                                    PatternBindingSyntax(
                                        pattern: IdentifierPatternSyntax(identifier: "signature"),
                                        initializer: InitializerClauseSyntax(value: StringLiteralExprSyntax(content: function.mockSignature))
                                    )
                                }
                            )

                            try GuardStmtSyntax(PartialSyntaxNodeString(stringLiteral: "guard let trace = _mock_tracker_.trace[signature] else")) {
                                DeclSyntax(#"fatalError("Mock function required for \(signature)")"#)
                            }

                            let parameterNames = function.signature.input.parameterList.map { $0.secondName?.description ?? $0.firstName.description }
                            DeclSyntax("trace.calls.append((\(raw: parameterNames.joined(separator: ", "))))")

                            if let outputType = function.signature.output?.returnType.description {
                                try GuardStmtSyntax(PartialSyntaxNodeString(stringLiteral: "guard let result = trace.result as? \(outputType) else")) {
                                    DeclSyntax(#"fatalError("Mock result required for \(signature)")"#)
                                }
                                DeclSyntax("return result")
                            }
                        }
                    )
                }
            })
    }
}

extension MockableMacro {

    public enum CompilerDiagnostic: String, DiagnosticMessage, Error {
        case notAppliedToProtocol

        public var diagnosticID: MessageID { MessageID(domain: "MockableMacro", id: rawValue) }

        public var message: String {
            switch self {
                case .notAppliedToProtocol: "@Mockable must be applied to a protocol"
            }
        }

        public var severity: DiagnosticSeverity {
            switch self {
                case .notAppliedToProtocol: .error
            }
        }
    }
}

extension FunctionDeclSyntax {

    public var mockSignature: String {
        let inputSignature = signature.input.parameterList.map({ $0.type.description }).joined(separator: ", ")
        let outputSignature = (signature.output?.description).map { " " + $0 } ?? ""
        return "\(identifier)(\(inputSignature))\(outputSignature)"
    }
}
