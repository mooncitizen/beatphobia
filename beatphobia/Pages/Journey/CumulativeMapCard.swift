//
//  CumulativeMapCard.swift
//  beatphobia
//
//  Created for cumulative journey visualization
//

import SwiftUI
import MapKit
import CoreLocation
import RealmSwift

// MARK: - Data Models

struct HeatMapCell: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let bounds: MKMapRect
    let count: Int
    let normalizedIntensity: Double // 0.0 to 1.0
    var color: Color {
        if normalizedIntensity > 0.7 {
            return .red
        } else if normalizedIntensity > 0.4 {
            return .orange
        } else if normalizedIntensity > 0.2 {
            return .yellow
        } else {
            return .green
        }
    }
}

struct CumulativeStats {
    let totalJourneys: Int
    let totalDistance: Double
    let totalDuration: Int
    let furthestDistance: Double
    let safeAreaSize: Double
    let totalHesitations: Int
    let avgJourneyDuration: Int
    let anxietyFreePercentage: Double
}

struct HesitationCluster: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let count: Int
    let totalDuration: Double
}

struct MapLayerToggles {
    var showHeatMap: Bool = true
    var showBoundary: Bool = true
    var showLastWeekBoundary: Bool = true
    var showSafeArea: Bool = true
    var showPaths: Bool = true
    var showHesitations: Bool = true
    var showCheckpoints: Bool = false
}

// MARK: - Cumulative Map Card View

struct CumulativeMapCard: View {
    let journeys: [JourneyRealm]
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("setting.miles") private var enableMiles = false
    @State private var showLayerSheet = false
    @State private var layerToggles = MapLayerToggles()
    @State private var stats: CumulativeStats?
    @State private var heatMapCells: [HeatMapCell] = []
    @State private var boundaryPolygon: MKPolygon?
    @State private var lastWeekBoundaryPolygon: MKPolygon?
    @State private var safeAreaPolygon: MKPolygon?
    @State private var hesitationClusters: [HesitationCluster] = []
    @State private var furthestPoint: (coordinate: CLLocationCoordinate2D, distance: Double)?
    @State private var showFullScreenMap = false
    
