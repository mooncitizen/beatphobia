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
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("setting.miles") private var enableMiles = false
    @State private var showFullScreenMap = false
    @State private var linkedPlan: ExposurePlan?
    @State private var targetCompletions: [TargetCompletion] = []
    
    // Get the linked plan from Realm
    private func loadLinkedPlanAsync() {
        guard let realm = try? Realm(),
              let journeyId = UUID(uuidString: journey.id) else {
            print("⚠️ JourneyDetailView: Could not parse journey ID: \(journey.id)")
            return
        }
        
        guard let journeyMeta = realm.object(ofType: Journey.self, forPrimaryKey: journeyId) else {
            print("⚠️ JourneyDetailView: Could not find Journey with ID: \(journeyId)")
            return
        }
        
        guard let planId = journeyMeta.linkedPlanId else {
            print("ℹ️ JourneyDetailView: Journey has no linkedPlanId")
            return
        }
        
        print("📍 JourneyDetailView: Found linkedPlanId: \(planId)")
        
        guard let plan = realm.object(ofType: ExposurePlan.self, forPrimaryKey: planId) else {
            print("⚠️ JourneyDetailView: Could not find ExposurePlan with ID: \(planId)")
            return
        }
        
        print("✅ JourneyDetailView: Loaded plan: \(plan.name) with \(plan.targets.filter { !$0.isDeleted }.count) targets")
        
        linkedPlan = plan
        
        // Analyze target completions based on actual path
        analyzeTargetCompletions(plan: plan)
    }
    
    // Analyze which targets were likely reached based on proximity to actual path
    private func analyzeTargetCompletions(plan: ExposurePlan) {
        let targets = plan.targets.filter { !$0.isDeleted }.sorted(by: { $0.orderIndex < $1.orderIndex })
        var completions: [TargetCompletion] = []
        
        // Convert journey path points to CLLocation array
        let pathLocations = journey.pathPoints.map { point in
            CLLocation(latitude: point.latitude, longitude: point.longitude)
        }
        
        for (index, target) in targets.enumerated() {
            let targetLocation = CLLocation(latitude: target.latitude, longitude: target.longitude)
            
            // Find minimum distance from any path point to this target
            var minDistance: CLLocationDistance = Double.greatestFiniteMagnitude
            var closestPointIndex: Int? = nil
            var timeAtTarget: Date? = nil
            
            for (pathIndex, pathLocation) in pathLocations.enumerated() {
                let distance = targetLocation.distance(from: pathLocation)
                if distance < minDistance {
                    minDistance = distance
                    closestPointIndex = pathIndex
                    // Estimate time based on path point index (rough approximation)
                    if pathIndex < journey.pathPoints.count {
                        // Use start time + estimated time based on point index
                        let totalDuration = journey.duration
                        let pointTime = journey.startTime.addingTimeInterval(Double(pathIndex) * Double(totalDuration) / Double(max(1, pathLocations.count)))
                        timeAtTarget = pointTime
                    }
                }
            }
            
            // Consider target "reached" if within 30 meters (geofence radius was 10-20m)
            let wasReached = minDistance <= 30.0
            
            // Estimate wait time: if user stayed within 30m for a period, estimate wait time
            var estimatedWaitTime: TimeInterval = 0
            if wasReached, let closestIndex = closestPointIndex {
                // Count consecutive points within 30m of target
                var pointsNearTarget = 0
                for i in max(0, closestIndex - 10)..<min(pathLocations.count, closestIndex + 10) {
                    let distance = targetLocation.distance(from: pathLocations[i])
                    if distance <= 30.0 {
                        pointsNearTarget += 1
                    }
                }
                // Estimate wait time: assume location updates every 5 seconds
                estimatedWaitTime = Double(pointsNearTarget) * 5.0
                // Cap at planned wait time
                estimatedWaitTime = min(estimatedWaitTime, Double(target.waitTimeInSeconds))
            }
            
            completions.append(TargetCompletion(
                target: target,
                index: index,
                wasReached: wasReached,
                minDistance: minDistance,
                timeReached: timeAtTarget,
                estimatedWaitTime: estimatedWaitTime
            ))
        }
        
        targetCompletions = completions
    }
    
    var body: some View {
        ZStack {
            AppConstants.backgroundColor(for: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Compact map section
                    compactMapSection
                    
                    // Plan information section (if journey was part of a plan)
                    if linkedPlan != nil {
                        planInfoSection
                            .padding(.horizontal, 20)
                    }
                    
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
                        .padding(.bottom, 100)
                }
            }
            .onAppear {
                loadLinkedPlanAsync()
            }
        }
        .navigationTitle(journey.startTime.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
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
            
            if !journey.hesitationPoints.isEmpty {
                HStack(spacing: 12) {
                    detailStatCard(
                        icon: "pause.circle.fill",
                        title: "Hesitations",
                        value: "\(journey.hesitationPoints.count)",
                        color: .red
                    )
                    
                    Spacer()
                }
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
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(AppConstants.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 3)
    }
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Emotional Timeline")
                .font(.system(size: 20, weight: .bold))
                .fontDesign(.serif)
                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

            VStack(spacing: 12) {
                ForEach(Array(journey.checkpoints.enumerated()), id: \.element.id) { index, checkpoint in
                    timelineItem(checkpoint: checkpoint, isLast: index == journey.checkpoints.count - 1)
                }
            }
            .padding(16)
            .background(AppConstants.cardBackgroundColor(for: colorScheme))
            .cornerRadius(16)
            .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 3)
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
                        .fill(AppConstants.borderColor(for: colorScheme).opacity(0.3))
                        .frame(width: 2, height: 40)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                let feeling = FeelingLevel(rawValue: checkpoint.feeling) ?? .okay

                Text(feeling.title)
                    .font(.system(size: 16, weight: .semibold))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                Text(checkpoint.timestamp.formatted(date: .omitted, time: .complete))
                    .font(.system(size: 13))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
            }
            
            Spacer()
        }
    }
    
    // MARK: - Plan Info Section
    private var planInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let plan = linkedPlan {
                // Plan header
                HStack {
                    Image(systemName: "map.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppConstants.primaryColor)
                    
                    Text(plan.name)
                        .font(.system(size: 20, weight: .bold))
                        .fontDesign(.serif)
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    
                    Spacer()
                }
                
                // Plan stats
                let targetsReached = targetCompletions.filter { $0.wasReached }.count
                let totalTargets = targetCompletions.count
                
                HStack(spacing: 12) {
                    planStatCard(
                        icon: "checkmark.circle.fill",
                        title: "Targets Reached",
                        value: "\(targetsReached)/\(totalTargets)",
                        color: targetsReached == totalTargets ? .green : .orange
                    )
                    
                    planStatCard(
                        icon: "clock.fill",
                        title: "Plan Progress",
                        value: totalTargets > 0 ? "\(Int((Double(targetsReached) / Double(totalTargets)) * 100))%" : "0%",
                        color: AppConstants.primaryColor
                    )
                }
                
                // Targets list
                if !targetCompletions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Targets")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        
                        ForEach(Array(targetCompletions.enumerated()), id: \.element.target.id) { index, completion in
                            targetCompletionRow(completion: completion, index: index)
                        }
                    }
                    .padding(16)
                    .background(AppConstants.cardBackgroundColor(for: colorScheme))
                    .cornerRadius(16)
                    .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 3)
                }
            }
        }
    }
    
    private func planStatCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .fontDesign(.monospaced)
                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppConstants.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 3)
    }
    
    private func targetCompletionRow(completion: TargetCompletion, index: Int) -> some View {
        HStack(spacing: 12) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(completion.wasReached ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                if completion.wasReached {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
            }
            
            // Target info
            VStack(alignment: .leading, spacing: 4) {
                Text(completion.target.name.isEmpty ? "Target \(index + 1)" : completion.target.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                HStack(spacing: 12) {
                    if completion.wasReached {
                        if completion.estimatedWaitTime > 0 {
                            Text("Waited: \(formatWaitTime(completion.estimatedWaitTime))")
                                .font(.system(size: 12))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        }
                        
                        if let timeReached = completion.timeReached {
                            Text(timeReached.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 12))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        }
                    } else {
                        Text("Not reached")
                            .font(.system(size: 12))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        
                        Text("Closest: \(formatDistance(completion.minDistance))")
                            .font(.system(size: 12))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private func formatWaitTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if minutes > 0 {
            return "\(minutes)m \(secs)s"
        }
        return "\(secs)s"
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Journey Summary")
                .font(.system(size: 20, weight: .bold))
                .fontDesign(.serif)
                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

            VStack(alignment: .leading, spacing: 12) {
                summaryRow(icon: "calendar", label: "Date", value: journey.startTime.formatted(date: .long, time: .omitted))
                summaryRow(icon: "clock", label: "Started", value: journey.startTime.formatted(date: .omitted, time: .shortened))
                summaryRow(icon: "clock.badge.checkmark", label: "Ended", value: journey.endTime.formatted(date: .omitted, time: .shortened))
            }
            .padding(16)
            .background(AppConstants.cardBackgroundColor(for: colorScheme))
            .cornerRadius(16)
            .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 3)
        }
    }
    
    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppConstants.adaptivePrimaryColor(for: colorScheme))
                .frame(width: 24)

            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .fontDesign(.monospaced)
                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
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
        
        // Clear planned route polylines
        context.coordinator.plannedRoutePolylines.removeAll()
        
        guard !journey.pathPoints.isEmpty else { return }
        
        // Load linked plan if exists
        var linkedPlan: ExposurePlan?
        if let realm = try? Realm(),
           let journeyId = UUID(uuidString: journey.id),
           let journeyMeta = realm.object(ofType: Journey.self, forPrimaryKey: journeyId),
           let planId = journeyMeta.linkedPlanId {
            linkedPlan = realm.object(ofType: ExposurePlan.self, forPrimaryKey: planId)
        }
        
        // Add planned route if plan exists
        if let plan = linkedPlan {
            addPlannedRoute(plan: plan, to: mapView, context: context)
        }
        
        // Convert path points to coordinates array
        var coordinates = [CLLocationCoordinate2D]()
        for point in journey.pathPoints {
            coordinates.append(CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude))
        }
        
        // Calculate starting point and maximum distance from start (and find furthest point)
        let startCoordinate = coordinates[0]
        var maxDistanceFromStart: CLLocationDistance = 0
        var furthestPointCoordinate: CLLocationCoordinate2D = startCoordinate
        
        for coordinate in coordinates {
            let startLocation = CLLocation(latitude: startCoordinate.latitude, longitude: startCoordinate.longitude)
            let currentLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let distance = startLocation.distance(from: currentLocation)
            if distance > maxDistanceFromStart {
                maxDistanceFromStart = distance
                furthestPointCoordinate = coordinate
            }
        }
        
        // Add total distance circle overlay (blue - straight line potential)
        if journey.distance > 0 {
            let totalDistanceCircle = TotalDistanceCircle(center: startCoordinate, radius: journey.distance)
            mapView.addOverlay(totalDistanceCircle)
        }
        
        // Add furthest distance circle overlay (green dashed circle from start)
        if maxDistanceFromStart > 0 {
            let maxDistanceCircle = MaxDistanceCircle(center: startCoordinate, radius: maxDistanceFromStart)
            mapView.addOverlay(maxDistanceCircle)
        }
        
        // Add safe area overlay (from all journeys)
        if let safeAreaPolygon = calculateSafeAreaPolygon() {
            mapView.addOverlay(safeAreaPolygon)
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
        
        // Add hesitation annotations
        for hesitation in journey.hesitationPoints {
            let coordinate = CLLocationCoordinate2D(latitude: hesitation.latitude, longitude: hesitation.longitude)
            let annotation = SavedHesitationAnnotation(
                coordinate: coordinate,
                startTime: hesitation.startTime,
                endTime: hesitation.endTime,
                duration: hesitation.duration
            )
            mapView.addAnnotation(annotation)
        }
        
        // Add start point annotation
        mapView.addAnnotation(StartPointAnnotation(coordinate: startCoordinate))
        
        // Add finish point annotation
        if let lastPoint = coordinates.last {
            mapView.addAnnotation(FinishPointAnnotation(coordinate: lastPoint))
        }
        
        // Add halfway point annotation
        if coordinates.count > 2 {
            let halfwayIndex = coordinates.count / 2
            let halfwayCoordinate = coordinates[halfwayIndex]
            mapView.addAnnotation(HalfwayPointAnnotation(coordinate: halfwayCoordinate))
        }
        
        // Fit map to show entire route including circles
        if coordinates.count > 0 {
            var coordsCopy = coordinates
            let polyline = MKPolyline(coordinates: &coordsCopy, count: coordsCopy.count)
            
            // Calculate the map rect to include the route and circles
            let totalDistanceRect = MKCircle(center: startCoordinate, radius: journey.distance).boundingMapRect
            var combinedRect = polyline.boundingMapRect.union(totalDistanceRect)
            
            // Also include the max distance circle
            if maxDistanceFromStart > 0 {
                let maxCircleRect = MKCircle(center: startCoordinate, radius: maxDistanceFromStart).boundingMapRect
                combinedRect = combinedRect.union(maxCircleRect)
            }
            
            mapView.setVisibleMapRect(combinedRect, edgePadding: UIEdgeInsets(top: 60, left: 60, bottom: 60, right: 60), animated: false)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // Add planned route overlays and annotations
    private func addPlannedRoute(plan: ExposurePlan, to mapView: MKMapView, context: Context) {
        let targets = plan.targets.filter { !$0.isDeleted }.sorted(by: { $0.orderIndex < $1.orderIndex })
        guard !targets.isEmpty else { return }
        
        // Store planned route polylines in coordinator
        let coordinator = context.coordinator
        
        // Add target annotations
        for (index, target) in targets.enumerated() {
            let coordinate = CLLocationCoordinate2D(latitude: target.latitude, longitude: target.longitude)
            
            // Check if target was reached (within 30m of any path point)
            var wasReached = false
            let targetLocation = CLLocation(latitude: target.latitude, longitude: target.longitude)
            for point in journey.pathPoints {
                let pathLocation = CLLocation(latitude: point.latitude, longitude: point.longitude)
                if targetLocation.distance(from: pathLocation) <= 30.0 {
                    wasReached = true
                    break
                }
            }
            
            let annotation = PlannedTargetAnnotation(
                target: target,
                index: index,
                wasReached: wasReached
            )
            mapView.addAnnotation(annotation)
        }
        
        // Calculate and add planned route polylines between targets
        if targets.count > 1 {
            for i in 0..<targets.count - 1 {
                let fromTarget = targets[i]
                let toTarget = targets[i + 1]
                
                let request = MKDirections.Request()
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: fromTarget.latitude, longitude: fromTarget.longitude)))
                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: toTarget.latitude, longitude: toTarget.longitude)))
                request.transportType = .walking
                
                let directions = MKDirections(request: request)
                directions.calculate { response, error in
                    guard let route = response?.routes.first else { return }
                    DispatchQueue.main.async {
                        // Store as planned route polyline
                        let polyline = route.polyline
                        coordinator.plannedRoutePolylines.append(polyline)
                        mapView.addOverlay(polyline)
                    }
                }
            }
        }
    }
    
    // Calculate safe area polygon from all journeys
    private func calculateSafeAreaPolygon() -> MKPolygon? {
        guard let realm = try? Realm() else { return nil }
        
        // Get all safe area points from all journeys
        let safeAreaPoints = realm.objects(SafeAreaPointRealm.self)
        
        guard safeAreaPoints.count >= 3 else { return nil } // Need at least 3 points for a polygon
        
        // Step 1: Create a grid and count point density to identify "intense repeat travels"
        let gridSize: Double = 50.0 // 50 meter grid cells
        
        // Find bounding box of all safe area points
        var minLat = Double.greatestFiniteMagnitude
        var maxLat = -Double.greatestFiniteMagnitude
        var minLon = Double.greatestFiniteMagnitude
        var maxLon = -Double.greatestFiniteMagnitude
        
        for point in safeAreaPoints {
            minLat = min(minLat, point.latitude)
            maxLat = max(maxLat, point.latitude)
            minLon = min(minLon, point.longitude)
            maxLon = max(maxLon, point.longitude)
        }
        
        // Calculate grid dimensions
        let centerLat = (minLat + maxLat) / 2.0
        let metersPerDegreeLat = 111320.0
        let metersPerDegreeLon = 111320.0 * cos(centerLat * .pi / 180.0)
        
        let degreesLat = gridSize / metersPerDegreeLat
        let degreesLon = gridSize / metersPerDegreeLon
        
        // Count points in each grid cell
        var cellCounts: [String: Int] = [:]
        var cellPoints: [String: [CLLocationCoordinate2D]] = [:]
        
        for point in safeAreaPoints {
            let latIndex = Int((point.latitude - minLat) / degreesLat)
            let lonIndex = Int((point.longitude - minLon) / degreesLon)
            let key = "\(latIndex),\(lonIndex)"
            
            cellCounts[key, default: 0] += 1
            if cellPoints[key] == nil {
                cellPoints[key] = []
            }
            cellPoints[key]?.append(CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude))
        }
        
        // Step 2: Filter to only include high-density cells (intense repeat travels)
        // Use cells with count >= 3 (areas visited multiple times) or above average
        let avgCount = Double(cellCounts.values.reduce(0, +)) / Double(cellCounts.count)
        let threshold = max(3.0, avgCount * 1.5) // At least 3 points or 1.5x average
        
        var intenseTravelPoints: [CLLocationCoordinate2D] = []
        for (key, count) in cellCounts {
            if Double(count) >= threshold, let points = cellPoints[key] {
                // Use the average coordinate of points in this cell
                let avgLat = points.map { $0.latitude }.reduce(0, +) / Double(points.count)
                let avgLon = points.map { $0.longitude }.reduce(0, +) / Double(points.count)
                intenseTravelPoints.append(CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon))
            }
        }
        
        guard intenseTravelPoints.count >= 3 else { return nil }
        
        // Step 3: Compute convex hull of the intense travel areas
        let hull = convexHull(points: intenseTravelPoints)
        
        guard hull.count >= 3 else { return nil }
        
        var coordsArray = hull
        return MKPolygon(coordinates: &coordsArray, count: coordsArray.count)
    }
    
    // Convex hull algorithm (Graham scan)
    private func convexHull(points: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        guard points.count >= 3 else { return points }
        
        // Sort points lexicographically
        let sorted = points.sorted { (p1, p2) -> Bool in
            if p1.longitude != p2.longitude {
                return p1.longitude < p2.longitude
            }
            return p1.latitude < p2.latitude
        }
        
        // Build lower hull
        var lower: [CLLocationCoordinate2D] = []
        for point in sorted {
            while lower.count >= 2 && crossProduct(lower[lower.count - 2], lower[lower.count - 1], point) <= 0 {
                lower.removeLast()
            }
            lower.append(point)
        }
        
        // Build upper hull
        var upper: [CLLocationCoordinate2D] = []
        for point in sorted.reversed() {
            while upper.count >= 2 && crossProduct(upper[upper.count - 2], upper[upper.count - 1], point) <= 0 {
                upper.removeLast()
            }
            upper.append(point)
        }
        
        // Remove duplicates at the ends
        lower.removeLast()
        upper.removeLast()
        
        // Combine
        return lower + upper
    }
    
    private func crossProduct(_ o: CLLocationCoordinate2D, _ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        return (a.latitude - o.latitude) * (b.longitude - o.longitude) - (a.longitude - o.longitude) * (b.latitude - o.latitude)
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
        var plannedRoutePolylines: [MKPolyline] = []
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            // Handle total distance circle (blue - straight line potential)
            if overlay is TotalDistanceCircle {
                let renderer = MKCircleRenderer(overlay: overlay)
                renderer.fillColor = UIColor.systemBlue.withAlphaComponent(0.08)
                renderer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.35)
                renderer.lineWidth = 2
                renderer.lineDashPattern = [8, 6]
                return renderer
            }
            // Handle max distance circle (green dashed - furthest point from start)
            else if overlay is MaxDistanceCircle {
                let renderer = MKCircleRenderer(overlay: overlay)
                renderer.fillColor = UIColor.systemGreen.withAlphaComponent(0.1)
                renderer.strokeColor = UIColor.systemGreen.withAlphaComponent(0.5)
                renderer.lineWidth = 2
                renderer.lineDashPattern = [8, 4]
                return renderer
            }
            else if let polyline = overlay as? MKPolyline {
                // Check if this is a planned route (by reference equality)
                if plannedRoutePolylines.contains(where: { $0 === polyline }) {
                    // Planned route - mustard yellow dashed line
                    let renderer = MKPolylineRenderer(polyline: polyline)
                    renderer.strokeColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) // Mustard yellow
                    renderer.lineWidth = 4
                    renderer.lineDashPattern = [8, 6]
                    renderer.lineCap = .round
                    renderer.lineJoin = .round
                    return renderer
                } else {
                    // Actual route - blue solid line
                    let renderer = MKPolylineRenderer(polyline: polyline)
                    renderer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.85)
                    renderer.lineWidth = 5
                    renderer.lineCap = .round
                    renderer.lineJoin = .round
                    return renderer
                }
            }
            else if let polygon = overlay as? MKPolygon {
                // Check if this is a safe area polygon (we'll identify by checking if it's a rectangle with green styling)
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.systemGreen.withAlphaComponent(0.15)
                renderer.strokeColor = UIColor.systemGreen.withAlphaComponent(0.4)
                renderer.lineWidth = 2
                renderer.lineDashPattern = [8, 4]
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
            
            // Handle halfway point annotation
            if annotation is HalfwayPointAnnotation {
                let identifier = "HalfwayPointAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                
                // Configure as an orange/yellow marker for halfway point
                annotationView?.markerTintColor = .systemOrange
                annotationView?.glyphImage = UIImage(systemName: "location.circle.fill")
                annotationView?.glyphTintColor = .white
                annotationView?.displayPriority = .required
                
                return annotationView
            }
            
            // Handle hesitation annotations
            if let hesitationAnnotation = annotation as? SavedHesitationAnnotation {
                let identifier = "SavedHesitationAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                
                // Create red box image (30x30 point square)
                let boxSize: CGFloat = 30
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: boxSize, height: boxSize))
                let boxImage = renderer.image { context in
                    let rect = CGRect(x: 0, y: 0, width: boxSize, height: boxSize)
                    
                    // Red fill
                    UIColor.systemRed.withAlphaComponent(0.3).setFill()
                    UIBezierPath(rect: rect).fill()
                    
                    // Red dashed border
                    UIColor.systemRed.setStroke()
                    let border = UIBezierPath(rect: rect)
                    border.lineWidth = 2
                    border.setLineDash([4, 4], count: 2, phase: 0)
                    border.stroke()
                }
                
                annotationView?.image = boxImage
                annotationView?.centerOffset = CGPoint(x: 0, y: 0)
                return annotationView
            }
            

            // Handle planned target annotations
            if let plannedTarget = annotation as? PlannedTargetAnnotation {
                let identifier = "PlannedTargetAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                
                // Color based on whether target was reached
                if plannedTarget.wasReached {
                    annotationView?.markerTintColor = .systemGreen
                    annotationView?.glyphImage = UIImage(systemName: "checkmark.circle.fill")
                } else {
                    annotationView?.markerTintColor = .systemGray
                    annotationView?.glyphImage = UIImage(systemName: "mappin.circle.fill")
                }
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

class HalfwayPointAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    
    var title: String? {
        "Halfway Point"
    }
    
    var subtitle: String? {
        "Midpoint of your journey"
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
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Map Legend")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                Text("Understanding your journey visualization")
                    .font(.system(size: 15))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)
            .background(AppConstants.backgroundColor(for: colorScheme))

            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
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
                    
                    // Safe Area
                    LegendItem(
                        icon: "square.fill",
                        iconColor: .green,
                        title: "Safe Area (Green)",
                        description: "Shows areas where you've traveled without experiencing anxious or panic feelings. This safe zone accumulates across all your journeys over time."
                    )
                    
                    // Furthest Distance Circle
                    LegendItem(
                        icon: "circle.dashed",
                        iconColor: .green,
                        title: "Green Circle (Dashed)",
                        description: "Shows the furthest distance you reached from your starting point. This circle marks the maximum range of your journey."
                    )
                    
                    // Red Hesitation Boxes
                    LegendItem(
                        icon: "square.dashed",
                        iconColor: .red,
                        title: "Red Boxes",
                        description: "Shows locations where you hesitated or paused for 15 seconds or more within a 10-meter area."
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
                        description: "Marks where your journey started. This is the center point of the distance circle."
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
            .background(AppConstants.backgroundColor(for: colorScheme))
        }
        .background(AppConstants.backgroundColor(for: colorScheme))
    }
}

