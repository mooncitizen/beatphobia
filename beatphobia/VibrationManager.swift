//
//  VibrationManger.swift
//  beatphobia
//
//  Created by Paul Gardiner on 21/10/2025.
//

import Foundation
import CoreHaptics
import UIKit
import Observation

@Observable
@MainActor
class VibrationManager {
    
    private var engine: CHHapticEngine?
    private var heartbeatPlayer: CHHapticAdvancedPatternPlayer?
    
    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("Haptics not supported on this device")
            return
        }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            engine?.playsHapticsOnly = true
            
            engine?.resetHandler = { [weak self] in
                print("Haptic engine reset")
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    do {
                        try self.engine?.start()
                        self.createHeartbeatPlayer()
                    } catch {
                        print("Failed to restart haptic engine: \(error)")
                    }
                }
            }
            
            createHeartbeatPlayer()
        } catch {
            print("Failed to start haptic engine: \(error)")
        }
    }
    
    deinit {
        print("Vibration manager deinit")
    }
    
    private func createHeartbeatPlayer() {
        guard let engine = self.engine else { return }
        
        self.engine?.playsHapticsOnly = true
        
        var events: [CHHapticEvent] = []
        
        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let thump1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensityParam, sharpnessParam], relativeTime: 0.0)
        
        let intensityParam2 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
        let sharpnessParam2 = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
        let thump2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensityParam2, sharpnessParam2], relativeTime: 0.15)
        
        let loopEnd = CHHapticEvent(eventType: .hapticContinuous, parameters: [], relativeTime: 1.0, duration: 0.0)
        
        events.append(thump1)
        events.append(thump2)
        events.append(loopEnd)
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            heartbeatPlayer = try engine.makeAdvancedPlayer(with: pattern)
            heartbeatPlayer?.loopEnabled = true
        } catch {
            print("Failed to create heartbeat player: \(error)")
        }
    }
    
    func checkCapabilities() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("Haptics not supported on this device")
            return
        }
    }
    
    func startHeartbeat() {
        
        checkCapabilities()
        
        guard let player = heartbeatPlayer else {
            print("Heartbeat player not ready")
            return
        }
        
        do {
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to start heartbeat player: \(error)")
        }
    }
    
    func stopHeartbeat() {
        guard let player = heartbeatPlayer else { return }
        
        do {
            try player.stop(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to stop heartbeat player: \(error)")
        }
    }
    
    func shutdown() {
        print("Shutting down haptic engine.")
        stopHeartbeat()
        engine?.stop()
    }
}