    var body: some View {
        Button(action: {
            showFullScreenMap = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Icon
                HStack {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                    
                    Spacer()
                }
                
                // Total Distance Covered Value
                if let stats = stats {
                    Text(formatDistance(stats.totalDistance))
                        .font(.system(size: 28, weight: .bold))
                        .fontDesign(.rounded)
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                } else {
                    Text("--")
                        .font(.system(size: 28, weight: .bold))
                        .fontDesign(.rounded)
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                }
                
                // Title
                Text("Total Distance")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                
                // Subtitle
                Text("Tap to view map")
                    .font(.system(size: 11))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.8))
            }
            .padding(16)
            .frame(width: 140)
            .background(AppConstants.cardBackgroundColor(for: colorScheme))
            .cornerRadius(16)
            .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            calculateAllData()
        }
        .onChange(of: journeys.count) { _, _ in
            calculateAllData()
        }
        .fullScreenCover(isPresented: $showFullScreenMap) {
            FullScreenCumulativeMapView(
                journeys: journeys,
                stats: stats,
                heatMapCells: heatMapCells,
                boundaryPolygon: boundaryPolygon,
                lastWeekBoundaryPolygon: lastWeekBoundaryPolygon,
                safeAreaPolygon: safeAreaPolygon,
                hesitationClusters: hesitationClusters,
                layerToggles: $layerToggles,
                isPresented: $showFullScreenMap
            )
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatDistance(_ meters: Double) -> String {
        if enableMiles {
            let miles = meters / 1609.34
            return String(format: "%.1f mi", miles)
        } else {
            let km = meters / 1000.0
            return String(format: "%.1f km", km)
        }
    }
    
    // MARK: - Compact Stats Overlay (for thumbnail)
    
    private func compactStatsOverlay(stats: CumulativeStats) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Distance Covered")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                Text(formatDistance(stats.totalDistance))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.75))
                .blur(radius: 1)
        )
    }
    
    // MARK: - Stats Overlay (for full screen)
    
    private func statsOverlay(stats: CumulativeStats) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                statPill(icon: "map.fill", value: "\(stats.totalJourneys)", label: "Journeys")
                statPill(icon: "figure.walk", value: formatDistance(stats.totalDistance), label: "Distance")
                statPill(icon: "clock.fill", value: formatDuration(stats.totalDuration), label: "Time")
                
                if stats.furthestDistance > 0 {
                    statPill(icon: "arrow.up.right", value: formatDistance(stats.furthestDistance), label: "Max Range")
                }
                
                if stats.totalHesitations > 0 {
                    statPill(icon: "pause.circle.fill", value: "\(stats.totalHesitations)", label: "Hesitations")
                }
                
                if stats.anxietyFreePercentage > 0 {
                    statPill(icon: "heart.fill", value: String(format: "%.0f%%", stats.anxietyFreePercentage), label: "Anxiety Free")
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.7))
                .blur(radius: 1)
        )
    }
    
    private func statPill(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.8))
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Data Calculation
    
    private func calculateAllData() {
        guard !journeys.isEmpty else { return }
        
        // Extract all data from Realm objects on main thread first
        let extractedData = extractJourneyData(journeys: journeys)
        
        // Calculate stats (can use Realm objects since we're on main thread)
        stats = calculateCumulativeStats(journeys: journeys, extractedData: extractedData)
        
        // Calculate heat map (async for performance)
        DispatchQueue.global(qos: .userInitiated).async {
            let cells = self.calculateHeatMap(extractedData: extractedData)
            DispatchQueue.main.async {
                self.heatMapCells = cells
            }
        }
        
        // Calculate boundary (async for performance)
        DispatchQueue.global(qos: .userInitiated).async {
            let polygon = self.calculateBoundaryPolygon(extractedData: extractedData)
            DispatchQueue.main.async {
                self.boundaryPolygon = polygon
            }
        }
        
        // Calculate last week boundary (must be on main thread for Realm access)
        lastWeekBoundaryPolygon = calculateLastWeekBoundaryPolygon(journeys: journeys)
        
        // Calculate safe area (must be on main thread for Realm access)
        safeAreaPolygon = calculateSafeAreaOverlay()
        
        // Calculate hesitation clusters (async)
        DispatchQueue.global(qos: .userInitiated).async {
            let clusters = self.clusterHesitations(extractedData: extractedData)
            DispatchQueue.main.async {
                self.hesitationClusters = clusters
            }
        }
        
        // Calculate furthest point (async)
        DispatchQueue.global(qos: .userInitiated).async {
            let point = self.calculateFurthestPoint(extractedData: extractedData)
            DispatchQueue.main.async {
                self.furthestPoint = point
            }
        }
    }
    
    // MARK: - Data Extraction (must be called on main thread)
    
    private func extractJourneyData(journeys: [JourneyRealm]) -> ExtractedJourneyData {
        var allPathPoints: [(lat: Double, lon: Double)] = []
        var allHesitations: [(lat: Double, lon: Double, duration: Double)] = []
        var startPoints: [(lat: Double, lon: Double)] = []
        
        for journey in journeys {
            // Extract path points
            for point in journey.pathPoints {
                allPathPoints.append((lat: point.latitude, lon: point.longitude))
            }
            
            // Extract first point as start point
            if let firstPoint = journey.pathPoints.first {
                startPoints.append((lat: firstPoint.latitude, lon: firstPoint.longitude))
            }
            
            // Extract hesitation points
            for hesitation in journey.hesitationPoints {
                allHesitations.append((
                    lat: hesitation.latitude,
                    lon: hesitation.longitude,
                    duration: hesitation.duration
                ))
            }
        }
        
        return ExtractedJourneyData(
            pathPoints: allPathPoints,
            hesitationPoints: allHesitations,
            startPoints: startPoints
        )
    }
    
    // MARK: - Extracted Data Structure
    
    private struct ExtractedJourneyData {
        let pathPoints: [(lat: Double, lon: Double)]
        let hesitationPoints: [(lat: Double, lon: Double, duration: Double)]
        let startPoints: [(lat: Double, lon: Double)]
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        }
        return String(format: "%dm", minutes)
    }
    
    // MARK: - Data Processing Functions
    
    private func calculateCumulativeStats(journeys: [JourneyRealm], extractedData: ExtractedJourneyData) -> CumulativeStats {
        let totalJourneys = journeys.count
        let totalDistance = journeys.reduce(0.0) { $0 + $1.distance }
        let totalDuration = journeys.reduce(0) { $0 + $1.duration }
        let totalHesitations = journeys.reduce(0) { $0 + $1.hesitationPoints.count }
        let avgJourneyDuration = totalJourneys > 0 ? totalDuration / totalJourneys : 0
        
        // Calculate anxiety-free percentage (journeys with no anxious/panic checkpoints)
        let anxietyFreeCount = journeys.filter { journey in
            !journey.checkpoints.contains { checkpoint in
                checkpoint.feeling == "anxious" || checkpoint.feeling == "panic"
            }
        }.count
        let anxietyFreePercentage = totalJourneys > 0 ? Double(anxietyFreeCount) / Double(totalJourneys) * 100.0 : 0.0
        
        // Calculate furthest distance and safe area size
        let furthest = calculateFurthestPoint(extractedData: extractedData)
        let furthestDistance = furthest?.distance ?? 0.0
        
        // Calculate safe area size (approximate from polygon area)
        let safeArea = calculateSafeAreaOverlay()
        let safeAreaSize = calculatePolygonArea(polygon: safeArea) ?? 0.0
        
        return CumulativeStats(
            totalJourneys: totalJourneys,
            totalDistance: totalDistance,
            totalDuration: totalDuration,
            furthestDistance: furthestDistance,
            safeAreaSize: safeAreaSize,
            totalHesitations: totalHesitations,
            avgJourneyDuration: avgJourneyDuration,
            anxietyFreePercentage: anxietyFreePercentage
        )
    }
    
    private func calculateHeatMap(extractedData: ExtractedJourneyData, gridSize: Double = 100.0) -> [HeatMapCell] {
        let allPoints = extractedData.pathPoints
        guard !allPoints.isEmpty else { return [] }
        
        // Find bounding box
        let minLat = allPoints.map { $0.lat }.min()!
        let maxLat = allPoints.map { $0.lat }.max()!
        let minLon = allPoints.map { $0.lon }.min()!
        let maxLon = allPoints.map { $0.lon }.max()!
        
        // Calculate grid dimensions
        let centerLat = (minLat + maxLat) / 2.0
        let metersPerDegreeLat = 111320.0
        let metersPerDegreeLon = 111320.0 * cos(centerLat * .pi / 180.0)
        
        let degreesLat = gridSize / metersPerDegreeLat
        let degreesLon = gridSize / metersPerDegreeLon
        
        let latSteps = Int((maxLat - minLat) / degreesLat) + 1
        let lonSteps = Int((maxLon - minLon) / degreesLon) + 1
        
        // Create grid cells and count points
        var cellCounts: [String: Int] = [:]
        for point in allPoints {
            let latIndex = Int((point.lat - minLat) / degreesLat)
            let lonIndex = Int((point.lon - minLon) / degreesLon)
            let key = "\(latIndex),\(lonIndex)"
            cellCounts[key, default: 0] += 1
        }
        
        // Find max count for normalization
        let maxCount = cellCounts.values.max() ?? 1
        
        // Create heat map cells
        var cells: [HeatMapCell] = []
        for (key, count) in cellCounts {
            let parts = key.split(separator: ",")
            guard parts.count == 2,
                  let latIndex = Int(parts[0]),
                  let lonIndex = Int(parts[1]) else { continue }
            
            let cellLat = minLat + Double(latIndex) * degreesLat + degreesLat / 2.0
            let cellLon = minLon + Double(lonIndex) * degreesLon + degreesLon / 2.0
            let coordinate = CLLocationCoordinate2D(latitude: cellLat, longitude: cellLon)
            
            // Create bounds for this cell
            let cellMinLat = minLat + Double(latIndex) * degreesLat
            let cellMaxLat = cellMinLat + degreesLat
            let cellMinLon = minLon + Double(lonIndex) * degreesLon
            let cellMaxLon = cellMinLon + degreesLon
            
            let topLeft = MKMapPoint(CLLocationCoordinate2D(latitude: cellMaxLat, longitude: cellMinLon))
            let bottomRight = MKMapPoint(CLLocationCoordinate2D(latitude: cellMinLat, longitude: cellMaxLon))
            let bounds = MKMapRect(x: topLeft.x, y: topLeft.y, width: bottomRight.x - topLeft.x, height: bottomRight.y - topLeft.y)
            
            let normalizedIntensity = Double(count) / Double(maxCount)
            
            cells.append(HeatMapCell(
                id: UUID(),
                coordinate: coordinate,
                bounds: bounds,
                count: count,
                normalizedIntensity: normalizedIntensity
            ))
        }
        
        return cells
    }
    
    private func calculateBoundaryPolygon(extractedData: ExtractedJourneyData) -> MKPolygon? {
        let allPoints = extractedData.pathPoints
        guard !allPoints.isEmpty else { return nil }
        
        // Collect all unique coordinates
        var allCoordinates: Set<String> = []
        var coordinateMap: [String: CLLocationCoordinate2D] = [:]
        
        for point in allPoints {
            // Round to reduce duplicates
            let roundedLat = round(point.lat * 10000) / 10000
            let roundedLon = round(point.lon * 10000) / 10000
            let key = "\(roundedLat),\(roundedLon)"
            if !allCoordinates.contains(key) {
                allCoordinates.insert(key)
                coordinateMap[key] = CLLocationCoordinate2D(latitude: roundedLat, longitude: roundedLon)
            }
        }
        
        guard allCoordinates.count >= 3 else { return nil }
        
        let points = Array(coordinateMap.values)
        let hull = convexHull(points: points)
        
        guard hull.count >= 3 else { return nil }
        
        var coordsArray = hull
        return MKPolygon(coordinates: &coordsArray, count: coordsArray.count)
    }
    
    private func calculateLastWeekBoundaryPolygon(journeys: [JourneyRealm]) -> MKPolygon? {
        // Filter journeys from last week (7-14 days ago, not including today or last 7 days)
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -14, to: now) ?? now
        
        let lastWeekJourneys = journeys.filter { journey in
            journey.startTime >= fourteenDaysAgo && journey.startTime < sevenDaysAgo
        }
        
        guard !lastWeekJourneys.isEmpty else { return nil }
        
        // Extract path points from last week journeys
        var lastWeekPoints: [(lat: Double, lon: Double)] = []
        for journey in lastWeekJourneys {
            for point in journey.pathPoints {
                lastWeekPoints.append((lat: point.latitude, lon: point.longitude))
            }
        }
        
        guard !lastWeekPoints.isEmpty else { return nil }
        
        // Collect all unique coordinates
        var allCoordinates: Set<String> = []
        var coordinateMap: [String: CLLocationCoordinate2D] = [:]
        
        for point in lastWeekPoints {
            // Round to reduce duplicates
            let roundedLat = round(point.lat * 10000) / 10000
            let roundedLon = round(point.lon * 10000) / 10000
            let key = "\(roundedLat),\(roundedLon)"
            if !allCoordinates.contains(key) {
                allCoordinates.insert(key)
                coordinateMap[key] = CLLocationCoordinate2D(latitude: roundedLat, longitude: roundedLon)
            }
        }
        
        guard allCoordinates.count >= 3 else { return nil }
        
        let points = Array(coordinateMap.values)
        let hull = convexHull(points: points)
        
        guard hull.count >= 3 else { return nil }
        
        var coordsArray = hull
        return MKPolygon(coordinates: &coordsArray, count: coordsArray.count)
    }
    
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
    
    private func calculateSafeAreaOverlay() -> MKPolygon? {
        guard let realm = try? Realm() else { return nil }
        
        let safeAreaPoints = realm.objects(SafeAreaPointRealm.self)
        
        guard safeAreaPoints.count >= 3 else { return nil }
        
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
                // Use the average coordinate of points in this cell (or sample one per cell)
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
    
    private func clusterHesitations(extractedData: ExtractedJourneyData) -> [HesitationCluster] {
        var allHesitations: [(coordinate: CLLocationCoordinate2D, duration: Double)] = []
        
        for hesitation in extractedData.hesitationPoints {
            allHesitations.append((
                coordinate: CLLocationCoordinate2D(latitude: hesitation.lat, longitude: hesitation.lon),
                duration: hesitation.duration
            ))
        }
        
        guard !allHesitations.isEmpty else { return [] }
        
        // Simple clustering: group hesitations within 50m of each other
        var clusters: [HesitationCluster] = []
        var processed = Set<Int>()
        let clusterRadius: Double = 50.0 // meters
        
        for (index, hesitation) in allHesitations.enumerated() {
            if processed.contains(index) { continue }
            
            let location = CLLocation(latitude: hesitation.coordinate.latitude, longitude: hesitation.coordinate.longitude)
            var clusterPoints: [(coordinate: CLLocationCoordinate2D, duration: Double)] = [hesitation]
            processed.insert(index)
            
            // Find nearby points
            for (otherIndex, otherHesitation) in allHesitations.enumerated() {
                if processed.contains(otherIndex) { continue }
                
                let otherLocation = CLLocation(latitude: otherHesitation.coordinate.latitude, longitude: otherHesitation.coordinate.longitude)
                if location.distance(from: otherLocation) <= clusterRadius {
                    clusterPoints.append(otherHesitation)
                    processed.insert(otherIndex)
                }
            }
            
            // Calculate cluster center (average)
            let avgLat = clusterPoints.map { $0.coordinate.latitude }.reduce(0, +) / Double(clusterPoints.count)
            let avgLon = clusterPoints.map { $0.coordinate.longitude }.reduce(0, +) / Double(clusterPoints.count)
            let totalDuration = clusterPoints.map { $0.duration }.reduce(0, +)
            
            clusters.append(HesitationCluster(
                id: UUID(),
                coordinate: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon),
                count: clusterPoints.count,
                totalDuration: totalDuration
            ))
        }
        
        return clusters
    }
    
    private func calculateFurthestPoint(extractedData: ExtractedJourneyData) -> (coordinate: CLLocationCoordinate2D, distance: Double)? {
        let startPoints = extractedData.startPoints
        let allPoints = extractedData.pathPoints
        
        guard !startPoints.isEmpty && !allPoints.isEmpty else { return nil }
        
        // Calculate average "home" location (average of all start points)
        let avgLat = startPoints.map { $0.lat }.reduce(0, +) / Double(startPoints.count)
        let avgLon = startPoints.map { $0.lon }.reduce(0, +) / Double(startPoints.count)
        let homeLocation = CLLocation(latitude: avgLat, longitude: avgLon)
        
        // Find furthest point from home
        var maxDistance: Double = 0
        var furthestCoord: CLLocationCoordinate2D?
        
        for point in allPoints {
            let pointLocation = CLLocation(latitude: point.lat, longitude: point.lon)
            let distance = homeLocation.distance(from: pointLocation)
            if distance > maxDistance {
                maxDistance = distance
                furthestCoord = CLLocationCoordinate2D(latitude: point.lat, longitude: point.lon)
            }
        }
        
        guard let coordinate = furthestCoord else { return nil }
        return (coordinate: coordinate, distance: maxDistance)
    }
    
    private func calculatePolygonArea(polygon: MKPolygon?) -> Double? {
        guard let polygon = polygon, polygon.pointCount >= 3 else { return nil }
        
        var area: Double = 0
        let points = polygon.points()
        
        for i in 0..<polygon.pointCount {
            let j = (i + 1) % polygon.pointCount
            area += Double(points[i].coordinate.longitude) * Double(points[j].coordinate.latitude)
            area -= Double(points[j].coordinate.longitude) * Double(points[i].coordinate.latitude)
        }
        
        area = abs(area) / 2.0
        
        // Convert to square meters (approximate)
        let centerLat = polygon.coordinate.latitude
        let metersPerDegreeLat = 111320.0
        let metersPerDegreeLon = 111320.0 * cos(centerLat * .pi / 180.0)
        area *= metersPerDegreeLat * metersPerDegreeLon
        
        return area
    }
}

