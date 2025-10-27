//
//  JourneyDetailView.swift
//  beatphobia
//
//  Created by Paul Gardiner on 25/10/2025.
//

import SwiftUI
import MapKit
import RealmSwift

struct JourneyDetailView: View {
    let journey: JourneyRealm
    @Environment(\.dismiss) var dismiss
    @AppStorage("setting.miles") private var enableMiles = false
    @State private var showFullScreenMap = false
    
    var body: some View {
        ZStack {
            AppConstants.defaultBackgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Compact map section
                    compactMapSection
                    
                    // Stats cards
                    statsSection
                        .padding(.horizontal, 20)
                    
                    // Timeline section
                    if !journey.checkpoints.isEmpty {
                        timelineSection
                            .padding(.horizontal, 20)
                    }
                    
                    // Journey summary
                    summarySection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(journey.startTime.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 16, weight: .bold))
                        .fontDesign(.serif)
                        .foregroundColor(.black)
                    
                    Text(journey.startTime.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 12))
                        .foregroundColor(.black.opacity(0.6))
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .fullScreenCover(isPresented: $showFullScreenMap) {
            FullScreenMapView(journey: journey, isPresented: $showFullScreenMap)
        }
    }
    
    private var compactMapSection: some View {
        VStack(spacing: 0) {
            ZStack {
                SavedJourneyMapView(journey: journey, isInteractive: false)
                    .frame(height: 250)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
                
                // Transparent overlay to capture taps
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showFullScreenMap = true
                    }
                
                // Expand indicator
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 40, height: 40)
                                .shadow(color: Color.black.opacity(0.2), radius: 8, y: 3)
                            
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppConstants.primaryColor)
                        }
                        .padding(12)
                    }
                }
            }
            .frame(height: 250)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var statsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                detailStatCard(
                    icon: "clock.fill",
                    title: "Duration",
                    value: formatDuration(journey.duration),
                    color: AppConstants.primaryColor
                )
                
                detailStatCard(
                    icon: "figure.walk",
                    title: "Distance",
                    value: formatDistance(journey.distance),
                    color: .green
                )
            }
            
            HStack(spacing: 12) {
                detailStatCard(
                    icon: "gauge.high",
                    title: "Avg Pace",
                    value: calculatePace(),
                    color: .orange
                )
                
                detailStatCard(
                    icon: "heart.fill",
                    title: "Checkpoints",
                    value: "\(journey.checkpoints.count)",
                    color: .pink
                )
            }
        }
    }
    
    private func detailStatCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .fontDesign(.monospaced)
                    .foregroundColor(.black)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.black.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, y: 3)
    }
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Emotional Timeline")
                .font(.system(size: 20, weight: .bold))
                .fontDesign(.serif)
                .foregroundColor(.black)
            
            VStack(spacing: 12) {
                ForEach(Array(journey.checkpoints.enumerated()), id: \.element.id) { index, checkpoint in
                    timelineItem(checkpoint: checkpoint, isLast: index == journey.checkpoints.count - 1)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 3)
        }
    }
    
    private func timelineItem(checkpoint: FeelingCheckpointRealm, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline indicator
            VStack(spacing: 0) {
                let feeling = FeelingLevel(rawValue: checkpoint.feeling) ?? .okay
                
                ZStack {
                    Circle()
                        .fill(feeling.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .fill(feeling.color)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: feeling.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                if !isLast {
                    Rectangle()
                        .fill(Color.black.opacity(0.1))
                        .frame(width: 2, height: 40)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                let feeling = FeelingLevel(rawValue: checkpoint.feeling) ?? .okay
                
                Text(feeling.title)
                    .font(.system(size: 16, weight: .semibold))
                    .fontDesign(.serif)
                    .foregroundColor(.black)
                
                Text(checkpoint.timestamp.formatted(date: .omitted, time: .complete))
                    .font(.system(size: 13))
                    .foregroundColor(.black.opacity(0.5))
            }
            
            Spacer()
        }
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Journey Summary")
                .font(.system(size: 20, weight: .bold))
                .fontDesign(.serif)
                .foregroundColor(.black)
            
            VStack(alignment: .leading, spacing: 12) {
                summaryRow(icon: "calendar", label: "Date", value: journey.startTime.formatted(date: .long, time: .omitted))
                summaryRow(icon: "clock", label: "Started", value: journey.startTime.formatted(date: .omitted, time: .shortened))
                summaryRow(icon: "clock.badge.checkmark", label: "Ended", value: journey.endTime.formatted(date: .omitted, time: .shortened))
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 3)
        }
    }
    
    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppConstants.primaryColor)
                .frame(width: 24)
            
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black.opacity(0.6))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .fontDesign(.monospaced)
                .foregroundColor(.black)
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatDistance(_ meters: Double) -> String {
        if enableMiles {
            let miles = meters / 1609.34
            return String(format: "%.2f mi", miles)
        } else {
            let kilometers = meters / 1000.0
            return String(format: "%.2f km", kilometers)
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if minutes > 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return String(format: "%dh %dm", hours, mins)
        }
        return String(format: "%dm %ds", minutes, secs)
    }
    
    private func calculatePace() -> String {
        guard journey.duration > 0 && journey.distance > 0 else { return "--:--" }
        
        let distance = enableMiles ? (journey.distance / 1609.34) : (journey.distance / 1000.0)
        let paceMinPerUnit = Double(journey.duration) / 60.0 / distance
        let paceMin = Int(paceMinPerUnit)
        let paceSec = Int((paceMinPerUnit - Double(paceMin)) * 60)
        return String(format: "%d:%02d", paceMin, paceSec)
    }
}

