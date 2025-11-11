//
//  PlanDetailView.swift
//  beatphobia
//
//  Created for Guided Exposure Plans feature
//

import SwiftUI
import MapKit
import CoreLocation
import Combine
import RealmSwift

struct PlanDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authManager: AuthManager
    @ObservedRealmObject var plan: ExposurePlan
    @Binding var isTabBarVisible: Bool
    
    @State private var planName: String = ""
    @State private var targets: [ExposureTarget] = []
    @State private var showLocationSearch: Bool = false
    @State private var editingTargetIndex: Int?
    @State private var showStartPlanAlert: Bool = false
    @State private var showTrackingView: Bool = false
    @State private var isGeneratingPlan: Bool = false
    @State private var completedTargetIndices: Set<Int> = []
    @EnvironmentObject var journeySyncService: JourneySyncService
    @StateObject private var locationManager = CurrentLocationManager()
    @State private var planProgress: PlanProgress?
    
    @AppStorage("setting.miles") private var enableMiles = false
    
    let shouldAutoGenerate: Bool
    
    init(plan: ExposurePlan, isTabBarVisible: Binding<Bool>, shouldAutoGenerate: Bool = false) {
        self._plan = ObservedRealmObject(wrappedValue: plan)
        self._isTabBarVisible = isTabBarVisible
        self.shouldAutoGenerate = shouldAutoGenerate
    }
    
    var body: some View {
        ZStack {
            AppConstants.backgroundColor(for: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    planNameCard
                    
                    // Plan progress section
                    planProgressSection
                        .padding(.horizontal, 20)
                    
                    mapPreviewCard
                    targetsSection
                }
            }
            
            // Progress spinner overlay when generating plan
            if isGeneratingPlan {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(AppConstants.primaryColor)
                        
                        Text("Generating your plan...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppConstants.cardBackgroundColor(for: colorScheme))
                    )
                    .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 20, y: 10)
                }
            }
        }
        .navigationTitle(planName.isEmpty ? "New Plan" : planName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    handleCancel()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    if !targets.isEmpty {
                        Button("Start Journey") {
                            showStartPlanAlert = true
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppConstants.primaryColor)
                    }
                    
                    Button("Save") {
                        savePlan()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppConstants.primaryColor)
                }
            }
        }
        .sheet(isPresented: $showLocationSearch) {
            LocationSearchView(onLocationSelected: { name, coordinate in
                if let index = editingTargetIndex {
                    updateTargetLocation(at: index, name: name, coordinate: coordinate)
                }
                editingTargetIndex = nil
            }, initialCoordinate: {
                // Get the current target's coordinate if editing, otherwise use current location
                if let index = editingTargetIndex, index < targets.count {
                    let target = targets[index]
                    // Only use target coordinate if it's not default (0,0)
                    if target.latitude != 0.0 || target.longitude != 0.0 {
                        return CLLocationCoordinate2D(latitude: target.latitude, longitude: target.longitude)
                    } else {
                        return locationManager.currentLocation?.coordinate
                    }
                } else {
                    return locationManager.currentLocation?.coordinate
                }
            }())
        }
        .alert("Start This Plan?", isPresented: $showStartPlanAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Start") {
                startPlan()
            }
        } message: {
            Text("This will start a new journey following this exposure plan.")
        }
        .fullScreenCover(isPresented: $showTrackingView) {
            LocationTrackingView(isTabBarVisible: $isTabBarVisible, initialPlan: plan)
                .environmentObject(journeySyncService)
        }
        .task {
            // Load plan data asynchronously
            await loadPlanAsync()

            // Check which targets are completed in active journey
            Task.detached { @MainActor in
                await checkCompletedTargets()
            }
            
            // Load plan progress
            loadPlanProgress()

            // Request location in background - don't wait for it
            Task.detached { @MainActor in
                locationManager.requestLocation()
            }
            
            // Auto-generate if requested
            if shouldAutoGenerate && targets.isEmpty {
                await autogeneratePlan()
            }
        }
    }
    
    // MARK: - View Components
    
    private var planNameCard: some View {
        Card(backgroundColor: AppConstants.cardBackgroundColor(for: colorScheme)) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Plan Name")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                
                TextField("Enter plan name", text: $planName)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    
    @ViewBuilder
    private var mapPreviewCard: some View {
        if !targets.isEmpty {
            Card(backgroundColor: AppConstants.cardBackgroundColor(for: colorScheme), padding: 0) {
                MapPreviewView(targets: targets)
                    .frame(height: 300)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var targetsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            targetsHeader
            addFirstTargetButton
            targetsList
        }
        .padding(.bottom, 100)
    }
    
    private var targetsHeader: some View {
        HStack {
            Text("Targets")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
            
            Spacer()
            
            addTargetMenu
        }
        .padding(.horizontal, 20)
    }
    
    private var addTargetMenu: some View {
        Menu {
            Button(action: {
                addNewTarget()
            }) {
                Label("Add Target", systemImage: "plus.circle")
            }
            
            Button(action: {
                guard !isGeneratingPlan else { return }
                Task {
                    await autogeneratePlan()
                }
            }) {
                Label("Auto-Generate Plan", systemImage: "sparkles")
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                Text("Add")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(AppConstants.primaryColor)
        }
    }
    
    @ViewBuilder
    private var addFirstTargetButton: some View {
        if targets.isEmpty {
            Button(action: {
                addNewTarget()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Add Your First Target")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [AppConstants.primaryColor, AppConstants.primaryColor.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: AppConstants.primaryColor.opacity(0.3), radius: 8, y: 4)
            }
            .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private var targetsList: some View {
        if targets.isEmpty {
            emptyTargetsCard
        } else {
            targetsListView
        }
    }
    
    private var emptyTargetsCard: some View {
        Card(backgroundColor: AppConstants.cardBackgroundColor(for: colorScheme)) {
            VStack(spacing: 16) {
                Image(systemName: "mappin.circle")
                    .font(.system(size: 48))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.5))
                
                Text("No targets yet")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                Text("Tap the 'Add' button above to add your first target or auto-generate a plan")
                    .font(.system(size: 14))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
        .padding(.horizontal, 20)
    }
    
    private var targetsListView: some View {
        VStack(spacing: 12) {
            ForEach(Array(targets.enumerated()), id: \.element.id) { index, target in
                TargetRowView(
                    target: target,
                    index: index,
                    isLocked: completedTargetIndices.contains(index),
                    onLocationTap: {
                        editingTargetIndex = index
                        showLocationSearch = true
                    },
                    onWaitTimeChange: { newSeconds in
                        if let realm = try? Realm(),
                           let liveTarget = target.thaw() {
                            try! realm.write {
                                liveTarget.waitTimeInSeconds = newSeconds
                                liveTarget.updatedAt = Date()
                                liveTarget.needsSync = true
                            }
                            updateTargets()
                        }
                    },
                    onDelete: {
                        deleteTarget(at: index)
                    },
                    startLocation: locationManager.currentLocation
                )
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadPlanAsync() async {
        await MainActor.run {
            planName = plan.name
            
            // Load targets and sort by order index
            targets = Array(plan.targets.filter { !$0.isDeleted }).sorted(by: { $0.orderIndex < $1.orderIndex })
        }
    }
    
    private func checkCompletedTargets() async {
        let realm = await MainActor.run {
            try? Realm()
        }
        guard let realm = realm else {
            await MainActor.run {
                completedTargetIndices = []
            }
            return
        }
        
        // Check if there's a current journey using this plan
        let currentJourney = await MainActor.run {
            realm.objects(Journey.self)
                .filter("current == true AND linkedPlanId == %@", plan.id)
                .first
        }
        
        guard currentJourney != nil else {
            await MainActor.run {
                completedTargetIndices = []
            }
            return
        }
        
        // Get the current target index from the tracking manager
        // For now, we'll need to check the journey's progress
        // Since we don't store target completion in the journey, we'll use a different approach
        // We'll check if there's an active LocationTrackingManager with this plan
        // For simplicity, we'll check the journey's start date and assume targets before current are completed
        
        // This is a simplified approach - in a real implementation, you'd track completed targets
        // For now, we'll just mark that there's an active journey
        await MainActor.run {
            // We'll need to get the current target index from somewhere
            // For now, we'll leave this empty and implement proper tracking later
            completedTargetIndices = []
        }
    }
    
    private func addNewTarget() {
        guard let realm = try? Realm(),
              let livePlan = plan.thaw() else { return }
        
        let newTarget = ExposureTarget()
        newTarget.planId = plan.id
        newTarget.name = "New Target"
        
        // Use current location if available, otherwise default to 0.0
        if let currentLocation = locationManager.currentLocation {
            newTarget.latitude = currentLocation.coordinate.latitude
            newTarget.longitude = currentLocation.coordinate.longitude
        } else {
            newTarget.latitude = 0.0
            newTarget.longitude = 0.0
        }
        
        newTarget.waitTimeInSeconds = 120 // Default 2 minutes
        newTarget.orderIndex = targets.count
        newTarget.createdAt = Date()
        newTarget.updatedAt = Date()
        newTarget.needsSync = true
        
        try! realm.write {
            livePlan.targets.append(newTarget)
        }
        
        // Refresh targets array from Realm
        targets = Array(plan.targets.filter { !$0.isDeleted }).sorted(by: { $0.orderIndex < $1.orderIndex })
        
        // Open location search for the new target
        editingTargetIndex = targets.count - 1
        showLocationSearch = true
    }
    
    private func updateTargetLocation(at index: Int, name: String, coordinate: CLLocationCoordinate2D) {
        guard index < targets.count,
              let realm = try? Realm(),
              let liveTarget = targets[index].thaw() else {
            print("⚠️ Failed to update target location at index \(index)")
            return
        }
        
        print("💾 Saving location for target \(index): \(name) at \(coordinate.latitude), \(coordinate.longitude)")
        
        try! realm.write {
            liveTarget.name = name
            liveTarget.latitude = coordinate.latitude
            liveTarget.longitude = coordinate.longitude
            liveTarget.updatedAt = Date()
            liveTarget.needsSync = true
        }
        
        // Refresh targets array from Realm
        targets = Array(plan.targets.filter { !$0.isDeleted }).sorted(by: { $0.orderIndex < $1.orderIndex })
        
        // Verify the save
        if let savedTarget = realm.object(ofType: ExposureTarget.self, forPrimaryKey: liveTarget.id) {
            print("✅ Verified saved: \(savedTarget.name) at \(savedTarget.latitude), \(savedTarget.longitude)")
        }
    }
    
    private func deleteTarget(at index: Int) {
        guard index < targets.count,
              let realm = try? Realm(),
              let liveTarget = targets[index].thaw() else { return }
        
        try! realm.write {
            liveTarget.isDeleted = true
            liveTarget.updatedAt = Date()
            liveTarget.needsSync = true
        }
        
        // Reorder remaining targets
        updateTargets()
        reorderTargets()
    }
    
    private func moveTargets(from source: IndexSet, to destination: Int) {
        targets.move(fromOffsets: source, toOffset: destination)
        reorderTargets()
    }
    
    private func reorderTargets() {
        guard let realm = try? Realm() else { return }
        
        for (index, target) in targets.enumerated() {
            if let liveTarget = target.thaw() {
                try! realm.write {
                    liveTarget.orderIndex = index
                    liveTarget.updatedAt = Date()
                    liveTarget.needsSync = true
                }
            }
        }
        
        updateTargets()
    }
    
    private func updateTargets() {
        // Refresh targets from Realm
        targets = Array(plan.targets.filter { !$0.isDeleted }).sorted(by: { $0.orderIndex < $1.orderIndex })
    }
    
    private func handleCancel() {
        // If plan has no name and no targets, delete it (it's a new unsaved plan)
        if planName.isEmpty && targets.isEmpty {
            guard let realm = try? Realm(),
                  let livePlan = plan.thaw() else {
                dismiss()
                return
            }
            
            try! realm.write {
                realm.delete(livePlan)
            }
        }
        
        dismiss()
    }
    
    private func savePlan() {
        guard !planName.isEmpty else { return }
        guard let realm = try? Realm(),
              let livePlan = plan.thaw() else { return }
        
        try! realm.write {
            livePlan.name = planName
            livePlan.updatedAt = Date()
            livePlan.needsSync = true
            livePlan.isSynced = false
            
            // Ensure createdAt is set if it's a new plan
            if livePlan.createdAt == Date(timeIntervalSince1970: 0) {
                livePlan.createdAt = Date()
            }
        }
        
        dismiss()
    }
    
    private func startPlan() {
        guard let realm = try? Realm() else { return }
        
        // Create a new journey with this plan
        let newJourney = Journey()
        newJourney.type = .None
        newJourney.startDate = Date()
        newJourney.current = true
        newJourney.isCompleted = false
        newJourney.linkedPlanId = plan.id
        newJourney.needsSync = true
        
        realm.saveJourney(newJourney, needsSync: true)
        
        // Dismiss this view and show tracking view
        dismiss()
        showTrackingView = true
    }
    
    private func autogeneratePlan() async {
        await MainActor.run {
            isGeneratingPlan = true
        }
        
        defer {
            Task { @MainActor in
                isGeneratingPlan = false
            }
        }
        
        // Wait for location if not available
        if locationManager.currentLocation == nil {
            locationManager.requestLocation()
            // Wait a bit for location to be available
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        }
        
        guard let currentLocation = locationManager.currentLocation else {
            await MainActor.run {
                // Show error or request location again
                locationManager.requestLocation()
            }
            return
        }
        
        // Get Realm and thaw plan on main actor
        let realm = await MainActor.run {
            try? Realm()
        }
        guard let realm = realm else { return }
        
        let livePlan = await MainActor.run {
            plan.thaw()
        }
        guard let livePlan = livePlan else { return }
        
        // Clear existing targets
        await MainActor.run {
            try! realm.write {
                for target in livePlan.targets {
                    target.isDeleted = true
                    target.updatedAt = Date()
                    target.needsSync = true
                }
            }
        }
        
        // Search for nearby points of interest (POIs), shops, cafes, etc.
        // This creates a hierarchical progression using actual locations
        let coordinate = currentLocation.coordinate
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) // ~5km radius
        )
        
        // Search for various types of places - actual POIs, shops, cafes, etc.
        let searchCategories = [
            "shop",
            "convenience store",
            "cafe",
            "restaurant",
            "pharmacy",
            "post office",
            "park",
            "library"
        ]
        
        var allPlaces: [(name: String, coordinate: CLLocationCoordinate2D, distance: CLLocationDistance)] = []
        
        // Search for each category with async/await
        await withTaskGroup(of: [(name: String, coordinate: CLLocationCoordinate2D, distance: CLLocationDistance)].self) { group in
            for category in searchCategories {
                group.addTask {
                    await self.searchForPlaces(category: category, region: region, currentLocation: currentLocation)
                }
            }
            
            for await places in group {
                allPlaces.append(contentsOf: places)
            }
        }
        
        // Remove duplicates (same coordinate)
        var uniquePlaces: [(name: String, coordinate: CLLocationCoordinate2D, distance: CLLocationDistance)] = []
        var seenCoordinates: Set<String> = []
        
        for place in allPlaces {
            let coordKey = "\(place.coordinate.latitude),\(place.coordinate.longitude)"
            if !seenCoordinates.contains(coordKey) {
                seenCoordinates.insert(coordKey)
                uniquePlaces.append(place)
            }
        }
        
        // Sort by distance to create hierarchical progression (closest first)
        uniquePlaces.sort { $0.distance < $1.distance }
        
        // Select 5-8 places at increasing distances for hierarchical progression
        // Filter to ensure we have a good range: start close (50m+) and go up to 1km
        let filteredPlaces = uniquePlaces.filter { $0.distance >= 50 && $0.distance <= 1000 }
        let targetCount = min(8, filteredPlaces.count)
        let selectedPlaces = Array(filteredPlaces.prefix(targetCount))
        
        // If we don't have enough places, use fallback
        if selectedPlaces.isEmpty {
            await createFallbackPlan(currentLocation: currentLocation, realm: realm, livePlan: livePlan)
            return
        }
        
        // Create targets for each selected place
        let baseWaitTime: Int = 30 // Start with 30 seconds
        
        await MainActor.run {
            for (targetIndex, place) in selectedPlaces.enumerated() {
                let newTarget = ExposureTarget()
                newTarget.planId = plan.id
                newTarget.latitude = place.coordinate.latitude
                newTarget.longitude = place.coordinate.longitude
                newTarget.waitTimeInSeconds = baseWaitTime + (targetIndex * 15) // Progressive: 30s, 45s, 1m, 1m15s, etc.
                newTarget.orderIndex = targetIndex
                newTarget.createdAt = Date()
                newTarget.updatedAt = Date()
                newTarget.needsSync = true
                newTarget.name = place.name
                
                try! realm.write {
                    livePlan.targets.append(newTarget)
                }
            }
        }
        
        // Update targets list
        await MainActor.run {
            updateTargets()
            
            // Set a default plan name if empty
            if planName.isEmpty {
                planName = "Auto-Generated Plan"
            }
            
            // Save the plan name
            try! realm.write {
                livePlan.name = planName
                livePlan.updatedAt = Date()
                livePlan.needsSync = true
            }
        }
    }
    
    private func calculateDestination(from start: CLLocationCoordinate2D, distance: CLLocationDistance, bearing: Double) -> CLLocationCoordinate2D {
        let earthRadius: Double = 6371000 // meters
        let lat1 = start.latitude * .pi / 180
        let lon1 = start.longitude * .pi / 180
        let bearingRad = bearing * .pi / 180
        
        let lat2 = asin(sin(lat1) * cos(distance / earthRadius) +
                       cos(lat1) * sin(distance / earthRadius) * cos(bearingRad))
        let lon2 = lon1 + atan2(sin(bearingRad) * sin(distance / earthRadius) * cos(lat1),
                                cos(distance / earthRadius) - sin(lat1) * sin(lat2))
        
        return CLLocationCoordinate2D(latitude: lat2 * 180 / .pi, longitude: lon2 * 180 / .pi)
    }
    
    private func searchForPlaces(category: String, region: MKCoordinateRegion, currentLocation: CLLocation) async -> [(name: String, coordinate: CLLocationCoordinate2D, distance: CLLocationDistance)] {
        return await withCheckedContinuation { continuation in
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = category
            request.region = region
            request.resultTypes = [.pointOfInterest, .address] // Include both POIs and addresses
            
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                var places: [(name: String, coordinate: CLLocationCoordinate2D, distance: CLLocationDistance)] = []
                
                if let response = response {
                    for item in response.mapItems {
                        let placeLocation = CLLocation(
                            latitude: item.placemark.coordinate.latitude,
                            longitude: item.placemark.coordinate.longitude
                        )
                        let distance = currentLocation.distance(from: placeLocation)
                        
                        // Only include places within reasonable walking distance (50m to 1km for hierarchical progression)
                        if distance >= 50 && distance <= 1000 {
                            // Prefer the business name, fall back to placemark name, then address
                            let name: String
                            if let businessName = item.name, !businessName.isEmpty {
                                name = businessName
                            } else if let placemarkName = item.placemark.name, !placemarkName.isEmpty {
                                name = placemarkName
                            } else if let street = item.placemark.thoroughfare, !street.isEmpty {
                                name = street
                            } else {
                                name = "Location"
                            }
                            places.append((name: name, coordinate: item.placemark.coordinate, distance: distance))
                        }
                    }
                }
                
                continuation.resume(returning: places)
            }
        }
    }
    
    private func createFallbackPlan(currentLocation: CLLocation, realm: Realm, livePlan: ExposurePlan) async {
        // Fallback: search for "nearby" places with a broader query
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "nearby"
        request.region = MKCoordinateRegion(
            center: currentLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02) // ~2km radius
        )
        request.resultTypes = [.pointOfInterest]
        
        let places = await withCheckedContinuation { continuation in
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                var foundPlaces: [(name: String, coordinate: CLLocationCoordinate2D, distance: CLLocationDistance)] = []
                
                if let response = response, !response.mapItems.isEmpty {
                    for item in response.mapItems.prefix(5) {
                        let placeLocation = CLLocation(
                            latitude: item.placemark.coordinate.latitude,
                            longitude: item.placemark.coordinate.longitude
                        )
                        let distance = currentLocation.distance(from: placeLocation)
                        
                        // Only include if within reasonable distance
                        if distance >= 50 && distance <= 2000 {
                            let name = item.name ?? item.placemark.name ?? "Location"
                            foundPlaces.append((name: name, coordinate: item.placemark.coordinate, distance: distance))
                        }
                    }
                }
                
                continuation.resume(returning: foundPlaces)
            }
        }
        
        if places.isEmpty {
            // If still no results, create a simple plan with street intersections
            await createStreetBasedPlan(currentLocation: currentLocation, realm: realm, livePlan: livePlan)
            return
        }
        
        let baseWaitTime: Int = 60
        
        for (targetIndex, place) in places.enumerated() {
            let newTarget = ExposureTarget()
            newTarget.planId = plan.id
            newTarget.latitude = place.coordinate.latitude
            newTarget.longitude = place.coordinate.longitude
            newTarget.waitTimeInSeconds = baseWaitTime + (targetIndex * 30)
            newTarget.orderIndex = targetIndex
            newTarget.createdAt = Date()
            newTarget.updatedAt = Date()
            newTarget.needsSync = true
            newTarget.name = place.name
            
            try! realm.write {
                livePlan.targets.append(newTarget)
            }
        }
        
        await MainActor.run {
            updateTargets()
            
            if planName.isEmpty {
                planName = "Auto-Generated Plan"
            }
            
            try! realm.write {
                livePlan.name = planName
                livePlan.updatedAt = Date()
                livePlan.needsSync = true
            }
        }
    }
    
    private func createStreetBasedPlan(currentLocation: CLLocation, realm: Realm, livePlan: ExposurePlan) async {
        // Last resort: use reverse geocoding to find nearby streets
        let placemark = await withCheckedContinuation { continuation in
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(currentLocation) { placemarks, error in
                continuation.resume(returning: placemarks?.first)
            }
        }
        
        guard let placemark = placemark, let street = placemark.thoroughfare else { return }
        
        // Search for places on the same street or nearby streets
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = street
        request.region = MKCoordinateRegion(
            center: currentLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        let places = await withCheckedContinuation { continuation in
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                var foundPlaces: [(name: String, coordinate: CLLocationCoordinate2D, distance: CLLocationDistance)] = []
                
                if let response = response {
                    for item in response.mapItems.prefix(5) {
                        let placeLocation = CLLocation(
                            latitude: item.placemark.coordinate.latitude,
                            longitude: item.placemark.coordinate.longitude
                        )
                        let distance = currentLocation.distance(from: placeLocation)
                        
                        if distance >= 50 && distance <= 2000 {
                            let name = item.name ?? item.placemark.name ?? "\(street) Location"
                            foundPlaces.append((name: name, coordinate: item.placemark.coordinate, distance: distance))
                        }
                    }
                }
                
                continuation.resume(returning: foundPlaces)
            }
        }
        
        let baseWaitTime: Int = 60
        
        for (targetIndex, place) in places.enumerated() {
            let newTarget = ExposureTarget()
            newTarget.planId = plan.id
            newTarget.latitude = place.coordinate.latitude
            newTarget.longitude = place.coordinate.longitude
            newTarget.waitTimeInSeconds = baseWaitTime + (targetIndex * 30)
            newTarget.orderIndex = targetIndex
            newTarget.createdAt = Date()
            newTarget.updatedAt = Date()
            newTarget.needsSync = true
            newTarget.name = place.name
            
            try! realm.write {
                livePlan.targets.append(newTarget)
            }
        }
        
        await MainActor.run {
            updateTargets()
            
            if planName.isEmpty {
                planName = "Auto-Generated Plan"
            }
            
            try! realm.write {
                livePlan.name = planName
                livePlan.updatedAt = Date()
                livePlan.needsSync = true
            }
        }
    }
    
    // MARK: - Plan Progress
    
    private func loadPlanProgress() {
        guard let realm = try? Realm() else { return }
        
        // Find all journeys linked to this plan
        let linkedJourneys = realm.objects(Journey.self)
            .filter("linkedPlanId == %@ AND isDeleted == false", plan.id)
            .sorted(byKeyPath: "startDate", ascending: false)
        
        guard !linkedJourneys.isEmpty else {
            planProgress = nil
            return
        }
        
        let totalAttempts = linkedJourneys.count
        var completedAttempts = 0
        var totalTargetsReached = 0
        var bestTargetsReached = 0
        
        // Get JourneyRealm objects to analyze target completions
        for journeyMeta in linkedJourneys {
            if journeyMeta.isCompleted {
                completedAttempts += 1
            }
            
            // Try to find the corresponding JourneyRealm
            if let journeyRealm = realm.object(ofType: JourneyRealm.self, forPrimaryKey: journeyMeta.id.uuidString) {
                // Analyze target completions for this journey
                let targetsReached = analyzeTargetCompletionsForJourney(journeyRealm: journeyRealm, plan: plan)
                totalTargetsReached += targetsReached
                bestTargetsReached = max(bestTargetsReached, targetsReached)
            }
        }
        
        let averageTargetsReached = totalAttempts > 0 ? Double(totalTargetsReached) / Double(totalAttempts) : 0.0
        let lastAttemptDate = linkedJourneys.first?.startDate
        
        planProgress = PlanProgress(
            totalAttempts: totalAttempts,
            completedAttempts: completedAttempts,
            averageTargetsReached: averageTargetsReached,
            bestTargetsReached: bestTargetsReached,
            lastAttemptDate: lastAttemptDate
        )
    }
    
    private func analyzeTargetCompletionsForJourney(journeyRealm: JourneyRealm, plan: ExposurePlan) -> Int {
        let targets = plan.targets.filter { !$0.isDeleted }.sorted(by: { $0.orderIndex < $1.orderIndex })
        guard !targets.isEmpty else { return 0 }
        
        // Convert journey path points to CLLocation array
        let pathLocations = journeyRealm.pathPoints.map { point in
            CLLocation(latitude: point.latitude, longitude: point.longitude)
        }
        
        var targetsReached = 0
        
        for target in targets {
            let targetLocation = CLLocation(latitude: target.latitude, longitude: target.longitude)
            
            // Check if any path point is within 30m of target
            for pathLocation in pathLocations {
                if targetLocation.distance(from: pathLocation) <= 30.0 {
                    targetsReached += 1
                    break
                }
            }
        }
        
        return targetsReached
    }
    
    private var planProgressSection: some View {
        Group {
            if let progress = planProgress {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Plan Progress")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    
                    // Progress stats cards
                    HStack(spacing: 12) {
                        progressStatCard(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Attempts",
                            value: "\(progress.totalAttempts)",
                            color: AppConstants.primaryColor
                        )
                        
                        progressStatCard(
                            icon: "checkmark.circle.fill",
                            title: "Completed",
                            value: "\(progress.completedAttempts)",
                            color: .green
                        )
                        
                        progressStatCard(
                            icon: "star.fill",
                            title: "Best",
                            value: "\(progress.bestTargetsReached)/\(plan.targets.filter { !$0.isDeleted }.count)",
                            color: .orange
                        )
                    }
                    
                    // Average progress
                    if progress.totalAttempts > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Average Targets Reached")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                                
                                Spacer()
                                
                                Text(String(format: "%.1f", progress.averageTargetsReached))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                            }
                            
                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.2))
                                        .frame(height: 8)
                                        .cornerRadius(4)
                                    
                                    Rectangle()
                                        .fill(AppConstants.primaryColor)
                                        .frame(width: geometry.size.width * CGFloat(progress.averageTargetsReached / Double(max(1, plan.targets.filter { !$0.isDeleted }.count))), height: 8)
                                        .cornerRadius(4)
                                }
                            }
                            .frame(height: 8)
                        }
                        .padding(16)
                        .background(AppConstants.cardBackgroundColor(for: colorScheme))
                        .cornerRadius(16)
                        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 3)
                    }
                    
                    // Last attempt
                    if let lastAttempt = progress.lastAttemptDate {
                        HStack {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            
                            Text("Last attempt: \(lastAttempt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.system(size: 14))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(16)
                .background(AppConstants.cardBackgroundColor(for: colorScheme))
                .cornerRadius(16)
                .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 3)
            }
        }
    }
    
    private func progressStatCard(icon: String, title: String, value: String, color: Color) -> some View {
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
}

