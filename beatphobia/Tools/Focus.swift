//
//  Focus.swift
//  beatphobia
//
//  Created by Paul Gardiner on 21/10/2025.
//
import SwiftUI
import Combine
import Foundation
import AVFoundation
import Vision


// MARK: - Object Detection Manager

class ObjectDetectionManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var detectedObjects: [DetectedObject] = []
    @Published var isProcessing = false
    
    private var lastProcessTime: TimeInterval = 0
    private let minimumProcessInterval: TimeInterval = 0.5 // Process every 0.5 seconds
    
    struct DetectedObject: Identifiable {
        let id = UUID()
        let label: String
        let confidence: Float
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Throttle processing
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastProcessTime >= minimumProcessInterval else { return }
        lastProcessTime = currentTime
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Create Vision classification request
        let request = VNClassifyImageRequest { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation] else { return }
            
            // Get top objects with reasonable confidence
            let objects = results
                .filter { $0.confidence > 0.1 && $0.identifier != "background" }
                .prefix(10)
                .map { observation -> DetectedObject in
                    // Clean up the label for better readability
                    let cleanLabel = observation.identifier
                        .replacingOccurrences(of: "_", with: " ")
                        .capitalized
                    
                    return DetectedObject(
                        label: cleanLabel,
                        confidence: observation.confidence
                    )
                }
            
            DispatchQueue.main.async {
                self?.detectedObjects = objects
            }
        }
        
        // Perform request
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
}

// MARK: - Camera Manager

class CameraManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var isSessionConfigured = false
    
    let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.beatphobia.camera.session", qos: .userInitiated)
    private let videoOutputQueue = DispatchQueue(label: "com.beatphobia.video.output", qos: .utility)
    
    var videoOutput: AVCaptureVideoDataOutput?
    
    override init() {
        super.init()
    }
    
    func setupCamera(with delegate: AVCaptureVideoDataOutputSampleBufferDelegate? = nil) async {
        // Always use the same camera permission as the main permission check
        isAuthorized = true
        await configureCaptureSession(with: delegate)
    }
    
    private func configureCaptureSession(with delegate: AVCaptureVideoDataOutputSampleBufferDelegate?) async {
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                self.captureSession.beginConfiguration()
                
                // Remove any existing inputs/outputs
                for input in self.captureSession.inputs {
                    self.captureSession.removeInput(input)
                }
                for output in self.captureSession.outputs {
                    self.captureSession.removeOutput(output)
                }
                
                // Use medium preset for good quality object detection
                self.captureSession.sessionPreset = .medium
                
                // Add back camera input
                guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                    self.captureSession.commitConfiguration()
                    continuation.resume()
                    return
                }
                
                do {
                    let input = try AVCaptureDeviceInput(device: backCamera)
                    
                    if self.captureSession.canAddInput(input) {
                        self.captureSession.addInput(input)
                        
                        // Add video output for object detection
                        if let delegate = delegate {
                            let output = AVCaptureVideoDataOutput()
                            output.videoSettings = [
                                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                            ]
                            output.alwaysDiscardsLateVideoFrames = true
                            output.setSampleBufferDelegate(delegate, queue: self.videoOutputQueue)
                            
                            if self.captureSession.canAddOutput(output) {
                                self.captureSession.addOutput(output)
                                self.videoOutput = output
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self.isSessionConfigured = true
                        }
                    }
                } catch {
                    print("❌ Camera error: \(error.localizedDescription)")
                }
                
                self.captureSession.commitConfiguration()
                continuation.resume()
            }
        }
    }
    
    func startSession() {
        guard isSessionConfigured else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }
}

// MARK: - Camera Preview

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewView {
        CameraPreviewView(session: session)
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        // Minimal updates - frame is handled by Auto Layout
    }
}

class CameraPreviewView: UIView {
    private let captureSession: AVCaptureSession
    
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
    
    init(session: AVCaptureSession) {
        self.captureSession = session
        super.init(frame: .zero)
        
        backgroundColor = .black
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        
        // Set video orientation
        if let connection = previewLayer.connection,
           connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Frame is automatically handled by AVCaptureVideoPreviewLayer
    }
}

