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

import SwiftUI
import AppKit
import FirebaseAnalytics

struct TimestampConverterView: View {
    let screenName = "Timestamp Converter"
    @State private var timestampInput: String = ""
    @State private var dateInput: String = ""
    @State private var convertedDate: String = ""
    @State private var convertedTimestamp: String = ""
    @State private var isLocalTime: Bool = true
    @State private var copiedButtonId: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text(screenName)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                // Timestamp to Date
                VStack(alignment: .leading, spacing: 10) {
                    Text("Timestamp to Date")
                        .font(.headline)
                    
                    TextField("Enter timestamp", text: $timestampInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: timestampInput) { _, newValue in
                            convertTimestampToDate(newValue)
                        }
                    
                    Button("Current Timestamp") {
                        timestampInput = String(Int(Date().timeIntervalSince1970))
                    }
                    .buttonStyle(.bordered)
                    
                    ScrollView {
                        if convertedDate.isEmpty {
                            Text("Converted date will appear here")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                dateRow("UTC Time", getUTCFromResult())
                                dateRow("Local Time", getLocalFromResult())
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .frame(height: 120)
                }
                
                // Date to Timestamp
                VStack(alignment: .leading, spacing: 10) {
                    Text("Date to Timestamp")
                        .font(.headline)
                    
                    TextField("Enter date (YYYY-MM-DD HH:MM:SS)", text: $dateInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: dateInput) { _, newValue in
                            convertDateToTimestamp(newValue)
                        }
                    
                    Button("Current Date") {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        dateInput = formatter.string(from: Date())
                    }
                    .buttonStyle(.bordered)
                    
                    ScrollView {
                        if convertedTimestamp.isEmpty {
                            Text("Converted timestamp will appear here")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                timestampRow("Seconds", getSecondsFromResult())
                                timestampRow("Milliseconds", getMillisecondsFromResult())
                                timestampRow("Microseconds", getMicrosecondsFromResult())
                                timestampRow("Nanoseconds", getNanosecondsFromResult())
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .frame(height: 120)
                }
            }
            .padding(.horizontal, 0)
            
            Toggle("Use Local Time", isOn: $isLocalTime)
                .onChange(of: isLocalTime) { _, _ in
                    if !timestampInput.isEmpty {
                        convertTimestampToDate(timestampInput)
                    }
                    if !dateInput.isEmpty {
                        convertDateToTimestamp(dateInput)
                    }
                }
            
            Spacer()
        }
        .padding()
        .onAppear {
            loadState()
            Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                AnalyticsParameterScreenName: screenName
            ])
        }
        .onDisappear {
            saveState()
        }
    }
    
    private func convertTimestampToDate(_ timestamp: String) {
        guard !timestamp.isEmpty else {
            convertedDate = ""
            return
        }
        
        // Auto-detect timestamp format based on length
        var timeInterval: TimeInterval = 0
        
        if let timestampInt = Int64(timestamp) {
            switch timestamp.count {
            case 10: // seconds
                timeInterval = TimeInterval(timestampInt)
            case 13: // milliseconds
                timeInterval = TimeInterval(timestampInt) / 1000
            case 16: // microseconds
                timeInterval = TimeInterval(timestampInt) / 1_000_000
            case 19: // nanoseconds
                timeInterval = TimeInterval(timestampInt) / 1_000_000_000
            default:
                convertedDate = "Invalid timestamp format"
                return
            }
        } else {
            convertedDate = "Invalid timestamp"
            return
        }
        
        let date = Date(timeIntervalSince1970: timeInterval)
        
        // Format for local time
        let localFormatter = DateFormatter()
        localFormatter.timeZone = TimeZone.current
        localFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
        let localTime = localFormatter.string(from: date)
        
        // Format for UTC
        let utcFormatter = DateFormatter()
        utcFormatter.timeZone = TimeZone(abbreviation: "UTC")
        utcFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss 'UTC'"
        let utcTime = utcFormatter.string(from: date)
        
        convertedDate = """
        UTC Time: \(utcTime)

        Local Time: \(localTime)
        """
    }
    
    private func convertDateToTimestamp(_ dateString: String) {
        guard !dateString.isEmpty else {
            convertedTimestamp = ""
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if isLocalTime {
            formatter.timeZone = TimeZone.current
        } else {
            formatter.timeZone = TimeZone(abbreviation: "UTC")
        }
        
        if let date = formatter.date(from: dateString) {
            let timestamp = Int64(date.timeIntervalSince1970)
            convertedTimestamp = generateTimestampResult(timestamp)
        } else {
            convertedTimestamp = "Invalid date format. Use: YYYY-MM-DD HH:MM:SS"
        }
    }
    
    @ViewBuilder
    private func timestampRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text("\(label):")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value)
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 160, alignment: .leading)
                .textSelection(.enabled)
            Button(action: {
                copyToClipboard(value)
                withAnimation(.easeInOut(duration: 0.2)) {
                    copiedButtonId = "\(label)-\(value)"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        copiedButtonId = nil
                    }
                }
            }) {
                Image(systemName: copiedButtonId == "\(label)-\(value)" ? "checkmark" : "doc.on.doc")
                    .foregroundColor(copiedButtonId == "\(label)-\(value)" ? .green : .blue)
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .help("Copy to clipboard")
        }
    }
    
    private func generateTimestampResult(_ timestamp: Int64) -> String {
        return """
        Seconds: \(timestamp)
        
        Milliseconds: \(timestamp * 1000)
        
        Microseconds: \(timestamp * 1_000_000)
        
        Nanoseconds: \(timestamp * 1_000_000_000)
        """
    }
    
    private func getSecondsFromResult() -> String {
        let lines = convertedTimestamp.components(separatedBy: "\n")
        for line in lines {
            if line.hasPrefix("Seconds:") {
                return String(line.dropFirst(9))
            }
        }
        return ""
    }
    
    private func getMillisecondsFromResult() -> String {
        let lines = convertedTimestamp.components(separatedBy: "\n")
        for line in lines {
            if line.hasPrefix("Milliseconds:") {
                return String(line.dropFirst(14))
            }
        }
        return ""
    }
    
    private func getMicrosecondsFromResult() -> String {
        let lines = convertedTimestamp.components(separatedBy: "\n")
        for line in lines {
            if line.hasPrefix("Microseconds:") {
                return String(line.dropFirst(14))
            }
        }
        return ""
    }
    
    private func getNanosecondsFromResult() -> String {
        let lines = convertedTimestamp.components(separatedBy: "\n")
        for line in lines {
            if line.hasPrefix("Nanoseconds:") {
                return String(line.dropFirst(13))
            }
        }
        return ""
    }
    
    @ViewBuilder
    private func dateRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text("\(label):")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value)
                .frame(minWidth: 200, alignment: .leading)
                .textSelection(.enabled)
            Button(action: {
                copyToClipboard(value)
                withAnimation(.easeInOut(duration: 0.2)) {
                    copiedButtonId = "\(label)-\(value)"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        copiedButtonId = nil
                    }
                }
            }) {
                Image(systemName: copiedButtonId == "\(label)-\(value)" ? "checkmark" : "doc.on.doc")
                    .foregroundColor(copiedButtonId == "\(label)-\(value)" ? .green : .blue)
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .help("Copy to clipboard")
        }
    }
    
    private func getUTCFromResult() -> String {
        let lines = convertedDate.components(separatedBy: "\n")
        for line in lines {
            if line.hasPrefix("UTC Time:") {
                return String(line.dropFirst(10))
            }
        }
        return ""
    }
    
    private func getLocalFromResult() -> String {
        let lines = convertedDate.components(separatedBy: "\n")
        for line in lines {
            if line.hasPrefix("Local Time:") {
                return String(line.dropFirst(12))
            }
        }
        return ""
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(text, forType: .string)
    }
    
    private func saveState() {
        let defaults = UserDefaults.standard
        defaults.set(timestampInput, forKey: "TimestampConverter.timestampInput")
        defaults.set(dateInput, forKey: "TimestampConverter.dateInput")
        defaults.set(convertedDate, forKey: "TimestampConverter.convertedDate")
        defaults.set(convertedTimestamp, forKey: "TimestampConverter.convertedTimestamp")
        defaults.set(isLocalTime, forKey: "TimestampConverter.isLocalTime")
    }
    
    private func loadState() {
        let defaults = UserDefaults.standard
        timestampInput = defaults.string(forKey: "TimestampConverter.timestampInput") ?? ""
        dateInput = defaults.string(forKey: "TimestampConverter.dateInput") ?? ""
        convertedDate = defaults.string(forKey: "TimestampConverter.convertedDate") ?? ""
        convertedTimestamp = defaults.string(forKey: "TimestampConverter.convertedTimestamp") ?? ""
        isLocalTime = defaults.bool(forKey: "TimestampConverter.isLocalTime")
        
        // If we have initial values, trigger conversions
        if !timestampInput.isEmpty {
            convertTimestampToDate(timestampInput)
        }
        if !dateInput.isEmpty {
            convertDateToTimestamp(dateInput)
        }
    }
}

#Preview {
    TimestampConverterView()
}