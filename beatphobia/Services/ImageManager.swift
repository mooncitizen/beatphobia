//
//  ImageManager.swift
//  beatphobia
//
//  Created by Paul Gardiner on 30/10/2025.
//
//  Manages image uploads to Supabase Storage with local disk caching

import Foundation
import SwiftUI
import Supabase
import Combine
import UIKit

@MainActor
class ImageManager: ObservableObject {
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var error: String?
    
    private let bucketName = "community-attachments"
    private let cacheDirectory: URL
    private let maxCacheSize: Int = 100 * 1024 * 1024 // 100 MB max cache
    
    init() {
        // Setup cache directory
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("ImageCache", isDirectory: true)
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        print("📁 Image cache directory: \(cacheDirectory.path)")
    }
    
    // MARK: - Upload Image
    
    /// Uploads an image to Supabase Storage and returns the public URL
    func uploadImage(_ image: UIImage, folder: String = "posts", bucket: String = "community-attachments") async throws -> String {
        isUploading = true
        uploadProgress = 0
        error = nil
        defer { isUploading = false }
        
        // Compress image to reasonable size
        guard let imageData = compressImage(image) else {
            throw ImageError.compressionFailed
        }
        
        // Generate unique filename
        let filename = "\(folder)/\(UUID().uuidString).jpg"
        
        print("📤 Uploading image: \(filename) (\(imageData.count / 1024) KB)")
        
        // Upload to Supabase Storage
        do {
            try await supabase.storage
                .from(bucket)
                .upload(
                    filename,
                    data: imageData,
                    options: FileOptions(
                        contentType: "image/jpeg"
                    )
                )
            
            // Get public URL
            let publicURL = try supabase.storage
                .from(bucket)
                .getPublicURL(path: filename)
            
            uploadProgress = 1.0
            print("✅ Image uploaded successfully: \(publicURL)")
            
            return publicURL.absoluteString
        } catch {
            self.error = "Failed to upload image: \(error.localizedDescription)"
            throw ImageError.uploadFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Load Image with Caching
    
    /// Loads an image from cache or downloads from URL
    func loadImage(from urlString: String) async -> UIImage? {
        // Check cache first
        if let cachedImage = loadFromCache(urlString: urlString) {
            print("📂 Loaded image from cache: \(urlString)")
            return cachedImage
        }
        
        // Download from URL
        guard let url = URL(string: urlString) else {
            print("❌ Invalid image URL: \(urlString)")
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            guard let image = UIImage(data: data) else {
                print("❌ Failed to decode image from: \(urlString)")
                return nil
            }
            
            // Save to cache
            saveToCache(image: image, urlString: urlString)
            
            print("✅ Downloaded and cached image: \(urlString)")
            return image
        } catch {
            print("❌ Error downloading image: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Cache Management
    
    private func loadFromCache(urlString: String) -> UIImage? {
        let cacheKey = cacheKey(from: urlString)
        let filePath = cacheDirectory.appendingPathComponent(cacheKey)
        
        guard FileManager.default.fileExists(atPath: filePath.path),
              let data = try? Data(contentsOf: filePath),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    private func saveToCache(image: UIImage, urlString: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let cacheKey = cacheKey(from: urlString)
        let filePath = cacheDirectory.appendingPathComponent(cacheKey)
        
        do {
            try data.write(to: filePath)
            
            // Check cache size and clean if needed
            Task.detached(priority: .background) {
                await self.cleanCacheIfNeeded()
            }
        } catch {
            print("❌ Failed to save to cache: \(error)")
        }
    }
    
    private func cacheKey(from urlString: String) -> String {
        // Create a safe filename from URL
        return urlString
            .addingPercentEncoding(withAllowedCharacters: .alphanumerics)?
            .replacingOccurrences(of: "%", with: "")
            .prefix(200) // Limit filename length
            .appending(".jpg")
            ?? "\(UUID().uuidString).jpg"
    }
    
    /// Clears all cached images
    func clearCache() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
            print("🗑️ Cleared image cache (\(files.count) files)")
        } catch {
            print("❌ Error clearing cache: \(error)")
        }
    }
    
    /// Returns cache size in bytes
    func getCacheSize() -> Int {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            let totalSize = files.reduce(0) { total, fileURL in
                let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                return total + size
            }
            return totalSize
        } catch {
            return 0
        }
    }
    
    /// Removes oldest cached images if cache exceeds max size
    private func cleanCacheIfNeeded() async {
        let currentSize = getCacheSize()
        
        guard currentSize > maxCacheSize else { return }
        
        print("🧹 Cache size (\(currentSize / 1024 / 1024) MB) exceeds limit, cleaning...")
        
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
            )
            
            // Sort by modification date (oldest first)
            let sortedFiles = files.sorted { file1, file2 in
                let date1 = (try? file1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                let date2 = (try? file2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                return date1 < date2
            }
            
            // Delete oldest files until under the limit
            var deletedSize = 0
            var deletedCount = 0
            
            for file in sortedFiles {
                let fileSize = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                try? FileManager.default.removeItem(at: file)
                deletedSize += fileSize
                deletedCount += 1
                
                if (currentSize - deletedSize) < (maxCacheSize * 80 / 100) { // Clean to 80% of max
                    break
                }
            }
            
            print("✅ Cleaned cache: deleted \(deletedCount) files (\(deletedSize / 1024 / 1024) MB)")
        } catch {
            print("❌ Error cleaning cache: \(error)")
        }
    }
    
    // MARK: - Image Compression
    
    private func compressImage(_ image: UIImage) -> Data? {
        // Resize to max width/height while maintaining aspect ratio
        let maxDimension: CGFloat = 1200
        let scaledImage: UIImage
        
        if image.size.width > maxDimension || image.size.height > maxDimension {
            let scale = min(maxDimension / image.size.width, maxDimension / image.size.height)
            let newSize = CGSize(
                width: image.size.width * scale,
                height: image.size.height * scale
            )
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            scaledImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        } else {
            scaledImage = image
        }
        
        // Compress JPEG with quality
        var compression: CGFloat = 0.8
        var imageData = scaledImage.jpegData(compressionQuality: compression)
        
        // If still too large (> 2MB), reduce quality
        while let data = imageData, data.count > 2 * 1024 * 1024 && compression > 0.3 {
            compression -= 0.1
            imageData = scaledImage.jpegData(compressionQuality: compression)
        }
        
        if let finalData = imageData {
            print("📦 Compressed image: \(finalData.count / 1024) KB (quality: \(Int(compression * 100))%)")
        }
        
        return imageData
    }
    
    // MARK: - Delete Image
    
    /// Deletes an image from Supabase Storage
    func deleteImage(urlString: String) async throws {
        // Extract path from URL
        guard let url = URL(string: urlString),
              let pathComponents = url.pathComponents.dropFirst(4).joined(separator: "/").removingPercentEncoding else {
            throw ImageError.invalidURL
        }
        
        do {
            try await supabase.storage
                .from(bucketName)
                .remove(paths: [pathComponents])
            
            // Remove from cache
            let cacheKey = cacheKey(from: urlString)
            let filePath = cacheDirectory.appendingPathComponent(cacheKey)
            try? FileManager.default.removeItem(at: filePath)
            
            print("✅ Deleted image: \(pathComponents)")
        } catch {
            print("❌ Error deleting image: \(error)")
            throw ImageError.deleteFailed(error.localizedDescription)
        }
    }
}

// MARK: - Image Errors

enum ImageError: LocalizedError {
    case compressionFailed
    case uploadFailed(String)
    case invalidURL
    case deleteFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .invalidURL:
            return "Invalid image URL"
        case .deleteFailed(let message):
            return "Delete failed: \(message)"
        }
    }
}

// MARK: - Cached Async Image View

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let urlString: String
    let content: (UIImage) -> Content
    let placeholder: () -> Placeholder
    
    @StateObject private var imageManager = ImageManager()
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    
    init(
        urlString: String,
        @ViewBuilder content: @escaping (UIImage) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.urlString = urlString
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = loadedImage {
                content(image)
            } else {
                placeholder()
            }
        }
        .task {
            guard !isLoading else { return }
            isLoading = true
            loadedImage = await imageManager.loadImage(from: urlString)
            isLoading = false
        }
    }
}

#Preview {
    VStack {
        Text("Image Manager Preview")
    }
}

