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
import FirebaseAnalytics

struct UUIDGeneratorView: View {
    let screenName = "UUID Generator"
    @State private var selectedVersion: UUIDVersion = .v4
    @State private var uuidFormat: UUIDFormat = .standard
    @State private var generatedUUIDs: [String] = []
    @State private var bulkCount: Int = 1
    @State private var validationInput: String = ""
    @State private var validationResult: String = ""
    @State private var copiedButtonId: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text(screenName)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            HStack(alignment: .top, spacing: 40) {
                // Generator Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Generate UUIDs")
                        .font(.headline)
                    
                    // UUID Version Selection
                    Picker("Version", selection: $selectedVersion) {
                        ForEach(UUIDVersion.allCases, id: \.self) { version in
                            Text(version.title)
                                .tag(version)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // Format Selection
                    Picker("Format", selection: $uuidFormat) {
                        ForEach(UUIDFormat.allCases, id: \.self) { format in
                            Text(format.title)
                                .tag(format)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    // Bulk Generation
                    HStack {
                        Text("Count:")
                        Stepper(value: $bulkCount, in: 1...100) {
                            Text("\(bulkCount)")
                        }
                        .frame(width: 100)
                    }
                    
                    // Generate Button
                    Button("Generate UUID\(bulkCount > 1 ? "s" : "")") {
                        generateUUIDs()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    // Generated UUIDs List
                    ScrollView {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(generatedUUIDs, id: \.self) { uuid in
                                HStack {
                                    Text(uuid)
                                        .font(.system(.body, design: .monospaced))
                                        .textSelection(.enabled)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        copyToClipboard(uuid)
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            copiedButtonId = uuid
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                copiedButtonId = nil
                                            }
                                        }
                                    }) {
                                        Image(systemName: copiedButtonId == uuid ? "checkmark" : "doc.on.doc")
                                            .foregroundColor(copiedButtonId == uuid ? .green : .blue)
                                            .font(.caption)
                                    }
                                    .buttonStyle(.borderless)
                                    .help("Copy to clipboard")
                                }
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                            }
                        }
                    }
                    .frame(height: 130)
                    
                    if !generatedUUIDs.isEmpty {
                        Button("Copy All") {
                            let allUUIDs = generatedUUIDs.joined(separator: "\n")
                            copyToClipboard(allUUIDs)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // Validation Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Validate UUID")
                        .font(.headline)
                    
                    TextField("Enter UUID to validate", text: $validationInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: validationInput) { _, newValue in
                            validateUUID(newValue)
                        }
                    
                    ScrollView {
                        Text(validationResult.isEmpty ? "Validation result will appear here" : validationResult)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .textSelection(.enabled)
                    }
                    .frame(minHeight: 100, maxHeight: 192)
                    
                    // Common UUID Patterns
                    Text("Common Patterns:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(commonPatterns, id: \.name) { pattern in
                            Button(pattern.name) {
                                validationInput = pattern.example
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.blue)
                        }
                    }
                }
            }
            .padding(.horizontal, 0)

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
    
    private func generateUUIDs() {
        generatedUUIDs.removeAll()
        
        for _ in 0..<bulkCount {
            let uuid: UUID
            
            switch selectedVersion {
            case .v7:
                uuid = generateUUIDv7()
            default:
                uuid = UUID() // Standard v4 UUID
            }
            
            let formattedUUID = formatUUID(uuid, format: uuidFormat)
            generatedUUIDs.append(formattedUUID)
        }
    }
    