// MARK: - Cumulative Map View

struct CumulativeMapView: UIViewRepresentable {
    let journeys: [JourneyRealm]
    let layerToggles: MapLayerToggles
    let heatMapCells: [HeatMapCell]
    let boundaryPolygon: MKPolygon?
    let lastWeekBoundaryPolygon: MKPolygon?
    let safeAreaPolygon: MKPolygon?
    let hesitationClusters: [HesitationCluster]
    let showPaths: Bool
    let isCompact: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .standard
        mapView.showsUserLocation = false
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Remove all existing overlays and annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        // Calculate bounding box from all journeys
        var allCoordinates: [CLLocationCoordinate2D] = []
        for journey in journeys {
            for point in journey.pathPoints {
                allCoordinates.append(CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude))
            }
        }
        
        guard !allCoordinates.isEmpty else { return }
        
        // Set map region to show all journeys
        let minLat = allCoordinates.map { $0.latitude }.min()!
        let maxLat = allCoordinates.map { $0.latitude }.max()!
        let minLon = allCoordinates.map { $0.longitude }.min()!
        let maxLon = allCoordinates.map { $0.longitude }.max()!
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2.0,
            longitude: (minLon + maxLon) / 2.0
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.3, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.3, 0.01)
        )
        
        mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: false)
        
        // Add heat map cells
        if layerToggles.showHeatMap {
            for cell in heatMapCells {
                let overlay = HeatMapCellOverlay(cell: cell)
                mapView.addOverlay(overlay)
            }
        }
        
        // Add boundary polygon
        if layerToggles.showBoundary, let boundary = boundaryPolygon {
            let boundaryOverlay = BoundaryPolygonOverlay(polygon: boundary)
            mapView.addOverlay(boundaryOverlay)
        }
        
        // Add last week boundary polygon (fainter)
        if layerToggles.showLastWeekBoundary, let lastWeekBoundary = lastWeekBoundaryPolygon {
            let lastWeekBoundaryOverlay = LastWeekBoundaryPolygonOverlay(polygon: lastWeekBoundary)
            mapView.addOverlay(lastWeekBoundaryOverlay)
        }
        
        // Add safe area polygon
        if layerToggles.showSafeArea, let safeArea = safeAreaPolygon {
            let safeAreaOverlay = SafeAreaPolygonOverlay(polygon: safeArea)
            mapView.addOverlay(safeAreaOverlay)
        }
        
        // Add total distance circle with easterly line (centered at average home location)
        if !journeys.isEmpty {
            // Calculate average home location from start points
            var startPoints: [CLLocationCoordinate2D] = []
            for journey in journeys {
                if let firstPoint = journey.pathPoints.first {
                    startPoints.append(CLLocationCoordinate2D(latitude: firstPoint.latitude, longitude: firstPoint.longitude))
                }
            }
            
            if !startPoints.isEmpty {
                let avgLat = startPoints.map { $0.latitude }.reduce(0, +) / Double(startPoints.count)
                let avgLon = startPoints.map { $0.longitude }.reduce(0, +) / Double(startPoints.count)
                let homeLocation = CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)
                
                // Calculate total distance (sum of all journey distances)
                let totalDistance = journeys.reduce(0.0) { $0 + $1.distance }
                
                if totalDistance > 0 {
                    // Create circle centered at home with radius = total distance
                    let circle = MKCircle(center: homeLocation, radius: totalDistance)
                    let circleOverlay = TotalDistanceCircleOverlay(circle: circle)
                    mapView.addOverlay(circleOverlay)
                    
                    // Calculate easterly point on the circle (same latitude, longitude increased)
                    // Convert distance (meters) to degrees longitude at this latitude
                    let metersPerDegreeLon = 111320.0 * cos(avgLat * .pi / 180.0)
                    let lonDelta = totalDistance / metersPerDegreeLon
                    let easterlyPoint = CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon + lonDelta)
                    
                    // Create line from center to easterly point
                    let lineCoordinates = [homeLocation, easterlyPoint]
                    var coords = lineCoordinates
                    let easterlyLine = MKPolyline(coordinates: &coords, count: coords.count)
                    mapView.addOverlay(easterlyLine)
                }
            }
        }
        
        // Add journey paths (only if showPaths is true)
        if showPaths && layerToggles.showPaths {
            for journey in journeys {
                guard journey.pathPoints.count > 1 else { continue }
                
                // Sample points if too many (performance optimization)
                let points = journey.pathPoints.count > 5000 
                    ? Array(journey.pathPoints.striding(by: journey.pathPoints.count / 5000))
                    : Array(journey.pathPoints)
                
                let coordinates = points.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                mapView.addOverlay(polyline)
            }
        }
        
        // Add hesitation cluster annotations
        if layerToggles.showHesitations {
            for cluster in hesitationClusters {
                let annotation = HesitationClusterAnnotation(cluster: cluster)
                mapView.addAnnotation(annotation)
            }
        }
        
        // Add checkpoint annotations
        if layerToggles.showCheckpoints {
            for journey in journeys {
                for checkpoint in journey.checkpoints {
                    let annotation = CheckpointAnnotation(checkpoint: checkpoint)
                    mapView.addAnnotation(annotation)
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CumulativeMapView
        
        init(_ parent: CumulativeMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            // Heat map cells
            if let heatMapOverlay = overlay as? HeatMapCellOverlay {
                let renderer = HeatMapCellRenderer(overlay: heatMapOverlay)
                return renderer
            }
            
            // Boundary polygon (dashed) - improved visibility
            if let boundaryOverlay = overlay as? BoundaryPolygonOverlay {
                let renderer = MKPolygonRenderer(polygon: boundaryOverlay.polygon)
                renderer.fillColor = UIColor.systemPurple.withAlphaComponent(0.1)
                renderer.strokeColor = UIColor.systemPurple.withAlphaComponent(0.9) // Changed from systemBlue
                renderer.lineWidth = 3.5 // Increased from 3.0
                renderer.lineDashPattern = [10, 5]
                return renderer
            }
            
            // Last week boundary polygon (fainter version)
            if let lastWeekBoundaryOverlay = overlay as? LastWeekBoundaryPolygonOverlay {
                let renderer = MKPolygonRenderer(polygon: lastWeekBoundaryOverlay.polygon)
                renderer.fillColor = UIColor.systemPurple.withAlphaComponent(0.05) // Fainter fill
                renderer.strokeColor = UIColor.systemPurple.withAlphaComponent(0.4) // Much fainter stroke
                renderer.lineWidth = 2.5 // Thinner line
                renderer.lineDashPattern = [10, 5]
                return renderer
            }
            
            // Safe area polygon (green, semi-transparent)
            if let safeAreaOverlay = overlay as? SafeAreaPolygonOverlay {
                let renderer = MKPolygonRenderer(polygon: safeAreaOverlay.polygon)
                renderer.fillColor = UIColor.systemGreen.withAlphaComponent(0.2)
                renderer.strokeColor = UIColor.systemGreen.withAlphaComponent(0.5)
                renderer.lineWidth = 2.0
                return renderer
            }
            
            // Journey paths (polylines) - improved visibility
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.7) // Increased from 0.4
                renderer.lineWidth = 3.0 // Increased from 2.0
                return renderer
            }
            
            // Total distance circle with easterly line
            if let totalDistanceOverlay = overlay as? TotalDistanceCircleOverlay {
                let renderer = MKCircleRenderer(circle: totalDistanceOverlay.circle)
                renderer.fillColor = UIColor.systemBlue.withAlphaComponent(0.15)
                renderer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.8)
                renderer.lineWidth = 2.5
                return renderer
            }
            
            // Easterly line from center to edge
            if let easterlyLine = overlay as? MKPolyline, easterlyLine.pointCount == 2 {
                let renderer = MKPolylineRenderer(polyline: easterlyLine)
                renderer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.9)
                renderer.lineWidth = 2.5
                renderer.lineDashPattern = [5, 3]
                return renderer
            }
            
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Hesitation cluster annotation
            if let hesitationAnnotation = annotation as? HesitationClusterAnnotation {
                let identifier = "HesitationClusterAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                } else {
                    annotationView?.annotation = annotation
                }
                
                annotationView?.markerTintColor = .systemRed
                annotationView?.glyphText = "\(hesitationAnnotation.cluster.count)"
                annotationView?.glyphTintColor = .white
                annotationView?.displayPriority = .required
                return annotationView
            }
            
            // Checkpoint annotation
            if let checkpointAnnotation = annotation as? CheckpointAnnotation {
                let identifier = "CheckpointAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKAnnotationView
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                } else {
                    annotationView?.annotation = annotation
                }
                
                // Create colored dot based on feeling
                let feeling = FeelingLevel(rawValue: checkpointAnnotation.checkpoint.feeling) ?? .okay
                let size: CGFloat = 12
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
                let dotImage = renderer.image { context in
                    feeling.uiColor.setFill()
                    let circle = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size))
                    circle.fill()
                }
                
                annotationView?.image = dotImage
                annotationView?.centerOffset = CGPoint(x: 0, y: 0)
                return annotationView
            }
            
            return nil
        }
    }
}

