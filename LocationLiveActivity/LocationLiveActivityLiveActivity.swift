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
            // Lock screen/banner UI goes here
            HStack(spacing: 16) {
                Image(systemName: "location.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tracking Journey")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text(context.state.duration)
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "figure.walk")
                                .font(.caption2)
                            Text(context.state.distance)
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "gauge.high")
                                .font(.caption2)
                            Text(context.state.pace)
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .activityBackgroundTint(Color.blue.opacity(0.1))

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
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 20) {
                        HStack(spacing: 6) {
                            Image(systemName: "gauge.high")
                                .font(.caption2)
                            Text(context.state.pace)
                                .font(.subheadline)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                    }
                    .foregroundColor(.secondary)
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
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.blue)
        }
    }
}
