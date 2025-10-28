//
//  LocationLiveActivityLiveActivity.swift
//  LocationLiveActivity
//
//  Created by Paul Gardiner on 28/10/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct LocationLiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LocationTrackingAttributes.self) { context in
            // Lock screen/banner UI goes here - Full width stats layout
            VStack(spacing: 10) {
                // Header
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("Still Step - Tracking Journey")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Stats Row - Spread across full width
                HStack(spacing: 0) {
                    // Duration
                    VStack(spacing: 4) {
                        Text(context.state.duration)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text("duration")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 30)
                    
                    // Distance
                    VStack(spacing: 4) {
                        Text(context.state.distance)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        HStack(spacing: 4) {
                            Image(systemName: "figure.walk")
                                .font(.caption2)
                            Text("distance")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 30)
                }
                
                // Location name
                Text(context.state.locationName)
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.9))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.05))

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Journey")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(context.state.duration)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Distance")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(context.state.distance)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        // Location name
                        Text(context.state.locationName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        // Pace display
                        HStack(spacing: 6) {
                            Image(systemName: "gauge.high")
                                .font(.caption)
                            Text(context.state.pace)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
            } compactTrailing: {
                Text(context.state.duration)
                    .font(.caption2)
                    .fontWeight(.medium)
            } minimal: {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
            }
            .widgetURL(URL(string: "beatphobia://location-tracker"))
            .keylineTint(Color.blue)
        }
    }
}
