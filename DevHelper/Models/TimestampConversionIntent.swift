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
import SwiftUI

struct TimestampConversionIntent: AppIntent {
    static var title: LocalizedStringResource = "Convert Timestamp"
    static var description = IntentDescription("Convert a timestamp to a human-readable date")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Timestamp", description: "The timestamp to convert")
    var timestamp: String

    static var parameterSummary: some ParameterSummary {
        Summary("Convert \(\.$timestamp) to date")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let convertedDate = convertTimestamp(timestamp)

        return .result(
            dialog: "The timestamp \(timestamp) converts to \(convertedDate)",
            view: TimestampResultView(timestamp: timestamp, convertedDate: convertedDate)
        )
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

struct TimestampResultView: View {
    let timestamp: String
    let convertedDate: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.blue)
                Text("Timestamp Conversion")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Input:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(timestamp)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Converted Date:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(convertedDate)
                    .font(.body)
                    .textSelection(.enabled)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}