struct LegendItem: View {
    @Environment(\.colorScheme) var colorScheme
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
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(AppConstants.cardBackgroundColor(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 2)
    }
}

// MARK: - Saved Hesitation Annotation
class SavedHesitationAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let startTime: Date
    let endTime: Date
    let duration: Double
    
    var title: String? {
        "Hesitation"
    }
    
    var subtitle: String? {
        "\(Int(duration))s"
    }
    
    init(coordinate: CLLocationCoordinate2D, startTime: Date, endTime: Date, duration: Double) {
        self.coordinate = coordinate
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
    }
}

// MARK: - Target Completion Model
struct TargetCompletion {
    let target: ExposureTarget
    let index: Int
    let wasReached: Bool
    let minDistance: CLLocationDistance
    let timeReached: Date?
    let estimatedWaitTime: TimeInterval
}

// MARK: - Planned Target Annotation
class PlannedTargetAnnotation: NSObject, MKAnnotation {
    let target: ExposureTarget
    let index: Int
    let wasReached: Bool
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: target.latitude, longitude: target.longitude)
    }
    
    var title: String? {
        target.name.isEmpty ? "Target \(index + 1)" : target.name
    }
    
    var subtitle: String? {
        wasReached ? "Reached" : "Not reached"
    }
    
    init(target: ExposureTarget, index: Int, wasReached: Bool) {
        self.target = target
        self.index = index
        self.wasReached = wasReached
        super.init()
    }
}

// MARK: - Custom Circle Overlays

// Circle representing the total distance traveled (blue)
class TotalDistanceCircle: MKCircle {}

// Circle representing the maximum distance from start point (green)
class MaxDistanceCircle: MKCircle {}