// MARK: - Target Row View

struct TargetRowView: View {
    @Environment(\.colorScheme) var colorScheme
    let target: ExposureTarget
    let index: Int
    let isLocked: Bool
    let onLocationTap: () -> Void
    let onWaitTimeChange: (Int) -> Void
    let onDelete: () -> Void
    let startLocation: CLLocation?
    
    @State private var waitTimeMinutes: Int = 0
    @State private var waitTimeSeconds: Int = 0
    @AppStorage("setting.miles") private var enableMiles = false
    
    var body: some View {
        Card(backgroundColor: AppConstants.cardBackgroundColor(for: colorScheme)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Target number badge
                    ZStack {
                        Circle()
                            .fill(AppConstants.primaryColor.opacity(0.15))
                            .frame(width: 32, height: 32)
                        
                        Text("\(index + 1)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppConstants.primaryColor)
                    }
                    
                    // Location
                    Button(action: {
                        if !isLocked {
                            onLocationTap()
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(target.name.isEmpty ? "Tap to set location" : target.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(target.name.isEmpty ? AppConstants.secondaryTextColor(for: colorScheme) : AppConstants.primaryTextColor(for: colorScheme))
                                .lineLimit(1)
                            
                            // Show distance from start or previous target
                            if let distance = calculateDistance() {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 10))
                                    Text(formatDistance(distance))
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(AppConstants.primaryColor)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isLocked)
                    
                    Spacer()
                    
                    if !isLocked {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.system(size: 16))
                        }
                    }
                }
                
                // Wait Time
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    
                    Text("Wait Time:")
                        .font(.system(size: 14))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    
                    if isLocked {
                        Text(beatphobia.formatWaitTimeShort(target.waitTimeInSeconds))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    } else {
                        HStack(spacing: 8) {
                            Picker("Minutes", selection: $waitTimeMinutes) {
                                ForEach(0..<60) { minute in
                                    Text("\(minute)m").tag(minute)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: waitTimeMinutes) { oldValue, newValue in
                                updateWaitTime()
                            }
                            
                            Picker("Seconds", selection: $waitTimeSeconds) {
                                ForEach(0..<60) { second in
                                    Text("\(second)s").tag(second)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: waitTimeSeconds) { oldValue, newValue in
                                updateWaitTime()
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            waitTimeMinutes = target.waitTimeInSeconds / 60
            waitTimeSeconds = target.waitTimeInSeconds % 60
        }
    }
    
    private func updateWaitTime() {
        let totalSeconds = waitTimeMinutes * 60 + waitTimeSeconds
        onWaitTimeChange(totalSeconds)
    }
    
    private func calculateDistance() -> CLLocationDistance? {
        let targetLocation = CLLocation(latitude: target.latitude, longitude: target.longitude)
        
        // Always show distance from START LOCATION (current location)
        if let start = startLocation {
            return start.distance(from: targetLocation)
        }
        
        return nil
    }
    
    private func formatDistance(_ meters: CLLocationDistance) -> String {
        if enableMiles {
            if meters < 160.934 { // Less than 0.1 miles
                let feet = meters * 3.28084
                return String(format: "%.0f ft", feet)
            } else {
                let miles = meters / 1609.34
                return String(format: "%.2f mi", miles)
            }
        } else {
            if meters < 100 {
                return String(format: "%.0f m", meters)
            } else {
                let km = meters / 1000.0
                return String(format: "%.2f km", km)
            }
        }
    }
}

// MARK: - Map Preview View

struct MapPreviewView: UIViewRepresentable {
    let targets: [ExposureTarget]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Remove existing overlays and annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        guard !targets.isEmpty else { return }
        
        // Add annotations for each target
        var coordinates: [CLLocationCoordinate2D] = []
        for (index, target) in targets.enumerated() {
            let coordinate = CLLocationCoordinate2D(latitude: target.latitude, longitude: target.longitude)
            coordinates.append(coordinate)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "\(index + 1). \(target.name)"
            mapView.addAnnotation(annotation)
        }
        
        // Calculate route if we have multiple targets
        if targets.count > 1 {
            calculateRoute(for: mapView, coordinates: coordinates)
        } else {
            // Just center on the single target
            let region = MKCoordinateRegion(
                center: coordinates[0],
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            mapView.setRegion(region, animated: false)
        }
    }
    
    private func calculateRoute(for mapView: MKMapView, coordinates: [CLLocationCoordinate2D]) {
        guard coordinates.count > 1 else { return }
        
        // Create waypoints
        var waypoints: [MKMapItem] = []
        for coordinate in coordinates {
            let placemark = MKPlacemark(coordinate: coordinate)
            waypoints.append(MKMapItem(placemark: placemark))
        }
        
        // Calculate route between consecutive waypoints
        var allCoordinates: [CLLocationCoordinate2D] = []
        
        for i in 0..<(waypoints.count - 1) {
            let request = MKDirections.Request()
            request.source = waypoints[i]
            request.destination = waypoints[i + 1]
            request.transportType = .walking
            
            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                guard let route = response?.routes.first else { return }
                
                // Add route polyline
                mapView.addOverlay(route.polyline)
                
                // Collect coordinates for bounding box
                let routeCoordinates = route.polyline.coordinates
                allCoordinates.append(contentsOf: routeCoordinates)
                
                // Update map region if this is the last route
                if i == waypoints.count - 2 {
                    updateMapRegion(for: mapView, with: allCoordinates + coordinates)
                }
            }
        }
        
        // If only one segment, update region immediately
        if waypoints.count == 2 {
            updateMapRegion(for: mapView, with: coordinates)
        }
    }
    
    private func updateMapRegion(for mapView: MKMapView, with coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else { return }
        
        let minLat = coordinates.map { $0.latitude }.min()!
        let maxLat = coordinates.map { $0.latitude }.max()!
        let minLon = coordinates.map { $0.longitude }.min()!
        let maxLon = coordinates.map { $0.longitude }.max()!
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2.0,
            longitude: (minLon + maxLon) / 2.0
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.3, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.3, 0.01)
        )
        
        mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: false)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(AppConstants.primaryColor)
                renderer.lineWidth = 3.0
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords: [CLLocationCoordinate2D] = []
        let pointCount = pointCount
        for i in 0..<pointCount {
            coords.append(points()[i].coordinate)
        }
        return coords
    }
}

// MARK: - Current Location Manager

class CurrentLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentLocation: CLLocation?
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            DispatchQueue.main.async {
                self.currentLocation = location
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
}


// MARK: - Plan Progress Model
struct PlanProgress {
    let totalAttempts: Int
    let completedAttempts: Int
    let averageTargetsReached: Double
    let bestTargetsReached: Int
    let lastAttemptDate: Date?
}

