//
//  Untitled.swift
//  beatphobia
//
//  Created by Paul Gardiner on 18/10/2025.
//

import Foundation
import Supabase

let SUPABASE_URL = "https://dktqwcqucsykjayyibuj.supabase.co"
let SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrdHF3Y3F1Y3N5a2pheXlpYnVqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA3OTk4MDcsImV4cCI6MjA3NjM3NTgwN30.wiPu71IG71kg0IAY-6XOeasxY_gimSrE-NeftyfGbg4"


let supabase: SupabaseClient = {
    if SUPABASE_URL.contains("YOUR_SUPABASE") || SUPABASE_ANON_KEY.contains("YOUR_SUPABASE") {
        fatalError("🚨🚨🚨 WARNING: Supabase keys not updated. Please replace the placeholders! 🚨🚨🚨")
    }
    
    guard let supabaseUrl = URL(string: SUPABASE_URL) else {
        fatalError("Invalid URL for SUPABASE_URL")
    }
    
    // Configure JSON decoder for proper date handling
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    
    return SupabaseClient(
        supabaseURL: supabaseUrl, 
        supabaseKey: SUPABASE_ANON_KEY,
        options: SupabaseClientOptions(
            db: SupabaseClientOptions.DatabaseOptions(
                encoder: encoder,
                decoder: decoder
            )
        )
    )
}()

func checkSupabaseConfiguration() {
    if SUPABASE_URL.contains("YOUR_SUPABASE") || SUPABASE_ANON_KEY.contains("YOUR_SUPABASE") {
        print("🚨🚨🚨 WARNING: Supabase keys not updated. The application will crash or fail to connect. Please replace the placeholders in Supabase.swift. 🚨🚨🚨")
    }
}