// MARK: - Annotation Classes

class HesitationClusterAnnotation: NSObject, MKAnnotation {
    let cluster: HesitationCluster
    var coordinate: CLLocationCoordinate2D { cluster.coordinate }
    var title: String? { "Hesitation Cluster" }
    var subtitle: String? { "\(cluster.count) hesitations, \(Int(cluster.totalDuration))s total" }
    
    init(cluster: HesitationCluster) {
        self.cluster = cluster
    }
}

class CheckpointAnnotation: NSObject, MKAnnotation {
    let checkpoint: FeelingCheckpointRealm
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: checkpoint.latitude, longitude: checkpoint.longitude)
    }
    var title: String? { FeelingLevel(rawValue: checkpoint.feeling)?.title }
    var subtitle: String? { checkpoint.timestamp.formatted(date: .omitted, time: .shortened) }
    
    init(checkpoint: FeelingCheckpointRealm) {
        self.checkpoint = checkpoint
    }
}

// MARK: - Custom Overlay Classes

class HeatMapCellOverlay: NSObject, MKOverlay {
    let cell: HeatMapCell
    var coordinate: CLLocationCoordinate2D { cell.coordinate }
    var boundingMapRect: MKMapRect { cell.bounds }
    
    init(cell: HeatMapCell) {
        self.cell = cell
    }
}

