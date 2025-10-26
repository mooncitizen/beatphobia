//
//  JourneyModel.swift
//  beatphobia
//
//  Created by Paul Gardiner on 20/10/2025.
//

import Foundation
import RealmSwift

enum JourneyType: Int, PersistableEnum {
    case Agoraphobia
    case GeneralAnxiety
    case None
    
    var title: String {
        switch self {
        case .Agoraphobia:
            return "Agoraphobia"
        case .GeneralAnxiety:
            return "General Anxiety"
        case .None:
            return "No Journey"
        }
    }
    
    var description: String {
        switch self {
        case .Agoraphobia:
            return "A journey focused on overcoming agoraphobia."
        case .GeneralAnxiety:
            return "A journey focused on managing general anxiety."
        case .None:
            return "No journey has been selected."
        }
    }
}

final class Journey: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: UUID = UUID()
    @Persisted var type: JourneyType = .None
    @Persisted var startDate: Date = Date()
    @Persisted var isCompleted: Bool = false
    @Persisted var current: Bool = true
}
