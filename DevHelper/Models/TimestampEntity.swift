// Copyright 2025 Hengfei Yang.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import AppIntents
import Foundation

struct TimestampEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Timestamp")
    }

    static var defaultQuery = TimestampEntityQuery()

    var id: String
    var timestamp: String
    var convertedDate: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: timestamp),
            subtitle: LocalizedStringResource(stringLiteral: convertedDate)
        )
    }
}

struct TimestampEntityQuery: EntityQuery {
    func entities(for identifiers: [TimestampEntity.ID]) async throws -> [TimestampEntity] {
        return identifiers.compactMap { id in
            TimestampEntity(
                id: id,
                timestamp: id,
                convertedDate: convertTimestamp(id)
            )
        }
    }

    func suggestedEntities() async throws -> [TimestampEntity] {
        let currentTimestamp = String(Int(Date().timeIntervalSince1970))
        return [
            TimestampEntity(
                id: currentTimestamp,
                timestamp: currentTimestamp,
                convertedDate: convertTimestamp(currentTimestamp)
            )
        ]
    }

    private func convertTimestamp(_ timestampString: String) -> String {
        guard let timestamp = Double(timestampString) else {
            return "Invalid timestamp"
        }

        let date: Date

        // Auto-detect timestamp format based on number of digits
        if timestampString.count == 10 {
            // Seconds
            date = Date(timeIntervalSince1970: timestamp)
        } else if timestampString.count == 13 {
            // Milliseconds
            date = Date(timeIntervalSince1970: timestamp / 1000)
        } else if timestampString.count == 16 {
            // Microseconds
            date = Date(timeIntervalSince1970: timestamp / 1_000_000)
        } else if timestampString.count == 19 {
            // Nanoseconds
            date = Date(timeIntervalSince1970: timestamp / 1_000_000_000)
        } else {
            // Default to seconds
            date = Date(timeIntervalSince1970: timestamp)
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .long
        formatter.timeZone = TimeZone.current

        return formatter.string(from: date)
    }
}
