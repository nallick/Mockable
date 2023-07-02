//
//  MockTrackable.swift
//
//  Copyright © 2023 Purgatory Design. Licensed under the MIT License.
//

public protocol MockTrackable: AnyObject {
    var _mock_tracker_: Mock.Tracker { get set }
}
