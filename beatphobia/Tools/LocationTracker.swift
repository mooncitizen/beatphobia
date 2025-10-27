//
//  LocationTracker.swift
//  beatphobia
//
//  Created by Paul Gardiner on 22/10/2025.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine
import RealmSwift

struct LocationTrackerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var locationManager = LocationTrackingManager()
    @State private var showMap = false // Hide map by default
    @Binding var isTabBarVisible: Bool
    @AppStorage("setting.miles") private var enableMiles = false
    @State private var showEndJourneyAlert = false
    @State private var showJourneyResults = false
    @State private var completedJourneyId: String?
    
    var body: some View {
        ZStack {
            // Background color
            AppConstants.defaultBackgroundColor
                .ignoresSafeArea()
            
            // Map view (only when enabled)
            if showMap {
                MapView(locationManager: locationManager)
                    .ignoresSafeArea()
            }
            
            // Overlay UI
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Info view (when not tracking) - scrollable
                if !locationManager.isTracking {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            infoView
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                        }
                    }
                }
                
                // Stats view (when not showing map)
                if !showMap && locationManager.isTracking {
                    Spacer()
                    statsView
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
                
                // Spacer when in map view to push controls down
                if showMap && locationManager.isTracking {
                    Spacer()
                }
                
                // Feeling selector (when tracking)
                if locationManager.isTracking {
                    feelingSelector
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                }
                
                // Bottom controls
                controlsView
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .alert("End Journey?", isPresented: $showEndJourneyAlert) {
            Button("Cancel", role: .cancel) { }
            Button("End Journey", role: .destructive) {
                completedJourneyId = locationManager.currentJourneyId?.uuidString
                locationManager.stopTracking()
                showJourneyResults = true
            }
        } message: {
            Text("Are you sure you want to end this tracking session?")
        }
        .fullScreenCover(isPresented: $showJourneyResults) {
            if let journeyId = completedJourneyId,
               let realm = try? Realm(),
               let journey = realm.object(ofType: JourneyRealm.self, forPrimaryKey: journeyId) {
                NavigationView {
                    JourneyDetailView(journey: journey)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showJourneyResults = false
                                    // Restore tab bar visibility
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isTabBarVisible = true
                                    }
                                    dismiss()
                                }
                            }
                        }
                }
            }
        }
        .onAppear {
            locationManager.requestPermission()
            locationManager.useMiles = enableMiles
            // Hide tab bar when view appears
            withAnimation(.easeInOut(duration: 0.2)) {
                isTabBarVisible = false
            }
        }
        .onChange(of: enableMiles) { oldValue, newValue in
            locationManager.useMiles = newValue
            locationManager.updateDistanceDisplay()
        }
        .onDisappear {
            // Only stop tracking if not actively tracking
            // This ensures tracking continues even when phone sleeps
            if !locationManager.isTracking {
                // Show tab bar when view disappears
                withAnimation(.easeInOut(duration: 0.2)) {
                    isTabBarVisible = true
                }
            }
        }
        .interactiveDismissDisabled(locationManager.isTracking) // Prevent swipe-to-dismiss while tracking
    }
    
    // MARK: - Info View
    private var infoView: some View {
        VStack(spacing: 20) {
            // Main title and description
            VStack(spacing: 12) {
                Image(systemName: "map.circle.fill")
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.blue.opacity(0.3), radius: 10, y: 5)
                
                Text("Tracker")
                    .font(.system(size: 26, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(.black)
                
                Text("Track your movements and emotions")
                    .font(.system(size: 15))
                    .fontDesign(.serif)
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 4)
            
            // Features cards
            VStack(spacing: 10) {
                featureCard(
                    icon: "location.fill",
                    title: "Real-time Tracking",
                    description: "See your path on an interactive map as you move"
                )
                
                featureCard(
                    icon: "heart.text.square.fill",
                    title: "Emotion Checkpoints",
                    description: "Log how you're feeling at different points"
                )
                
                featureCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Track Your Progress",
                    description: "View distance, time, and pace statistics"
                )
                
                featureCard(
                    icon: "map.fill",
                    title: "Toggle View",
                    description: "Switch between map and stats using the button in the top right"
                )
            }
            
            // Privacy note
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                
                Text("Your location data is stored securely on your device")
                    .font(.system(size: 12))
                    .fontDesign(.serif)
                    .foregroundColor(.black.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            .padding(.bottom, 8)
        }
    }
    
    private func featureCard(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .fontDesign(.serif)
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.system(size: 12))
                    .fontDesign(.serif)
                    .foregroundColor(.black.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, y: 3)
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            // Only show close button when NOT tracking
            if !locationManager.isTracking {
                Button(action: {
                    if locationManager.hapticsEnabled {
                        locationManager.lightHaptic.impactOccurred(intensity: 0.5)
                    }
                    dismiss()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.black.opacity(0.2), radius: 10, y: 3)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppConstants.primaryColor)
                    }
                }
            }
            
            Spacer()
            
            // View toggle button - only show when tracking
            if locationManager.isTracking {
                Button(action: {
                    if locationManager.hapticsEnabled {
                        locationManager.lightHaptic.impactOccurred(intensity: 0.5)
                    }
                    withAnimation(.spring(response: 0.3)) {
                        showMap.toggle()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.black.opacity(0.2), radius: 10, y: 3)
                        
                        Image(systemName: showMap ? "chart.bar.fill" : "map.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppConstants.primaryColor)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Stats View
    private var statsView: some View {
        VStack(spacing: 16) {
            // Time and Distance Row
            HStack(spacing: 12) {
                statCard(
                    title: "Time",
                    value: locationManager.trackingDuration,
                    icon: "clock.fill",
                    color: AppConstants.primaryColor
                )
                
                statCard(
                    title: "Distance",
                    value: locationManager.totalDistance,
                    icon: "figure.walk",
                    color: .green
                )
            }
            
            // Pace and Emotions Row
            HStack(spacing: 12) {
                statCard(
                    title: enableMiles ? "Pace (min/mi)" : "Pace (min/km)",
                    value: locationManager.averagePace,
                    icon: "gauge.high",
                    color: .orange
                )
                
                statCard(
                    title: "Checkpoints",
                    value: "\(locationManager.feelingCheckpoints.count)",
                    icon: "heart.fill",
                    color: .pink
                )
            }
            
            // Recent emotions
            if !locationManager.feelingCheckpoints.isEmpty {
                recentEmotionsView
            }
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.black.opacity(0.6))
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .fontDesign(.monospaced)
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, y: 3)
    }
    
    private var recentEmotionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Emotions")
                .font(.system(size: 14, weight: .semibold))
                .fontDesign(.serif)
                .foregroundColor(.black.opacity(0.7))
            
            HStack(spacing: 8) {
                ForEach(locationManager.feelingCheckpoints.suffix(5).reversed(), id: \.id) { checkpoint in
                    emotionBadge(checkpoint: checkpoint)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, y: 3)
    }
    
    private func emotionBadge(checkpoint: FeelingCheckpoint) -> some View {
        VStack(spacing: 4) {
            Image(systemName: checkpoint.feeling.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(checkpoint.feeling.color)
                .frame(width: 44, height: 44)
                .background(checkpoint.feeling.color.opacity(0.15))
                .cornerRadius(12)
            
            Text(checkpoint.timestamp.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.black.opacity(0.5))
        }
    }
    
    // MARK: - Feeling Selector
    private var feelingSelector: some View {
        VStack(spacing: showMap ? 8 : 12) {
            Text("How are you feeling?")
                .font(.system(size: showMap ? 12 : 14, weight: .semibold))
                .fontDesign(.serif)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.6))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.2), radius: 8, y: 3)
            
            HStack(spacing: showMap ? 8 : 12) {
                ForEach(FeelingLevel.allCases, id: \.self) { feeling in
                    feelingButton(feeling: feeling)
                }
            }
        }
    }
    
    private func feelingButton(feeling: FeelingLevel) -> some View {
        Button(action: {
            locationManager.recordFeeling(feeling)
        }) {
            if showMap {
                // Compact version for map view
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(feeling.color.opacity(0.9))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: feeling.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.black.opacity(0.3), radius: 4, y: 2)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: locationManager.currentFeeling == feeling ? 3 : 0)
                    )
                }
            } else {
                // Full version for stats view
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(feeling.color.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: feeling.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(feeling.color)
                    }
                    
                    Text(feeling.title)
                        .font(.system(size: 11, weight: .semibold))
                        .fontDesign(.serif)
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    locationManager.currentFeeling == feeling ?
                    feeling.color.opacity(0.25) : Color.white
                )
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.15), radius: 8, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(feeling.color, lineWidth: locationManager.currentFeeling == feeling ? 3 : 0)
                )
            }
        }
    }
    
    // MARK: - Controls
    private var controlsView: some View {
        VStack(spacing: 12) {
            if !locationManager.isTracking {
                // Start tracking button
                Button(action: {
                    locationManager.startTracking()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text("Start Tracking")
                            .font(.system(size: 18, weight: .semibold))
                            .fontDesign(.serif)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(28)
                    .shadow(color: Color.green.opacity(0.3), radius: 10, y: 5)
                }
            } else {
                // Stop tracking button
                Button(action: {
                    showEndJourneyAlert = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: showMap ? 16 : 20, weight: .semibold))
                        
                        Text("End Journey")
                            .font(.system(size: showMap ? 15 : 18, weight: .semibold))
                            .fontDesign(.serif)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: showMap ? 44 : 56)
                    .background(
                        LinearGradient(
                            colors: [Color.red.opacity(showMap ? 0.85 : 1.0), Color.red.opacity(showMap ? 0.7 : 0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(showMap ? 22 : 28)
                    .shadow(color: Color.red.opacity(showMap ? 0.4 : 0.3), radius: showMap ? 6 : 10, y: showMap ? 3 : 5)
                }
            }
        }
    }
}

// MARK: - Map View
struct MapView: UIViewRepresentable {
    @ObservedObject var locationManager: LocationTrackingManager
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update polyline only if tracking
        if locationManager.isTracking {
            // Only update if we have new points
            if locationManager.trackingPoints.count > 1 {
                let coordinates = locationManager.trackingPoints.map { $0.coordinate }
                
                // Check if we need to update the polyline
                let existingPolylines = mapView.overlays.compactMap { $0 as? MKPolyline }
                let needsUpdate = existingPolylines.isEmpty || existingPolylines.first?.pointCount != coordinates.count
                
                if needsUpdate {
                    // Remove only polylines, keep everything else
                    mapView.removeOverlays(existingPolylines)
                    
                    // Add new polyline
                    let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                    mapView.addOverlay(polyline)
                }
            }
            
            // Update feeling checkpoint annotations (only if count changed)
            let existingFeelingAnnotations = mapView.annotations.compactMap { $0 as? FeelingAnnotation }
            if existingFeelingAnnotations.count != locationManager.feelingCheckpoints.count {
                // Remove old feeling annotations
                mapView.removeAnnotations(existingFeelingAnnotations)
                
                // Add new feeling annotations
                for checkpoint in locationManager.feelingCheckpoints {
                    let annotation = FeelingAnnotation(checkpoint: checkpoint)
                    mapView.addAnnotation(annotation)
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }
            
            // Handle feeling checkpoint annotations
            if let feelingAnnotation = annotation as? FeelingAnnotation {
                let identifier = "FeelingAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                
                // Create custom pin with feeling color
                let pinSize: CGFloat = 30
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: pinSize, height: pinSize))
                let pinImage = renderer.image { context in
                    feelingAnnotation.checkpoint.feeling.uiColor.setFill()
                    let circle = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: pinSize, height: pinSize))
                    circle.fill()
                    
                    UIColor.white.setStroke()
                    circle.lineWidth = 3
                    circle.stroke()
                }
                
                annotationView?.image = pinImage
                return annotationView
            }
            
            return nil
        }
    }
}