class BoundaryPolygonOverlay: NSObject, MKOverlay {
    let polygon: MKPolygon
    var coordinate: CLLocationCoordinate2D { polygon.coordinate }
    var boundingMapRect: MKMapRect { polygon.boundingMapRect }
    
    init(polygon: MKPolygon) {
        self.polygon = polygon
    }
}

class LastWeekBoundaryPolygonOverlay: NSObject, MKOverlay {
    let polygon: MKPolygon
    var coordinate: CLLocationCoordinate2D { polygon.coordinate }
    var boundingMapRect: MKMapRect { polygon.boundingMapRect }
    
    init(polygon: MKPolygon) {
        self.polygon = polygon
    }
}

class SafeAreaPolygonOverlay: NSObject, MKOverlay {
    let polygon: MKPolygon
    var coordinate: CLLocationCoordinate2D { polygon.coordinate }
    var boundingMapRect: MKMapRect { polygon.boundingMapRect }
    
    init(polygon: MKPolygon) {
        self.polygon = polygon
    }
}

// MARK: - Total Distance Circle Overlay
class TotalDistanceCircleOverlay: NSObject, MKOverlay {
    let circle: MKCircle
    var coordinate: CLLocationCoordinate2D { circle.coordinate }
    var boundingMapRect: MKMapRect { circle.boundingMapRect }
    