// MARK: - Focus View

struct FocusView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var objectDetection = ObjectDetectionManager()
    @State private var permissionStatus: PermissionManager.PermissionStatus = .unknown
    @State private var focusTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var shouldStartCamera = false
    @State private var isInitialized = false
    @State private var currentChallenge: String?
    @State private var completedChallenges: [String] = []
    @State private var score: Int = 0
    
    // Objects based on what Apple Vision commonly detects
    let possibleObjects = [
        // Furniture (Vision can detect these)
        "Chair", "Table", "Desk", "Sofa", "Bed", "Bench", "Cabinet",
        
        // Electronics (commonly detected)
        "Laptop", "Monitor", "Keyboard", "Mouse", "Phone", "Television",
        "Remote Control", "Speaker", "Headphones", "Camera",
        
        // Kitchen Items (well-recognized)
        "Bottle", "Cup", "Plate", "Bowl", "Knife", "Microwave", "Refrigerator",
        
        // Personal Items (commonly detected)
        "Bag", "Backpack", "Shoe", "Watch", "Sunglasses", "Hat",
        
        // Office/Study (good detection)
        "Book", "Notebook", "Pen", "Scissors", "Paper",
        
        // Room Features
        "Door", "Window", "Mirror", "Clock", "Lamp", "Pillow",
        
        // Decorative
        "Plant", "Flower", "Vase",
        
        // Containers
        "Box", "Basket", "Jar",
        
        // Other
        "Toy", "Ball", "Towel", "Blanket"
    ]
    
    var body: some View {
        ZStack {
            if permissionStatus == .granted {
                if shouldStartCamera && cameraManager.isSessionConfigured {
                    // Camera Preview (full screen)
                    CameraPreview(session: cameraManager.captureSession)
                        .ignoresSafeArea()
                        .edgesIgnoringSafeArea(.all)
                    
                    // Object Detection Game Overlay
                    ObjectDetectionGameView(
                        detectedObjects: objectDetection.detectedObjects,
                        currentChallenge: $currentChallenge,
                        completedChallenges: $completedChallenges,
                        score: $score,
                        focusTime: focusTime,
                        onNewChallenge: startNewChallenge
                    )
                } else {
                    // Preparing to start camera
                    ZStack {
                        Color.black.ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            
                            Text(shouldStartCamera ? "Starting camera..." : "Preparing...")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                }
                
            } else if permissionStatus == .denied {
                // Permission denied
                ErrorStateView(
                    icon: "camera.fill",
                    title: "Camera Access Required",
                    message: "Please enable camera access to use Focus Training.",
                    actionTitle: "Open Settings",
                    action: openAppSettings
                )
            } else {
                // Loading
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text("Initializing Focus Training...")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
        }
        .task {
            guard !isInitialized else { return }
            isInitialized = true
            
            // Check camera permission
            self.permissionStatus = await PermissionManager.checkCameraPermission()
        }
        .onAppear {
            // Delay camera start until after view animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard permissionStatus == .granted, !shouldStartCamera else { return }
                
                // Signal to start camera
                shouldStartCamera = true
                
                // Initialize camera on background thread
                let camManager = cameraManager
                let detector = objectDetection
                
                Task.detached(priority: .userInitiated) {
                    await Self.initializeCamera(
                        cameraManager: camManager,
                        objectDetection: detector,
                        startTimer: {
                            await MainActor.run {
                                self.startFocusTimer()
                                self.startNewChallenge()
                            }
                        }
                    )
                }
            }
        }
        .onDisappear {
            stopFocusTimer()
            
            if permissionStatus == .granted {
                cameraManager.stopSession()
            }
            
            // Reset state for next time
            shouldStartCamera = false
            currentChallenge = nil
            completedChallenges = []
            score = 0
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationBarHidden(true)
    }
    
    private static func initializeCamera(
        cameraManager: CameraManager?,
        objectDetection: ObjectDetectionManager?,
        startTimer: @escaping () async -> Void
    ) async {
        guard let cameraManager = cameraManager else { return }
        
        // Setup back camera with object detection
        await cameraManager.setupCamera(with: objectDetection)
        
        // Start camera session
        await MainActor.run {
            cameraManager.startSession()
        }
        
        // Wait for camera to stabilize
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Start the focus timer
        await startTimer()
    }
    
    private func startFocusTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [self] _ in
            if currentChallenge != nil {
                focusTime += 0.1
            }
        }
    }
    
    private func startNewChallenge() {
        // Pick a random object that hasn't been completed yet
        let availableObjects = possibleObjects.filter { !completedChallenges.contains($0) }
        guard let newChallenge = availableObjects.randomElement() else {
            // All challenges completed!
            currentChallenge = nil
            return
        }
        currentChallenge = newChallenge
    }
    
    private func stopFocusTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else {
            return
        }
        UIApplication.shared.open(url)
    }
}

