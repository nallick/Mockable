//
//  Copyright © 2023 Purgatory Design. Licensed under the MIT License.
//

import Mockable

@Mockable
public protocol MyProtocol {
    var a: Double { get }
    var b: Double { get }

    func foo()
    func foo() -> Int
    func foo(_ p1: Int, p2: Double) -> Double
}
