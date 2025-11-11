//
//  LocationSearchView.swift
//  beatphobia
//
//  Created for Guided Exposure Plans feature
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct LocationSearchResult: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

struct IdentifiableSearchCompletion: Identifiable {
    let id = UUID()
    let completion: MKLocalSearchCompletion
}

struct LocationSearchView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var searchText: String = ""
    @State private var searchResults: [MKLocalSearchCompletion] = []
    @State private var selectedResult: LocationSearchResult?
    @State private var isSearchMode: Bool = true
    @State private var mapCoordinate: CLLocationCoordinate2D?
    @State private var mapLocationName: String = ""
    @State private var isGeocoding: Bool = false
    @State private var hasUserSelectedLocation: Bool = false
    @State private var confirmedCoordinate: CLLocationCoordinate2D?
    
    let onLocationSelected: (String, CLLocationCoordinate2D) -> Void
    let initialCoordinate: CLLocationCoordinate2D?
    
    @StateObject private var searchCompleter = LocationSearchCompleter()
    @StateObject private var locationManager = CurrentLocationManager()
    
    init(onLocationSelected: @escaping (String, CLLocationCoordinate2D) -> Void, initialCoordinate: CLLocationCoordinate2D? = nil) {
        self.onLocationSelected = onLocationSelected
        self.initialCoordinate = initialCoordinate
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.backgroundColor(for: colorScheme)
                    .ignoresSafeArea()
                
                if isSearchMode {
                    searchModeView
                } else {
                    mapModeView
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isSearchMode ? "Map" : "Search") {
                        let wasSearchMode = isSearchMode
                        withAnimation {
                            isSearchMode.toggle()
                        }
                        // When switching to map mode, center on current location if no coordinate is set
                        if wasSearchMode && mapCoordinate == nil {
                            // Now in map mode, set initial coordinate
                            if let initial = initialCoordinate {
                                mapCoordinate = initial
                            } else if let currentLocation = locationManager.currentLocation {
                                mapCoordinate = currentLocation.coordinate
                                // Reverse geocode to get location name
                                let geocoder = CLGeocoder()
                                geocoder.reverseGeocodeLocation(currentLocation) { placemarks, error in
                                    if let placemark = placemarks?.first {
                                        DispatchQueue.main.async {
                                            mapLocationName = placemark.name ?? placemark.thoroughfare ?? "Current Location"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Search Mode View
    
    private var searchModeView: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                
                TextField("Search for a location", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: searchText) { oldValue, newValue in
                        searchCompleter.queryFragment = newValue
                    }
            }
            .padding(12)
            .background(AppConstants.cardBackgroundColor(for: colorScheme))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Search Results
            if searchText.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.5))
                    
                    Text("Search for a location")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchCompleter.completions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "location.slash")
                        .font(.system(size: 48))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.5))
                    
                    Text("No results found")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(searchCompleter.identifiableCompletions) { identifiableCompletion in
                        Button(action: {
                            selectSearchResult(identifiableCompletion.completion)
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(AppConstants.primaryColor)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(identifiableCompletion.completion.title)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                    
                                    if !identifiableCompletion.completion.subtitle.isEmpty {
                                        Text(identifiableCompletion.completion.subtitle)
                                            .font(.system(size: 14))
                                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    // MARK: - Map Mode View
    
    private var mapModeView: some View {
        VStack(spacing: 0) {
            // Map
            MapViewWithPin(
                coordinate: $mapCoordinate,
                locationName: $mapLocationName,
                isGeocoding: $isGeocoding,
                hasUserSelectedLocation: $hasUserSelectedLocation,
                confirmedCoordinate: $confirmedCoordinate,
                initialCoordinate: initialCoordinate,
                currentLocation: locationManager.currentLocation
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: hasUserSelectedLocation) { oldValue, newValue in
                // Track when user manually selects a location
                if newValue && !oldValue {
                    print("📍 User has manually selected a location")
                }
            }
            .onAppear {
                // Request location when view appears
                locationManager.requestLocation()
            }
            
            // Location Info and Confirm Button
            VStack(spacing: 12) {
                if isGeocoding {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Finding location...")
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    }
                } else if let coordinate = mapCoordinate, !mapLocationName.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(AppConstants.primaryColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mapLocationName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                            
                            Text(String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude))
                                .font(.system(size: 12))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(AppConstants.cardBackgroundColor(for: colorScheme))
                    .cornerRadius(12)
                }
                
                Button(action: {
                    // Use confirmedCoordinate if available, otherwise use mapCoordinate
                    // This ensures we use the coordinate the user actually selected
                    let coordinateToUse: CLLocationCoordinate2D?
                    
                    if let confirmed = confirmedCoordinate {
                        coordinateToUse = confirmed
                    } else if hasUserSelectedLocation, let mapCoord = mapCoordinate {
                        coordinateToUse = mapCoord
                    } else if let mapCoord = mapCoordinate {
                        // Fallback to mapCoordinate, but warn
                        print("⚠️ Using mapCoordinate without user selection confirmation")
                        coordinateToUse = mapCoord
                    } else {
                        print("⚠️ Cannot confirm: no coordinate available")
                        return
                    }
                    
                    guard let coordinate = coordinateToUse, !mapLocationName.isEmpty else {
                        print("⚠️ Cannot confirm: coordinate=\(String(describing: coordinateToUse)), name=\(mapLocationName)")
                        return
                    }
                    
                    // Double-check that we're using the selected coordinate
                    print("📍 Confirming location: \(mapLocationName) at \(coordinate.latitude), \(coordinate.longitude)")
                    onLocationSelected(mapLocationName, coordinate)
                    dismiss()
                }) {
                    Text("Confirm Location")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            mapCoordinate != nil && !mapLocationName.isEmpty
                                ? LinearGradient(
                                    colors: [AppConstants.primaryColor, AppConstants.primaryColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .cornerRadius(12)
                }
                .disabled(mapCoordinate == nil || mapLocationName.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(AppConstants.backgroundColor(for: colorScheme))
        }
    }
    
    // MARK: - Helper Methods
    
    private func selectSearchResult(_ completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        
        search.start { response, error in
            guard let response = response, let item = response.mapItems.first else {
                return
            }
            
            let coordinate = item.placemark.coordinate
            let name = item.name ?? completion.title
            
            DispatchQueue.main.async {
                onLocationSelected(name, coordinate)
                dismiss()
            }
        }
    }
}

// MARK: - Location Search Completer

class LocationSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var completions: [MKLocalSearchCompletion] = []
    
    var identifiableCompletions: [IdentifiableSearchCompletion] {
        completions.map { IdentifiableSearchCompletion(completion: $0) }
    }
    
    private let completer = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }
    
    var queryFragment: String = "" {
        didSet {
            completer.queryFragment = queryFragment
        }
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async { [weak self] in
            self?.completions = completer.results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error.localizedDescription)")
    }
}

// MARK: - Map View with Pin

struct MapViewWithPin: UIViewRepresentable {
    @Binding var coordinate: CLLocationCoordinate2D?
    @Binding var locationName: String
    @Binding var isGeocoding: Bool
    @Binding var hasUserSelectedLocation: Bool
    @Binding var confirmedCoordinate: CLLocationCoordinate2D?
    var initialCoordinate: CLLocationCoordinate2D?
    var currentLocation: CLLocation?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        
        // Center on initial coordinate if provided, otherwise use current location
        let centerCoordinate: CLLocationCoordinate2D
        if let initial = initialCoordinate {
            centerCoordinate = initial
        } else if let current = currentLocation {
            centerCoordinate = current.coordinate
        } else if let userLocation = mapView.userLocation.location {
            centerCoordinate = userLocation.coordinate
        } else {
            // Default to a reasonable location (can be adjusted)
            centerCoordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
        
        let region = MKCoordinateRegion(
            center: centerCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        mapView.setRegion(region, animated: false)
        
        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update annotation if coordinate changes (but don't override if user manually selected)
        if let coordinate = coordinate {
            // Remove existing annotations (except user location)
            let existingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
            mapView.removeAnnotations(existingAnnotations)
            
            // Add new annotation
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
            
            // Only center map if this is a manual selection or initial setup
            if context.coordinator.hasManuallySelectedLocation || !context.coordinator.initialLocationSet {
                let region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
                mapView.setRegion(region, animated: true)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWithPin
        private let geocoder = CLGeocoder()
        var hasManuallySelectedLocation = false
        var initialLocationSet = false
        
        init(_ parent: MapViewWithPin) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            // Completely ignore user location updates if user has manually selected a location
            // This prevents any possibility of overriding the selected coordinate
            guard !hasManuallySelectedLocation && !parent.hasUserSelectedLocation && parent.confirmedCoordinate == nil else {
                // User has selected a location, stop listening to user location updates
                return
            }
            
            // Only set to user location initially if no coordinate has been manually selected
            if !initialLocationSet, let location = userLocation.location {
                // Only set initial location once, and only if user hasn't selected one
                DispatchQueue.main.async {
                    if !self.hasManuallySelectedLocation && !self.initialLocationSet && !self.parent.hasUserSelectedLocation && self.parent.confirmedCoordinate == nil {
                        self.parent.coordinate = location.coordinate
                        self.reverseGeocode(coordinate: location.coordinate)
                        self.initialLocationSet = true
                    }
                }
            }
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let mapView = gesture.view as! MKMapView
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            
            // Mark that user has manually selected a location
            hasManuallySelectedLocation = true
            
            DispatchQueue.main.async {
                self.parent.hasUserSelectedLocation = true
                self.parent.coordinate = coordinate
                // Store the confirmed coordinate immediately when user taps
                self.parent.confirmedCoordinate = coordinate
                print("📍 User tapped map: setting coordinate to \(coordinate.latitude), \(coordinate.longitude)")
                self.reverseGeocode(coordinate: coordinate)
            }
        }
        
        private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
            parent.isGeocoding = true
            
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.parent.isGeocoding = false
                    
                    if let error = error {
                        print("Geocoding error: \(error.localizedDescription)")
                        self.parent.locationName = "Unknown Location"
                        return
                    }
                    
                    if let placemark = placemarks?.first {
                        // Build location name from placemark
                        var nameComponents: [String] = []
                        
                        if let name = placemark.name {
                            nameComponents.append(name)
                        }
                        if let thoroughfare = placemark.thoroughfare, nameComponents.isEmpty {
                            nameComponents.append(thoroughfare)
                        }
                        if let locality = placemark.locality {
                            if !nameComponents.contains(locality) {
                                nameComponents.append(locality)
                            }
                        }
                        
                        self.parent.locationName = nameComponents.isEmpty
                            ? "Unknown Location"
                            : nameComponents.joined(separator: ", ")
                    } else {
                        self.parent.locationName = "Unknown Location"
                    }
                }
            }
        }
    }
}