    private func generateUUIDv7() -> UUID {
        // UUID v7 format:
        // 48 bits: Unix timestamp in milliseconds
        // 12 bits: Random data for sub-millisecond precision
        // 4 bits: Version (0111 for v7)
        // 62 bits: Random data
        // 2 bits: Variant (10)
        
        let now = Date()
        let timestamp = UInt64(now.timeIntervalSince1970 * 1000) // milliseconds since epoch
        
        // Generate random bytes
        var randomBytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        
        // Set timestamp (first 48 bits / 6 bytes)
        randomBytes[0] = UInt8((timestamp >> 40) & 0xFF)
        randomBytes[1] = UInt8((timestamp >> 32) & 0xFF)
        randomBytes[2] = UInt8((timestamp >> 24) & 0xFF)
        randomBytes[3] = UInt8((timestamp >> 16) & 0xFF)
        randomBytes[4] = UInt8((timestamp >> 8) & 0xFF)
        randomBytes[5] = UInt8(timestamp & 0xFF)
        
        // Set version (4 bits at position 6, upper nibble) - version 7
        randomBytes[6] = (randomBytes[6] & 0x0F) | 0x70
        
        // Set variant (2 bits at position 8, upper 2 bits) - variant 10
        randomBytes[8] = (randomBytes[8] & 0x3F) | 0x80
        
        // Create UUID from bytes
        let uuidBytes = (randomBytes[0], randomBytes[1], randomBytes[2], randomBytes[3],
                        randomBytes[4], randomBytes[5], randomBytes[6], randomBytes[7],
                        randomBytes[8], randomBytes[9], randomBytes[10], randomBytes[11],
                        randomBytes[12], randomBytes[13], randomBytes[14], randomBytes[15])
        
        return UUID(uuid: uuidBytes)
    }
    
    private func formatUUID(_ uuid: UUID, format: UUIDFormat) -> String {
        let uuidString = uuid.uuidString
        
        switch format {
        case .standard:
            return uuidString
        case .noHyphens:
            return uuidString.replacingOccurrences(of: "-", with: "")
        case .uppercase:
            return uuidString.uppercased()
        case .lowercase:
            return uuidString.lowercased()
        case .braces:
            return "{\(uuidString)}"
        }
    }
    
    private func validateUUID(_ input: String) {
        guard !input.isEmpty else {
            validationResult = ""
            return
        }
        
        let cleanedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove braces if present
        let uuidString = cleanedInput.hasPrefix("{") && cleanedInput.hasSuffix("}") 
            ? String(cleanedInput.dropFirst().dropLast())
            : cleanedInput
        
        // Check if it's a valid UUID format
        if let _ = UUID(uuidString: uuidString) {
            var result = """
            ✅ Valid UUID
            
            Format: \(detectFormat(cleanedInput))
            Length: \(cleanedInput.count) characters
            Version: \(detectVersion(uuidString))
            """
            
            // Add timestamp information for UUID v7
            if let timestampInfo = extractTimestampFromUUIDv7(uuidString) {
                result += "\n\n📅 Timestamp Information:\n\(timestampInfo)"
            }
            
            validationResult = result
        } else {
            validationResult = """
            ❌ Invalid UUID
            
            A valid UUID should be in format:
            XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
            
            Where X is a hexadecimal digit (0-9, A-F)
            """
        }
    }
    
    private func detectFormat(_ input: String) -> String {
        if input.hasPrefix("{") && input.hasSuffix("}") {
            return "Braces"
        } else if input.contains("-") {
            return input.uppercased() == input ? "Standard (Uppercase)" : "Standard (Lowercase)"
        } else {
            return "No Hyphens"
        }
    }
    
    private func detectVersion(_ uuidString: String) -> String {
        let versionIndex = uuidString.index(uuidString.startIndex, offsetBy: 14)
        let versionChar = uuidString[versionIndex]
        
        switch versionChar {
        case "1":
            return "Version 1 (Time-based)"
        case "4":
            return "Version 4 (Random)"
        case "5":
            return "Version 5 (Name-based SHA-1)"
        case "7":
            return "Version 7 (Timestamp-ordered)"
        default:
            return "Version \(versionChar)"
        }
    }
    
