//
//  Helpers.swift
//  beatphobia
//
//  Created by Paul Gardiner on 21/10/2025.
//
import Foundation

extension Date {
    func toRelativeString(
        style: RelativeDateTimeFormatter.DateTimeStyle = .named,
        units: RelativeDateTimeFormatter.UnitsStyle = .full
    ) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = style
        formatter.unitsStyle = units
        return formatter.localizedString(for: self, relativeTo: Date.now)
    }
}

extension String {
    func truncated(to length: Int) -> String {
        if self.count > length {
            return "\(self.prefix(length))..."
        } else {
            return self
        }
    }
}
