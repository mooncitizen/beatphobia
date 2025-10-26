//
//  PermissionManager.swift
//  beatphobia
//
//  Created by Paul Gardiner on 21/10/2025.
//
import AVFoundation

class PermissionManager {
    
    enum PermissionStatus {
        case unknown
        case granted
        case denied
    }
    
    static func checkCameraPermission() async -> PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
            case .authorized:
                return .granted
                
            case .notDetermined:
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                return granted ? .granted : .denied
                
            case .denied, .restricted:
                return .denied
                
            @unknown default:
                return .unknown
        }
    }
}