// MARK: - Saved Journey Map View
struct SavedJourneyMapView: UIViewRepresentable {
    let journey: JourneyRealm
    var isInteractive: Bool = true
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.isUserInteractionEnabled = isInteractive
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Clear existing overlays and annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        guard !journey.pathPoints.isEmpty else { return }
        
        // Convert path points to coordinates array
        var coordinates = [CLLocationCoordinate2D]()
        for point in journey.pathPoints {
            coordinates.append(CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude))
        }
        
        // Calculate starting point and maximum distance from start
        let startCoordinate = coordinates[0]
        var maxDistanceFromStart: CLLocationDistance = 0
        
        for coordinate in coordinates {
            let startLocation = CLLocation(latitude: startCoordinate.latitude, longitude: startCoordinate.longitude)
            let currentLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let distance = startLocation.distance(from: currentLocation)
            if distance > maxDistanceFromStart {
                maxDistanceFromStart = distance
            }
        }
        
        // Add achievement circle overlay (green - furthest point)
        if maxDistanceFromStart > 0 {
            let circle = MaxDistanceCircle(center: startCoordinate, radius: maxDistanceFromStart)
            mapView.addOverlay(circle)
        }
        
        // Add total distance circle overlay (blue - straight line potential)
        if journey.distance > 0 {
            let totalDistanceCircle = TotalDistanceCircle(center: startCoordinate, radius: journey.distance)
            mapView.addOverlay(totalDistanceCircle)
        }
        
        // Add smoothed polyline for the route
        if coordinates.count > 1 {
            let smoothedCoordinates = smoothPath(coordinates: coordinates)
            var smoothedArray = smoothedCoordinates
            let polyline = MKPolyline(coordinates: &smoothedArray, count: smoothedArray.count)
            mapView.addOverlay(polyline)
        }
        
        // Add feeling checkpoint annotations
        for checkpoint in journey.checkpoints {
            let coordinate = CLLocationCoordinate2D(latitude: checkpoint.latitude, longitude: checkpoint.longitude)
            let feeling = FeelingLevel(rawValue: checkpoint.feeling) ?? .okay
            let annotation = SavedFeelingAnnotation(coordinate: coordinate, feeling: feeling, timestamp: checkpoint.timestamp)
            mapView.addAnnotation(annotation)
        }
        
        // Add start point annotation
        mapView.addAnnotation(StartPointAnnotation(coordinate: startCoordinate))
        
        // Add finish point annotation
        if let lastPoint = coordinates.last {
            mapView.addAnnotation(FinishPointAnnotation(coordinate: lastPoint))
        }
        
        // Fit map to show entire route including both circles
        if coordinates.count > 0 {
            var coordsCopy = coordinates
            let polyline = MKPolyline(coordinates: &coordsCopy, count: coordsCopy.count)
            
            // Calculate the map rect to include the route and both circles
            let maxCircleRect = MKCircle(center: startCoordinate, radius: maxDistanceFromStart).boundingMapRect
            let totalDistanceRect = MKCircle(center: startCoordinate, radius: journey.distance).boundingMapRect
            
            var combinedRect = polyline.boundingMapRect.union(maxCircleRect)
            combinedRect = combinedRect.union(totalDistanceRect)
            
            mapView.setVisibleMapRect(combinedRect, edgePadding: UIEdgeInsets(top: 60, left: 60, bottom: 60, right: 60), animated: false)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // Smooth path using Catmull-Rom spline interpolation
    private func smoothPath(coordinates: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        guard coordinates.count > 2 else { return coordinates }
        
        var smoothed: [CLLocationCoordinate2D] = []
        let segmentsPerPoint = 5 // Number of interpolated points between each pair
        
        for i in 0..<coordinates.count {
            if i == 0 {
                smoothed.append(coordinates[i])
                continue
            }
            
            let p0 = coordinates[max(0, i - 2)]
            let p1 = coordinates[max(0, i - 1)]
            let p2 = coordinates[i]
            let p3 = coordinates[min(coordinates.count - 1, i + 1)]
            
            // Generate interpolated points
            for t in 1...segmentsPerPoint {
                let t_val = Double(t) / Double(segmentsPerPoint)
                let t2 = t_val * t_val
                let t3 = t2 * t_val
                
                // Catmull-Rom spline formula
                let lat = 0.5 * (
                    (2.0 * p1.latitude) +
                    (-p0.latitude + p2.latitude) * t_val +
                    (2.0 * p0.latitude - 5.0 * p1.latitude + 4.0 * p2.latitude - p3.latitude) * t2 +
                    (-p0.latitude + 3.0 * p1.latitude - 3.0 * p2.latitude + p3.latitude) * t3
                )
                
                let lon = 0.5 * (
                    (2.0 * p1.longitude) +
                    (-p0.longitude + p2.longitude) * t_val +
                    (2.0 * p0.longitude - 5.0 * p1.longitude + 4.0 * p2.longitude - p3.longitude) * t2 +
                    (-p0.longitude + 3.0 * p1.longitude - 3.0 * p2.longitude + p3.longitude) * t3
                )
                
                smoothed.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
        }
        
        return smoothed
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            // Handle max distance circle (green - furthest point)
            if overlay is MaxDistanceCircle {
                let renderer = MKCircleRenderer(overlay: overlay)
                renderer.fillColor = UIColor.systemGreen.withAlphaComponent(0.12)
                renderer.strokeColor = UIColor.systemGreen.withAlphaComponent(0.4)
                renderer.lineWidth = 2
                renderer.lineDashPattern = [6, 4]
                return renderer
            }
            // Handle total distance circle (blue - straight line potential)
            else if overlay is TotalDistanceCircle {
                let renderer = MKCircleRenderer(overlay: overlay)
                renderer.fillColor = UIColor.systemBlue.withAlphaComponent(0.08)
                renderer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.35)
                renderer.lineWidth = 2
                renderer.lineDashPattern = [8, 6]
                return renderer
            }
            else if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.85)
                renderer.lineWidth = 5
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Handle start point annotation
            if annotation is StartPointAnnotation {
                let identifier = "StartPointAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                
                // Configure as a prominent red pin with flag icon
                annotationView?.markerTintColor = .systemRed
                annotationView?.glyphImage = UIImage(systemName: "flag.fill")
                annotationView?.glyphTintColor = .white
                annotationView?.displayPriority = .required
                
                return annotationView
            }
            
            // Handle finish point annotation
            if annotation is FinishPointAnnotation {
                let identifier = "FinishPointAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                
                // Configure as a checkered flag pin
                annotationView?.markerTintColor = .black
                annotationView?.glyphImage = UIImage(systemName: "flag.checkered")
                annotationView?.glyphTintColor = .white
                annotationView?.displayPriority = .required
                
                return annotationView
            }
            
            // Handle feeling checkpoint annotations
            if let feelingAnnotation = annotation as? SavedFeelingAnnotation {
                let identifier = "SavedFeelingAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                
                // Create subtle feeling marker
                let pinSize: CGFloat = 20
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: pinSize, height: pinSize))
                let pinImage = renderer.image { context in
                    // White background with shadow
                    UIColor.white.setFill()
                    let bgCircle = UIBezierPath(ovalIn: CGRect(x: 2, y: 2, width: pinSize - 4, height: pinSize - 4))
                    bgCircle.fill()
                    
                    // Colored border (thinner and more transparent)
                    feelingAnnotation.feeling.uiColor.withAlphaComponent(0.7).setStroke()
                    bgCircle.lineWidth = 1.5
                    bgCircle.stroke()
                    
                    // Small inner colored dot
                    feelingAnnotation.feeling.uiColor.withAlphaComponent(0.6).setFill()
                    let innerDot = UIBezierPath(ovalIn: CGRect(x: 7, y: 7, width: 6, height: 6))
                    innerDot.fill()
                }
                
                annotationView?.image = pinImage
                return annotationView
            }
            
            return nil
        }
    }
}

