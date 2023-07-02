//
//  MockablePlugin.swift
//
//  Copyright © 2023 Purgatory Design. Licensed under the MIT License.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
public struct MockablePlugin: CompilerPlugin {
    public let providingMacros: [Macro.Type] = [
        MockMacro.self,
        MockableMacro.self,
    ]

    public init() {}
}
