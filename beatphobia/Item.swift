//
//  Item.swift
//  beatphobia
//
//  Created by Paul Gardiner on 18/10/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