    init(circle: MKCircle) {
        self.circle = circle
        super.init()
    }
}

class HeatMapCellRenderer: MKOverlayRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let heatMapOverlay = overlay as? HeatMapCellOverlay else { return }
        
        let cell = heatMapOverlay.cell
        let rect = rect(for: cell.bounds)
        
        // Improved visibility: increase alpha and ensure minimum visibility
        // For small datasets (few journeys), we need higher alpha to be visible
        let fillAlpha = max(0.4, min(0.8, 0.4 + cell.normalizedIntensity * 0.4)) // Range: 0.4 to 0.8
        let strokeAlpha = max(0.5, min(0.9, 0.5 + cell.normalizedIntensity * 0.4)) // Range: 0.5 to 0.9
        
        // Set fill color with improved visibility
        UIColor(cell.color).withAlphaComponent(fillAlpha).setFill()
        UIColor(cell.color).withAlphaComponent(strokeAlpha).setStroke()
        
        // Draw rectangle
        let path = UIBezierPath(rect: rect)
        path.fill()
        path.lineWidth = max(1.0, 1.5 / CGFloat(zoomScale)) // Increased minimum line width
        path.stroke()
    }
}

// MARK: - Helper Extension

extension Collection {
    func striding(by step: Int) -> [Element] {
        guard step > 0 else { return Array(self) }
        return self.enumerated().compactMap { index, element in
            index % step == 0 ? element : nil
        }
    }
}

