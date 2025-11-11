//
//  ExposurePlanHelpers.swift
//  beatphobia
//
//  Created for Guided Exposure Plans feature
//

import Foundation
import MapKit
import RealmSwift

func calculatePlanSummary(_ plan: ExposurePlan, useMiles: Bool = false) -> String {
    let targets = plan.targets.filter { !$0.isDeleted }.sorted(by: { $0.orderIndex < $1.orderIndex })
    let targetCount = targets.count
    
    guard targetCount > 0 else {
        return "0 Targets"
    }
    
    // Calculate total distance using straight-line distance (much faster, non-blocking)
    // This is an approximation but avoids blocking the main thread with MKDirections
    var totalDistance: Double = 0.0
    
    if targetCount > 1 {
        // Calculate straight-line distance between consecutive targets
        for i in 0..<(targets.count - 1) {
            let fromLocation = CLLocation(
                latitude: targets[i].latitude,
                longitude: targets[i].longitude
            )
            let toLocation = CLLocation(
                latitude: targets[i + 1].latitude,
                longitude: targets[i + 1].longitude
            )
            totalDistance += fromLocation.distance(from: toLocation)
        }
    }
    
    // Format distance
    let distanceString: String
    if useMiles {
        if totalDistance < 160.934 { // Less than 0.1 miles
            let feet = totalDistance * 3.28084
            distanceString = String(format: "%.0f ft", feet)
        } else {
            let miles = totalDistance / 1609.34
            distanceString = String(format: "%.2f mi", miles)
        }
    } else {
        if totalDistance < 100 {
            distanceString = String(format: "%.0f m", totalDistance)
        } else {
            let km = totalDistance / 1000.0
            distanceString = String(format: "%.2f km", km)
        }
    }
    
    return "\(targetCount) Target\(targetCount == 1 ? "" : "s") • \(distanceString)"
}

func formatWaitTime(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainingSeconds = seconds % 60
    
    if minutes > 0 {
        if remainingSeconds > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        } else {
            return "\(minutes)m"
        }
    } else {
        return "\(remainingSeconds)s"
    }
}

func formatWaitTimeShort(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainingSeconds = seconds % 60
    
    if minutes > 0 {
        return String(format: "%d:%02d", minutes, remainingSeconds)
    } else {
        return String(format: "0:%02d", remainingSeconds)
    }
}

