//
//  Mock.swift
//
//  Copyright © 2023 Purgatory Design. Licensed under the MIT License.
//

import Foundation

/// A macro to create a test double instance to mock a Swift protocol.
/// For example:
///
///     @Mockable
///     protocol MyProtocol {
///         func foo()
///     }
///
///     let mock = #Mock(MyProtocol)
///     let mockInstance = mock.instance
///
@freestanding(expression)
public macro Mock<Protocol>(_ protocolToMock: Protocol.Type, initializedWith: Any...) -> Mock.Wrapper<Protocol> = #externalMacro(module: "MockableMacros", type: "MockMacro")

public enum Mock {

    public class FunctionTrace {
        public var result: Any?
        public var calls: [Any?]

        public init(result: Any? = nil, calls: [Any?] = []) {
            self.result = result
            self.calls = calls
        }

        public func returns(_ result: Any?) { self.result = result }
    }

    public struct Tracker {
        public var trace: [String: FunctionTrace]

        public init(functionSignatures: [String]) {
            self.trace = functionSignatures.reduce(into: [String: FunctionTrace]()) { $0[$1] = FunctionTrace() }
        }

        public func function(_ signature: String) -> FunctionTrace {
            guard let functionTrace = trace[signature] else { fatalError("Invalid function signature: \(signature)") }
            return functionTrace
        }
    }

    public struct Wrapper<Protocol> {
        public let instance: Protocol
        public var trackable: MockTrackable { instance as! MockTrackable }

        public init(instance: Protocol) {
            guard instance is MockTrackable else { fatalError("Mock.Wrapper instance must be Mockable: \(instance)") }
            self.instance = instance
        }

        public func function(_ signature: String) -> FunctionTrace {
            trackable._mock_tracker_.function(signature)
        }
    }
}