// MARK: - Full Screen Cumulative Map View

struct FullScreenCumulativeMapView: View {
    let journeys: [JourneyRealm]
    let stats: CumulativeStats?
    let heatMapCells: [HeatMapCell]
    let boundaryPolygon: MKPolygon?
    let lastWeekBoundaryPolygon: MKPolygon?
    let safeAreaPolygon: MKPolygon?
    let hesitationClusters: [HesitationCluster]
    @Binding var layerToggles: MapLayerToggles
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var showLayerSheet = false
    @AppStorage("setting.miles") private var enableMiles = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.backgroundColor(for: colorScheme)
                    .ignoresSafeArea()
                
                // Full Map View
                CumulativeMapView(
                    journeys: journeys,
                    layerToggles: layerToggles,
                    heatMapCells: heatMapCells,
                    boundaryPolygon: boundaryPolygon,
                    lastWeekBoundaryPolygon: lastWeekBoundaryPolygon,
                    safeAreaPolygon: safeAreaPolygon,
                    hesitationClusters: hesitationClusters,
                    showPaths: true, // Allow paths in full screen
                    isCompact: false
                )
                .ignoresSafeArea()
                
                // Stats Overlay (Bottom)
                if let stats = stats {
                    VStack {
                        Spacer()
                        fullScreenStatsOverlay(stats: stats)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Overall Journeys")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showLayerSheet = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18))
                    }
                }
            }
        }
        .sheet(isPresented: $showLayerSheet) {
            MapLayersSheet(layerToggles: $layerToggles)
        }
    }
    
    private func fullScreenStatsOverlay(stats: CumulativeStats) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                statPill(icon: "figure.walk", value: formatDistance(stats.totalDistance), label: "Total Distance")
                statPill(icon: "map.fill", value: "\(stats.totalJourneys)", label: "Journeys")
                statPill(icon: "clock.fill", value: formatDuration(stats.totalDuration), label: "Time")
                
                if stats.furthestDistance > 0 {
                    statPill(icon: "arrow.up.right", value: formatDistance(stats.furthestDistance), label: "Max Range")
                }
                
                if stats.totalHesitations > 0 {
                    statPill(icon: "pause.circle.fill", value: "\(stats.totalHesitations)", label: "Hesitations")
                }
                
                if stats.anxietyFreePercentage > 0 {
                    statPill(icon: "heart.fill", value: String(format: "%.0f%%", stats.anxietyFreePercentage), label: "Anxiety Free")
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.8))
                .blur(radius: 1)
        )
    }
    
    private func statPill(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if enableMiles {
            let miles = meters / 1609.34
            return String(format: "%.1f mi", miles)
        } else {
            let km = meters / 1000.0
            return String(format: "%.1f km", km)
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        }
        return String(format: "%dm", minutes)
    }
}