// MARK: - Location Tracking Manager
class LocationTrackingManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isTracking = false
    @Published var trackingPoints: [CLLocation] = []
    @Published var feelingCheckpoints: [FeelingCheckpoint] = []
    @Published var currentFeeling: FeelingLevel?
    @Published var showStats = false
    @Published var hapticsEnabled = true
    @Published var trackingDuration: String = "00:00"
    @Published var totalDistance: String = "0.0 km"
    @Published var averagePace: String = "0:00"
    @Published var permissionStatus: CLAuthorizationStatus = .notDetermined
    
    var useMiles: Bool = false // Set from view based on user preference
    
    private let locationManager = CLLocationManager()
    private var startTime: Date?
    private var timer: Timer?
    private var saveTimer: Timer?
    private var distanceMeters: Double = 0
    var currentJourneyId: UUID? // Made public to access after journey ends
    
    let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    let successHaptic = UINotificationFeedbackGenerator()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
        lightHaptic.prepare()
        mediumHaptic.prepare()
        successHaptic.prepare()
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
    }
    
    func startTracking() {
        if hapticsEnabled {
            mediumHaptic.impactOccurred(intensity: 0.8)
        }
        
        isTracking = true
        trackingPoints = []
        feelingCheckpoints = []
        distanceMeters = 0
        totalDistance = useMiles ? "0.0 mi" : "0.0 km"
        averagePace = "0:00"
        startTime = Date()
        currentJourneyId = UUID()
        
        // Create initial journey in Realm
        saveJourneyToRealm()
        
        locationManager.startUpdatingLocation()
        
        // Start timer for duration
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateDuration()
        }
        
        // Start timer for saving to Realm every 5 seconds
        saveTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.saveJourneyToRealm()
        }
    }
    
    func stopTracking() {
        if hapticsEnabled {
            successHaptic.notificationOccurred(.success)
        }
        
        isTracking = false
        locationManager.stopUpdatingLocation()
        timer?.invalidate()
        timer = nil
        saveTimer?.invalidate()
        saveTimer = nil
        
        // Save final state to Realm
        saveJourneyToRealm()
    }
    
    func recordFeeling(_ feeling: FeelingLevel) {
        guard let location = trackingPoints.last else { return }
        
        if hapticsEnabled {
            lightHaptic.impactOccurred(intensity: 0.6)
        }
        
        let checkpoint = FeelingCheckpoint(
            id: UUID(),
            location: location,
            feeling: feeling,
            timestamp: Date()
        )
        
        feelingCheckpoints.append(checkpoint)
        currentFeeling = feeling
    }
    
    private func updateDuration() {
        guard let startTime = startTime else { return }
        let elapsed = Int(Date().timeIntervalSince(startTime))
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        trackingDuration = String(format: "%02d:%02d", minutes, seconds)
        
        // Calculate pace (min/km or min/mi)
        if distanceMeters > 0 && elapsed > 0 {
            let distance = useMiles ? (distanceMeters / 1609.34) : (distanceMeters / 1000.0) // miles or km
            let paceMinPerUnit = Double(elapsed) / 60.0 / distance
            let paceMin = Int(paceMinPerUnit)
            let paceSec = Int((paceMinPerUnit - Double(paceMin)) * 60)
            averagePace = String(format: "%d:%02d", paceMin, paceSec)
        }
    }
    
    private func calculateDistance() {
        guard trackingPoints.count > 1 else { return }
        
        var totalDist: Double = 0
        for i in 1..<trackingPoints.count {
            let dist = trackingPoints[i].distance(from: trackingPoints[i-1])
            totalDist += dist
        }
        
        distanceMeters = totalDist
        
        if useMiles {
            let miles = distanceMeters / 1609.34
            totalDistance = String(format: "%.2f mi", miles)
        } else {
            let kilometers = distanceMeters / 1000.0
            totalDistance = String(format: "%.2f km", kilometers)
        }
    }
    
    // Public method to update distance display when unit preference changes
    func updateDistanceDisplay() {
        if useMiles {
            let miles = distanceMeters / 1609.34
            totalDistance = String(format: "%.2f mi", miles)
        } else {
            let kilometers = distanceMeters / 1000.0
            totalDistance = String(format: "%.2f km", kilometers)
        }
        
        // Also update pace
        if let startTime = startTime {
            let elapsed = Int(Date().timeIntervalSince(startTime))
            if distanceMeters > 0 && elapsed > 0 {
                let distance = useMiles ? (distanceMeters / 1609.34) : (distanceMeters / 1000.0)
                let paceMinPerUnit = Double(elapsed) / 60.0 / distance
                let paceMin = Int(paceMinPerUnit)
                let paceSec = Int((paceMinPerUnit - Double(paceMin)) * 60)
                averagePace = String(format: "%d:%02d", paceMin, paceSec)
            }
        }
    }
    
    private func saveJourneyToRealm() {
        guard let journeyId = currentJourneyId else { return }
        
        let realm = try? Realm()
        try? realm?.write {
            // Check if journey exists
            if let existingJourney = realm?.object(ofType: JourneyRealm.self, forPrimaryKey: journeyId.uuidString) {
                // Update existing journey
                existingJourney.endTime = Date()
                existingJourney.distance = distanceMeters
                existingJourney.duration = Int(Date().timeIntervalSince(startTime ?? Date()))
                
                // Clear and re-add path points
                existingJourney.pathPoints.removeAll()
                for location in trackingPoints {
                    let pathPoint = PathPointRealm()
                    pathPoint.latitude = location.coordinate.latitude
                    pathPoint.longitude = location.coordinate.longitude
                    pathPoint.timestamp = location.timestamp
                    existingJourney.pathPoints.append(pathPoint)
                }
                
                // Clear and re-add checkpoints
                existingJourney.checkpoints.removeAll()
                for checkpoint in feelingCheckpoints {
                    let realmCheckpoint = FeelingCheckpointRealm()
                    realmCheckpoint.id = checkpoint.id.uuidString
                    realmCheckpoint.latitude = checkpoint.location.coordinate.latitude
                    realmCheckpoint.longitude = checkpoint.location.coordinate.longitude
                    realmCheckpoint.feeling = checkpoint.feeling.rawValue
                    realmCheckpoint.timestamp = checkpoint.timestamp
                    existingJourney.checkpoints.append(realmCheckpoint)
                }
            } else {
                // Create new journey
                let journey = JourneyRealm()
                journey.id = journeyId.uuidString
                journey.startTime = startTime ?? Date()
                journey.endTime = Date()
                journey.distance = distanceMeters
                journey.duration = Int(Date().timeIntervalSince(startTime ?? Date()))
                
                // Add path points
                for location in trackingPoints {
                    let pathPoint = PathPointRealm()
                    pathPoint.latitude = location.coordinate.latitude
                    pathPoint.longitude = location.coordinate.longitude
                    pathPoint.timestamp = location.timestamp
                    journey.pathPoints.append(pathPoint)
                }
                
                // Add checkpoints
                for checkpoint in feelingCheckpoints {
                    let realmCheckpoint = FeelingCheckpointRealm()
                    realmCheckpoint.id = checkpoint.id.uuidString
                    realmCheckpoint.latitude = checkpoint.location.coordinate.latitude
                    realmCheckpoint.longitude = checkpoint.location.coordinate.longitude
                    realmCheckpoint.feeling = checkpoint.feeling.rawValue
                    realmCheckpoint.timestamp = checkpoint.timestamp
                    journey.checkpoints.append(realmCheckpoint)
                }
                
                realm?.add(journey)
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTracking else { return }
        
        for location in locations {
            if location.horizontalAccuracy < 50 { // Only add accurate locations
                trackingPoints.append(location)
                calculateDistance()
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        permissionStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

// MARK: - Models
enum FeelingLevel: String, CaseIterable {
    case great = "Great"
    case good = "Good"
    case okay = "Okay"
    case anxious = "Anxious"
    case panic = "Panic"
    
    var icon: String {
        switch self {
        case .great: return "face.smiling.fill"
        case .good: return "face.smiling"
        case .okay: return "minus.circle.fill"
        case .anxious: return "exclamationmark.triangle.fill"
        case .panic: return "exclamationmark.octagon.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .great: return .green
        case .good: return .blue
        case .okay: return .yellow
        case .anxious: return .orange
        case .panic: return .red
        }
    }
    
    var uiColor: UIColor {
        switch self {
        case .great: return .systemGreen
        case .good: return .systemBlue
        case .okay: return .systemYellow
        case .anxious: return .systemOrange
        case .panic: return .systemRed
        }
    }
    
    var title: String {
        return rawValue
    }
}

struct FeelingCheckpoint: Identifiable {
    let id: UUID
    let location: CLLocation
    let feeling: FeelingLevel
    let timestamp: Date
    
    var coordinate: CLLocationCoordinate2D {
        location.coordinate
    }
}

class FeelingAnnotation: NSObject, MKAnnotation {
    let checkpoint: FeelingCheckpoint
    
    var coordinate: CLLocationCoordinate2D {
        checkpoint.coordinate
    }
    
    var title: String? {
        checkpoint.feeling.title
    }
    
    var subtitle: String? {
        checkpoint.timestamp.formatted(date: .omitted, time: .shortened)
    }
    
    init(checkpoint: FeelingCheckpoint) {
        self.checkpoint = checkpoint
    }
}

// MARK: - Realm Models
class JourneyRealm: Object {
    @Persisted(primaryKey: true) var id: String = ""
    @Persisted var startTime: Date = Date()
    @Persisted var endTime: Date = Date()
    @Persisted var distance: Double = 0.0 // in meters
    @Persisted var duration: Int = 0 // in seconds
    @Persisted var pathPoints = RealmSwift.List<PathPointRealm>()
    @Persisted var checkpoints = RealmSwift.List<FeelingCheckpointRealm>()
}

class PathPointRealm: Object {
    @Persisted var latitude: Double = 0.0
    @Persisted var longitude: Double = 0.0
    @Persisted var timestamp: Date = Date()
}

class FeelingCheckpointRealm: Object {
    @Persisted var id: String = ""
    @Persisted var latitude: Double = 0.0
    @Persisted var longitude: Double = 0.0
    @Persisted var feeling: String = ""
    @Persisted var timestamp: Date = Date()
}

// MARK: - Preview
#Preview {
    @Previewable @State var isTabBarVisible = true
    LocationTrackerView(isTabBarVisible: $isTabBarVisible)
}