// MARK: - Start Point Annotation
class StartPointAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    
    var title: String? {
        "Start Point"
    }
    
    var subtitle: String? {
        "Your journey began here"
    }
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}

class FinishPointAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    
    var title: String? {
        "Finish Point"
    }
    
    var subtitle: String? {
        "Your journey ended here"
    }
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}

// MARK: - Saved Feeling Annotation
class SavedFeelingAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let feeling: FeelingLevel
    let timestamp: Date
    
    var title: String? {
        feeling.title
    }
    
    var subtitle: String? {
        timestamp.formatted(date: .omitted, time: .shortened)
    }
    
    init(coordinate: CLLocationCoordinate2D, feeling: FeelingLevel, timestamp: Date) {
        self.coordinate = coordinate
        self.feeling = feeling
        self.timestamp = timestamp
    }
}

// MARK: - Full Screen Map View
struct FullScreenMapView: View {
    let journey: JourneyRealm
    @Binding var isPresented: Bool
    @State private var showMapInfo = false
    
    var body: some View {
        ZStack {
            SavedJourneyMapView(journey: journey)
                .ignoresSafeArea()
            
            // Top buttons
            VStack {
                HStack {
                    // Close button - top left
                    Button(action: {
                        isPresented = false
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
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    // Info button - top right
                    Button(action: {
                        showMapInfo = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 44, height: 44)
                                .shadow(color: Color.black.opacity(0.2), radius: 10, y: 3)
                            
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(AppConstants.primaryColor)
                        }
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 10)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showMapInfo) {
            MapLegendSheet()
                .presentationDetents([.medium])
        }
    }
}

// MARK: - Map Legend Sheet
struct MapLegendSheet: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Map Legend")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(.black)
                
                Text("Understanding your journey visualization")
                    .font(.system(size: 15))
                    .foregroundColor(.black.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)
            .background(AppConstants.defaultBackgroundColor)
            
            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Green Circle
                    LegendItem(
                        icon: "circle.dashed",
                        iconColor: .green,
                        title: "Green Circle (Dashed)",
                        description: "Shows the furthest point you reached from your starting location. This represents your maximum distance away from where you began."
                    )
                    
                    // Blue Circle
                    LegendItem(
                        icon: "circle.dashed",
                        iconColor: .blue,
                        title: "Blue Circle (Dashed)",
                        description: "Shows the total distance you traveled. If you had walked in a straight line, this is where you could have reached."
                    )
                    
                    // Blue Route Line
                    LegendItem(
                        icon: "line.diagonal",
                        iconColor: .blue,
                        title: "Blue Route Line (Solid)",
                        description: "Your actual walking path. This is the route you took during your journey."
                    )
                    
                    // Feeling Checkpoints
                    LegendItem(
                        icon: "circle.fill",
                        iconColor: .orange,
                        title: "Colored Dots",
                        description: "Your feeling checkpoints. Each dot is colored based on how you felt at that moment during your journey."
                    )
                    
                    // Start Point
                    LegendItem(
                        icon: "flag.fill",
                        iconColor: .red,
                        title: "Red Flag Pin",
                        description: "Marks where your journey started. This is the center point of both radius circles."
                    )
                    
                    // Finish Point
                    LegendItem(
                        icon: "flag.checkered",
                        iconColor: .black,
                        title: "Black Checkered Flag Pin",
                        description: "Marks where your journey ended. This is the final point of your walking path."
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .background(AppConstants.defaultBackgroundColor)
        }
        .background(AppConstants.defaultBackgroundColor)
    }
}

struct LegendItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.black.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }
}

// MARK: - Custom Circle Overlays

// Circle representing the furthest point from start (green)
class MaxDistanceCircle: MKCircle {}

// Circle representing the total distance traveled (blue)
class TotalDistanceCircle: MKCircle {}