// MARK: - Map Layers Sheet

struct MapLayersSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Binding var layerToggles: MapLayerToggles
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Toggle("Heat Map (Most Traveled Areas)", isOn: $layerToggles.showHeatMap)
                    Toggle("Range Boundary", isOn: $layerToggles.showBoundary)
                    Toggle("Last Week Range Boundary", isOn: $layerToggles.showLastWeekBoundary)
                    Toggle("Safe Areas", isOn: $layerToggles.showSafeArea)
                    Toggle("Journey Paths", isOn: $layerToggles.showPaths)
                    Toggle("Hesitation Points", isOn: $layerToggles.showHesitations)
                    Toggle("Feeling Checkpoints", isOn: $layerToggles.showCheckpoints)
                } header: {
                    Text("Visualization Layers")
                } footer: {
                    VStack(alignment: .leading, spacing: 12) {
                        Group {
                            Text("📊 Heat Map (Most Traveled Areas)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                            Text("Color-coded regions showing where you've traveled most frequently. Warmer colors indicate higher activity.")
                                .font(.system(size: 12))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            
                            Text("🔷 Range Boundary")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                .padding(.top, 4)
                            Text("Purple dashed polygon showing the outer boundary of all your journeys (current range).")
                                .font(.system(size: 12))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            
                            Text("🔷 Last Week Range Boundary")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                .padding(.top, 4)
                            Text("Fainter purple polygon showing your range from 7-14 days ago. Compare your progress over time!")
                                .font(.system(size: 12))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            
                            Text("✅ Safe Areas")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                .padding(.top, 4)
                            Text("Green polygon highlighting areas where you've traveled multiple times without anxiety or panic feelings.")
                                .font(.system(size: 12))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            
                            Text("🛤️ Journey Paths")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                .padding(.top, 4)
                            Text("Blue lines showing the actual routes you've taken during your journeys.")
                                .font(.system(size: 12))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            
                            Text("⏸️ Hesitation Points")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                .padding(.top, 4)
                            Text("Red boxes marking places where you paused or hesitated for a period of time.")
                                .font(.system(size: 12))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            
                            Text("❤️ Feeling Checkpoints")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                .padding(.top, 4)
                            Text("Markers showing where you recorded your feelings during journeys (anxiety levels, panic, etc.).")
                                .font(.system(size: 12))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            
                            Text("🔵 Total Distance Circle")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                .padding(.top, 4)
                            Text("Blue circle centered at your average starting point, with radius equal to your total cumulative distance. The dashed line points east to show the scale.")
                                .font(.system(size: 12))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Map Info & Layers")
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
}
