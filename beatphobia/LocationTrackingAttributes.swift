//
//  LocationTrackingAttributes.swift
//  beatphobia
//
//  Shared Attributes for Live Activity
//

import Foundation
import ActivityKit

@available(iOS 16.1, *)
struct LocationTrackingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var duration: String
        var distance: String
        var pace: String
        var latitude: Double
        var longitude: Double
        var altitude: Double
        var locationName: String
    }
    
    var startTime: Date
}