    private func extractTimestampFromUUIDv7(_ uuidString: String) -> String? {
        // Check if it's a v7 UUID
        let versionIndex = uuidString.index(uuidString.startIndex, offsetBy: 14)
        let versionChar = uuidString[versionIndex]
        
        guard versionChar == "7" else {
            return nil
        }
        
        // Extract the first 48 bits (12 hex characters) as timestamp
        let cleanUUID = uuidString.replacingOccurrences(of: "-", with: "")
        let timestampHex = String(cleanUUID.prefix(12))
        
        guard let timestamp = UInt64(timestampHex, radix: 16) else {
            return nil
        }
        
        // Convert from milliseconds to seconds
        let date = Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        formatter.timeZone = TimeZone.current
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return "\(formatter.string(from: date))\n\(isoFormatter.string(from: date))\nTimestamp: \(timestamp) ms"
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(text, forType: .string)
    }
    
    private func saveState() {
        let defaults = UserDefaults.standard
        defaults.set(selectedVersion.title, forKey: "UUIDGenerator.selectedVersion")
        defaults.set(uuidFormat.title, forKey: "UUIDGenerator.uuidFormat")
        defaults.set(bulkCount, forKey: "UUIDGenerator.bulkCount")
        defaults.set(validationInput, forKey: "UUIDGenerator.validationInput")
        defaults.set(generatedUUIDs, forKey: "UUIDGenerator.generatedUUIDs")
    }
    
    private func loadState() {
        let defaults = UserDefaults.standard
        
        if let versionTitle = defaults.string(forKey: "UUIDGenerator.selectedVersion") {
            selectedVersion = UUIDVersion.allCases.first { $0.title == versionTitle } ?? .v4
        }
        
        if let formatTitle = defaults.string(forKey: "UUIDGenerator.uuidFormat") {
            uuidFormat = UUIDFormat.allCases.first { $0.title == formatTitle } ?? .standard
        }
        
        bulkCount = defaults.integer(forKey: "UUIDGenerator.bulkCount")
        if bulkCount == 0 { bulkCount = 1 }
        
        validationInput = defaults.string(forKey: "UUIDGenerator.validationInput") ?? ""
        
        if let savedUUIDs = defaults.array(forKey: "UUIDGenerator.generatedUUIDs") as? [String] {
            generatedUUIDs = savedUUIDs
        }
        
        // If we have validation input, trigger validation
        if !validationInput.isEmpty {
            validateUUID(validationInput)
        }
        
        // If no saved UUIDs, generate initial ones
        if generatedUUIDs.isEmpty {
            generateUUIDs()
        }
    }
}

enum UUIDVersion: CaseIterable {
    case v1, v4, v5, v7
    
    var title: String {
        switch self {
        case .v1: return "V1"
        case .v4: return "V4"
        case .v5: return "V5"
        case .v7: return "V7"
        }
    }
}

enum UUIDFormat: CaseIterable {
    case standard, noHyphens, uppercase, lowercase, braces
    
    var title: String {
        switch self {
        case .standard: return "Standard"
        case .noHyphens: return "No Hyphens"
        case .uppercase: return "Uppercase"
        case .lowercase: return "Lowercase"
        case .braces: return "Braces"
        }
    }
}

struct UUIDPattern {
    let name: String
    let example: String
}

private let commonPatterns = [
    UUIDPattern(name: "Standard UUID", example: "550e8400-e29b-41d4-a716-446655440000"),
    UUIDPattern(name: "UUID v7 Sample", example: "01912345-6789-7abc-def0-123456789abc"),
    UUIDPattern(name: "No Hyphens", example: "550e8400e29b41d4a716446655440000"),
    UUIDPattern(name: "With Braces", example: "{550e8400-e29b-41d4-a716-446655440000}"),
    UUIDPattern(name: "Nil UUID", example: "00000000-0000-0000-0000-000000000000")
]

#Preview {
    UUIDGeneratorView()
}