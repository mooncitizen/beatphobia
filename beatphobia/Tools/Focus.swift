//
//  Focus.swift
//  beatphobia
//
//  Created by Paul Gardiner on 21/10/2025.
//
import SwiftUI
import Combine
import Foundation
@preconcurrency import AVFoundation
import Vision


// MARK: - Object Detection Manager

class ObjectDetectionManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var detectedObjects: [DetectedObject] = []
    @Published var allRecentDetections: [DetectedObject] = [] // Store more for better matching
    @Published var isProcessing = false
    
    private var lastProcessTime: TimeInterval = 0
    private let minimumProcessInterval: TimeInterval = 0.3 // Process faster for more data
    
    struct DetectedObject: Identifiable, Equatable {
        let id = UUID()
        let label: String
        let confidence: Float
        
        static func == (lhs: DetectedObject, rhs: DetectedObject) -> Bool {
            lhs.label == rhs.label && lhs.confidence == rhs.confidence
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Throttle processing
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastProcessTime >= minimumProcessInterval else { return }
        lastProcessTime = currentTime
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Create Vision classification request with better filtering
        let request = VNClassifyImageRequest { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation] else { return }
            
            // Filter out overly technical/abstract terms for better user experience
            let unwantedTerms = ["background", "material", "texture", "pattern", "surface", 
                                   "structure", "design", "style", "arrangement", "composition",
                                   "element", "component", "detail", "feature", "aspect"]
            
            // Get all objects with reasonable confidence
            let allObjects = results
                .filter { result in
                    // Basic confidence filter
                    guard result.confidence > 0.10 else { return false }
                    
                    // Filter out unwanted technical terms
                    let lowerLabel = result.identifier.lowercased()
                    return !unwantedTerms.contains(where: { lowerLabel.contains($0) })
                }
                .prefix(20) // Get more for better matching
                .map { observation -> DetectedObject in
                    // Clean up the label for better readability
                    let cleanLabel = observation.identifier
                        .replacingOccurrences(of: "_", with: " ")
                        .replacingOccurrences(of: "-", with: " ")
                        .capitalized
                    
                    return DetectedObject(
                        label: cleanLabel,
                        confidence: observation.confidence
                    )
                }
            
            // Show only top 3 in UI
            let topThree = Array(allObjects.prefix(3))
            
            DispatchQueue.main.async {
                self?.detectedObjects = topThree
                self?.allRecentDetections = allObjects
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
        
        // Set video rotation angle (iOS 17+)
        if let connection = previewLayer.connection {
            if #available(iOS 17.0, *) {
                connection.videoRotationAngle = 90 // Portrait orientation
            } else {
                // Fallback for earlier versions
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }
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
    @Environment(\.colorScheme) var colorScheme
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
    @State private var availableObjects: Set<String> = [] // Objects Vision has detected
    @State private var recentlySeenObjects: [String: Date] = [:] // Track when objects were last seen
    
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
                        allDetections: objectDetection.allRecentDetections,
                        currentChallenge: $currentChallenge,
                        completedChallenges: $completedChallenges,
                        score: $score,
                        focusTime: focusTime,
                        onNewChallenge: startNewChallenge,
                        onObjectsDetected: updateAvailableObjects
                    )
                } else {
                    // Preparing to start camera
                    FullScreenLoading(text: shouldStartCamera ? "Starting camera..." : "Preparing...")
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
                FullScreenLoading(text: "Initializing Focus Training...")
            }
        }
        .task {
            guard !isInitialized else { return }
            isInitialized = true
            
            // Check camera permission
            self.permissionStatus = await PermissionManager.checkCameraPermission()
        }
        .onChange(of: permissionStatus) { oldValue, newValue in
            // When permission is granted, start the camera
            if newValue == .granted && !shouldStartCamera {
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
            availableObjects = []
            recentlySeenObjects = [:]
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
        
        // Wait for camera to stabilize and start detecting objects
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Start the focus timer (challenge will be set once objects are detected)
        await startTimer()
    }
    
    private func startFocusTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [self] _ in
            if currentChallenge != nil {
                focusTime += 0.1
            }
        }
    }
    
    private func updateAvailableObjects(_ objects: [ObjectDetectionManager.DetectedObject]) {
        // Add newly detected objects to our available pool
        let now = Date()
        for object in objects {
            let cleanLabel = object.label
            availableObjects.insert(cleanLabel)
            recentlySeenObjects[cleanLabel] = now
        }
        
        // Remove objects that haven't been seen in 30 seconds
        let cutoffTime = now.addingTimeInterval(-30)
        recentlySeenObjects = recentlySeenObjects.filter { $0.value > cutoffTime }
        availableObjects = Set(recentlySeenObjects.keys)
        
        // If we don't have a current challenge and we have objects, start one
        if currentChallenge == nil && !availableObjects.isEmpty {
            startNewChallenge()
        }
    }
    
    private func startNewChallenge() {
        // Pick a random object from actually detected objects that hasn't been completed yet
        let unseenObjects = availableObjects.filter { !completedChallenges.contains($0) }
        
        guard let newChallenge = unseenObjects.randomElement() else {
            // If all detected objects have been found, allow repeats or wait for new objects
            if !availableObjects.isEmpty {
                // Reset and use all available objects again
                currentChallenge = availableObjects.randomElement()
            } else {
                // No objects detected yet - show hint
                currentChallenge = nil
            }
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
    let allDetections: [ObjectDetectionManager.DetectedObject]
    @Binding var currentChallenge: String?
    @Binding var completedChallenges: [String]
    @Binding var score: Int
    let focusTime: TimeInterval
    let onNewChallenge: () -> Void
    let onObjectsDetected: ([ObjectDetectionManager.DetectedObject]) -> Void
    
    @State private var showSuccess = false
    @State private var showHint = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack {
                challengeCardView
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                
                Spacer()
                
                centerDetectionArea
                
                Spacer()
                
                detectedObjectsPanel
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }
            
            exitButton
                .padding(.top, 10)
                .padding(.leading, 20)
        }
        .onChange(of: detectedObjects.count) { oldCount, newCount in
            // Update the available objects pool whenever new objects are detected
            if newCount > 0 {
                onObjectsDetected(allDetections) // Pass all detections, not just top 3
            }
        }
        .sheet(isPresented: $showHint) {
            AllDetectionsSheet(allDetections: allDetections, currentChallenge: currentChallenge)
        }
    }
    
    // MARK: - View Components
    
    private var challengeCardView: some View {
        VStack(spacing: 12) {
            if let challenge = currentChallenge {
                challengeContent(challenge: challenge)
                buttonRow
            } else {
                scanningContent
            }
        }
        .padding(20)
        .background(challengeCardBackground)
    }
    
    private func challengeContent(challenge: String) -> some View {
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
            
            scoreDisplay
        }
    }
    
    private var scoreDisplay: some View {
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
    
    private var buttonRow: some View {
        HStack(spacing: 8) {
            hintButton
            skipButton
        }
    }
    
    private var hintButton: some View {
        Button(action: {
            showHint.toggle()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                Text("All Detections")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.yellow.opacity(0.3)))
        }
    }
    
    private var skipButton: some View {
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
            .background(Capsule().fill(Color.white.opacity(0.2)))
        }
    }
    
    private var scanningContent: some View {
        VStack(spacing: 8) {
            Text("Scanning...")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundColor(.white)
            
            Text("Point your camera at objects around you")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 20)
    }
    
    private var challengeCardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.black.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(currentChallenge != nil ? Color.blue : Color.white.opacity(0.3), lineWidth: 2)
            )
    }
    
    private var centerDetectionArea: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                .frame(width: 120, height: 120)
            
            if showSuccess {
                successAnimation
            }
        }
    }
    
    private var successAnimation: some View {
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
    
    private var detectedObjectsPanel: some View {
        VStack(spacing: 12) {
            Text("Top Detected Objects")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            if detectedObjects.isEmpty {
                emptyDetectionState
            } else {
                detectedObjectsList
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.85))
        )
    }
    
    private var emptyDetectionState: some View {
        Text("Point camera at objects...")
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.6))
            .padding(.vertical, 30)
    }
    
    private var detectedObjectsList: some View {
        VStack(spacing: 10) {
            ForEach(detectedObjects) { object in
                DetectedObjectButton(
                    object: object,
                    isTarget: matchesChallenge(object.label)
                ) {
                    checkObject(object.label)
                }
            }
            
            Text("Tap 'All Detections' to see everything the AI sees")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 4)
        }
    }
    
    private var exitButton: some View {
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
    }
    
    // Check if a detected label matches the challenge with flexible matching
    private func matchesChallenge(_ objectLabel: String) -> Bool {
        guard let challenge = currentChallenge else { return false }
        
        let detectedLower = objectLabel.lowercased()
        let challengeLower = challenge.lowercased()
        
        // Flexible matching
        return detectedLower.contains(challengeLower) || 
               challengeLower.contains(detectedLower) ||
               detectedLower.split(separator: " ").contains(where: { challengeLower.contains($0) }) ||
               challengeLower.split(separator: " ").contains(where: { detectedLower.contains($0) })
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
            HStack(spacing: 12) {
                // Icon indicator
                ZStack {
                    Circle()
                        .fill(isTarget ? Color.green.opacity(0.2) : Color.white.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: isTarget ? "target" : "circle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isTarget ? .green : .white.opacity(0.6))
                }
                
                // Label and confidence
                VStack(alignment: .leading, spacing: 2) {
                    Text(object.label)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(isTarget ? .green : .white)
                    
                    Text("Confidence: \(Int(object.confidence * 100))%")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Arrow indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isTarget ? .green : .white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isTarget ? Color.green.opacity(0.15) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isTarget ? Color.green : Color.white.opacity(0.3), lineWidth: isTarget ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - All Detections Sheet

struct AllDetectionsSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    let allDetections: [ObjectDetectionManager.DetectedObject]
    let currentChallenge: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Info banner
                    VStack(spacing: 8) {
                        Text("Everything the AI Sees")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        if let challenge = currentChallenge {
                            Text("Looking for: \(challenge)")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        
                        Text("The AI sees \(allDetections.count) things. Any match will work!")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // All detections
                    detectionsList
                        .padding(.horizontal)
                        .padding(.bottom)
                }
            }
            .background(AppConstants.backgroundColor(for: colorScheme))
            .navigationTitle("All Detections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var detectionsList: some View {
        VStack(spacing: 12) {
            ForEach(Array(allDetections.enumerated()), id: \.element.id) { index, detection in
                DetectionRow(
                    index: index,
                    detection: detection,
                    isMatch: matchesChallenge(detection.label)
                )
            }
        }
    }
    
    private func matchesChallenge(_ objectLabel: String) -> Bool {
        guard let challenge = currentChallenge else { return false }
        
        let detectedLower = objectLabel.lowercased()
        let challengeLower = challenge.lowercased()
        
        // Flexible matching
        return detectedLower.contains(challengeLower) || 
               challengeLower.contains(detectedLower) ||
               detectedLower.split(separator: " ").contains(where: { challengeLower.contains($0) }) ||
               challengeLower.split(separator: " ").contains(where: { detectedLower.contains($0) })
    }
}

// MARK: - Detection Row

struct DetectionRow: View {
    let index: Int
    let detection: ObjectDetectionManager.DetectedObject
    let isMatch: Bool
    
    var body: some View {
        HStack {
            Text("\(index + 1).")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(detection.label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("\(Int(detection.confidence * 100))% confident")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isMatch {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20))
            }
        }
        .padding()
        .background(rowBackground)
    }
    
    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(isMatch ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
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
