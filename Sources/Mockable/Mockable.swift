//
//  Mockable.swift
//
//  Copyright © 2023 Purgatory Design. Licensed under the MIT License.
//

/// A macro to create a test double class to mock a Swift protocol.
/// For example:
///
///     @Mockable(when: isTesting)
///     protocol MyProtocol {
///         func foo()
///     }
///
@attached(peer, names: arbitrary)
public macro Mockable(when: Bool = true) -> () = #externalMacro(module: "MockableMacros", type: "MockableMacro")
