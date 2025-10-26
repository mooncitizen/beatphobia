//
//  JournalEntry.swift
//  beatphobia
//
//  Created by Paul Gardiner on 21/10/2025.
//
import Foundation
import RealmSwift
import SwiftUI

enum Mood: String, CaseIterable, Identifiable, PersistableEnum {
    case happy
    case angry
    case excited
    case stressed
    case sad
    case none
    
    var id: String { self.rawValue }
    
    var text: String {
        self.rawValue.capitalized
    }
    
    var iconName: String {
        switch self {
        case .happy:
            return "smiley"
        case .angry:
            return "flame"
        case .excited:
            return "sparkles"
        case .stressed:
            return "brain.head.profile"
        case .sad:
            return "cloud.drizzle"
        case .none:
            return ""
        }
    }
    
    var color: Color {
        switch self {
        case .happy:
            return .green
        case .angry:
            return .red
        case .excited:
            return .orange
        case .stressed:
            return .purple
        case .sad:
            return .blue
        case .none:
            return .gray
        }
    }
}

final class JournalEntryModel: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: UUID = UUID()
    @Persisted var mood: Mood = .none
    @Persisted var text: String = ""
    @Persisted var date: Date = Date()
}

func fetchSortedJournalEntries() -> Results<JournalEntryModel> {
    let realm = try! Realm()
    let sortedEntries = realm.objects(JournalEntryModel.self).sorted(byKeyPath: "date", ascending: false)
    return sortedEntries
}


//enum JourneyType: Int, PersistableEnum {
//    case Agoraphobia
//    case GeneralAnxiety
//    case None
//    
//    var title: String {
//        switch self {
//        case .Agoraphobia:
//            return "Agoraphobia"
//        case .GeneralAnxiety:
//            return "General Anxiety"
//        case .None:
//            return "No Journey"
//        }
//    }
//    
//    var description: String {
//        switch self {
//        case .Agoraphobia:
//            return "A journey focused on overcoming agoraphobia."
//        case .GeneralAnxiety:
//            return "A journey focused on managing general anxiety."
//        case .None:
//            return "No journey has been selected."
//        }
//    }
//}
//
//final class Journey: Object, ObjectKeyIdentifiable {
//    @Persisted(primaryKey: true) var id: UUID = UUID()
//    @Persisted var type: JourneyType = .None
//    @Persisted var startDate: Date = Date()
//    @Persisted var isCompleted: Bool = false
//    @Persisted var current: Bool = true
//}