// MARK: - Object Detection Game View

struct ObjectDetectionGameView: View {
    let detectedObjects: [ObjectDetectionManager.DetectedObject]
    @Binding var currentChallenge: String?
    @Binding var completedChallenges: [String]
    @Binding var score: Int
    let focusTime: TimeInterval
    let onNewChallenge: () -> Void
    
    @State private var showSuccess = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack {
                // Top challenge card
                if let challenge = currentChallenge {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Find:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text(challenge)
                                    .font(.system(size: 28, weight: .bold, design: .serif))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 14))
                                    Text("\(score)")
                                        .font(.system(size: 18, weight: .bold))
                                }
                                .foregroundColor(.yellow)
                                
                                Text("\(completedChallenges.count) found")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        
                        // Skip button
                        Button(action: {
                            onNewChallenge()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 12))
                                Text("Skip")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                            )
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                }
                
                Spacer()
                
                // Center detection area
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        .frame(width: 120, height: 120)
                    
                    if showSuccess {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.3))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                Spacer()
                
                // Bottom detected objects panel
                VStack(spacing: 16) {
                    Text("Detected Objects")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    if detectedObjects.isEmpty {
                        Text("Point camera at objects...")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.vertical, 20)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(detectedObjects) { object in
                                    DetectedObjectButton(
                                        object: object,
                                        isTarget: object.label.lowercased() == currentChallenge?.lowercased()
                                    ) {
                                        checkObject(object.label)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.8))
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            
            // Exit button (top left - above the card)
            Button(action: {
                dismiss()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.7))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 10)
            .padding(.leading, 20)
        }
    }
    
    private func checkObject(_ objectLabel: String) {
        guard let challenge = currentChallenge else { return }
        
        // Flexible matching - check if labels are similar
        let detectedLower = objectLabel.lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
        let challengeLower = challenge.lowercased()
        
        // Check for matches
        let isMatch = detectedLower.contains(challengeLower) || 
                     challengeLower.contains(detectedLower) ||
                     detectedLower.split(separator: " ").contains(where: { challengeLower.contains($0) }) ||
                     challengeLower.split(separator: " ").contains(where: { detectedLower.contains($0) })
        
        if isMatch {
            // Correct!
            withAnimation(.spring(response: 0.5)) {
                showSuccess = true
                score += 10
                completedChallenges.append(challenge)
            }
            
            // Show success animation then move to next
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    showSuccess = false
                }
                onNewChallenge()
            }
        }
    }
}

struct DetectedObjectButton: View {
    let object: ObjectDetectionManager.DetectedObject
    let isTarget: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(object.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isTarget ? .green : .white)
                
                Text("\(Int(object.confidence * 100))%")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isTarget ? Color.green.opacity(0.2) : Color.white.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isTarget ? Color.green : Color.white.opacity(0.3), lineWidth: 1.5)
                    )
            )
        }
    }
}

// MARK: - Error State View

struct ErrorStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.red.opacity(0.8))
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(Color.blue)
                        )
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - Preview

#Preview {
    FocusView()
}
