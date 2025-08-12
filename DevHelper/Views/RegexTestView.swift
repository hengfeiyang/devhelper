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

struct RegexTestView: View {
    let screenName = "Regex Test"
    @State private var regexPattern: String = ""
    @State private var testString: String = ""
    @State private var replacementString: String = ""
    @State private var selectedMode: RegexMode = .match
    @State private var selectedFlags: Set<RegexFlag> = []
    @State private var matchResults: [RegexMatch] = []
    @State private var replacementResult: String = ""
    @State private var errorMessage: String = ""
    @State private var isValidPattern: Bool = true
    
    var body: some View {
        VStack(spacing: 20) {
            Text(screenName)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Mode Selection
            Picker("Mode", selection: $selectedMode) {
                ForEach(RegexMode.allCases, id: \.self) { mode in
                    Text(mode.title)
                        .tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedMode) { _, _ in
                testRegex()
            }
            
            // Pattern Input
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Regular Expression Pattern")
                        .font(.headline)
                    Spacer()
                    Button("Clear") {
                        regexPattern = ""
                        clearResults()
                    }
                    .buttonStyle(.borderless)
                }
                
                TextField("Enter regex pattern (e.g., \\d+|[a-zA-Z]+)", text: $regexPattern)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: regexPattern) { _, _ in
                        testRegex()
                    }
                    .border(isValidPattern ? Color.clear : Color.red, width: 1)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Flags Selection
            HStack(alignment: .center, spacing: 20) {
                Text("Regex Options")
                    .font(.headline)
                
                ForEach(RegexFlag.allCases, id: \.self) { flag in
                    Toggle(flag.title, isOn: Binding(
                        get: { selectedFlags.contains(flag) },
                        set: { isOn in
                            if isOn {
                                selectedFlags.insert(flag)
                            } else {
                                selectedFlags.remove(flag)
                            }
                            testRegex()
                        }
                    ))
                    .toggleStyle(CheckboxToggleStyle())
                }
                
                Spacer()
            }
            
            HStack(alignment: .top, spacing: 20) {
                // Test String Input
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Test String")
                            .font(.headline)
                        Spacer()
                        Button("Sample") {
                            testString = sampleText
                            testRegex()
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    TextEditor(text: $testString)
                        .padding(5)
                        .frame(maxHeight: .infinity)
                        .onChange(of: testString) { _, _ in
                            testRegex()
                        }
                }
                
                // Results/Replacement
                VStack(alignment: .leading, spacing: 10) {
                    if selectedMode == .match {
                        HStack {
                            Text("Match Results")
                                .font(.headline)
                            Spacer()
                            if !matchResults.isEmpty {
                                Text("\(matchResults.count) matches")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 5) {
                                if matchResults.isEmpty {
                                    Text("No matches found")
                                        .foregroundColor(.secondary)
                                        .italic()
                                } else {
                                    ForEach(matchResults.indices, id: \.self) { index in
                                        matchResultRow(matchResults[index], index: index)
                                    }
                                }
                            }
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(5)
                        .frame(maxHeight: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    } else {
                        Text("Replacement")
                            .font(.headline)
                        
                        TextField("Replacement string", text: $replacementString)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(.body, design: .monospaced))
                            .onChange(of: replacementString) { _, _ in
                                testRegex()
                            }
                        
                        ScrollView {
                            Text(replacementResult.isEmpty ? "Replacement result will appear here" : replacementResult)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        .padding(5)
                        .frame(maxHeight: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            .padding(0)
            
            // Quick Patterns
            VStack(alignment: .leading, spacing: 10) {
                Text("Common Patterns")
                    .font(.headline)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                    ForEach(commonPatterns, id: \.name) { pattern in
                        Button(pattern.name) {
                            regexPattern = pattern.regex
                            testRegex()
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                AnalyticsParameterScreenName: screenName
            ])
        }
    }
    
    @ViewBuilder
    private func matchResultRow(_ match: RegexMatch, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Match \(index + 1):")
                    .fontWeight(.medium)
                Text(match.match)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
                Spacer()
                Button(action: {
                    copyToClipboard(match.match)
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
            
            HStack {
                Text("Range:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(match.range.lowerBound)-\(match.range.upperBound)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            if !match.groups.isEmpty {
                HStack {
                    Text("Groups:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ForEach(match.groups.indices, id: \.self) { groupIndex in
                        Text("$\(groupIndex + 1): \(match.groups[groupIndex])")
                            .font(.caption)
                            .padding(.horizontal, 4)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(4)
                    }
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.5))
        .cornerRadius(6)
    }
    
    private func testRegex() {
        guard !regexPattern.isEmpty else {
            clearResults()
            return
        }
        
        do {
            var options: NSRegularExpression.Options = []
            
            if selectedFlags.contains(.caseInsensitive) {
                options.insert(.caseInsensitive)
            }
            if selectedFlags.contains(.multiline) {
                options.insert(.anchorsMatchLines)
            }
            if selectedFlags.contains(.dotMatchesLineSeparators) {
                options.insert(.dotMatchesLineSeparators)
            }
            
            let regex = try NSRegularExpression(pattern: regexPattern, options: options)
            
            isValidPattern = true
            errorMessage = ""
            
            if selectedMode == .match {
                performMatching(with: regex)
            } else {
                performReplacement(with: regex)
            }
            
        } catch {
            isValidPattern = false
            errorMessage = "Invalid regex pattern: \(error.localizedDescription)"
            clearResults()
        }
    }
    
    private func performMatching(with regex: NSRegularExpression) {
        let nsString = testString as NSString
        let range = NSRange(location: 0, length: nsString.length)
        let matches = regex.matches(in: testString, options: [], range: range)
        
        matchResults = matches.map { match in
            let matchString = nsString.substring(with: match.range)
            let matchRange = match.range
            
            var groups: [String] = []
            for i in 1..<match.numberOfRanges {
                let groupRange = match.range(at: i)
                if groupRange.location != NSNotFound {
                    groups.append(nsString.substring(with: groupRange))
                }
            }
            
            return RegexMatch(
                match: matchString,
                range: matchRange.lowerBound..<matchRange.upperBound,
                groups: groups
            )
        }
    }
    
    private func performReplacement(with regex: NSRegularExpression) {
        let nsString = testString as NSString
        let range = NSRange(location: 0, length: nsString.length)
        
        let result = regex.stringByReplacingMatches(
            in: testString,
            options: [],
            range: range,
            withTemplate: replacementString
        )
        
        replacementResult = result
    }
    
    private func clearResults() {
        matchResults = []
        replacementResult = ""
        errorMessage = ""
        isValidPattern = true
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(text, forType: .string)
    }
}

enum RegexMode: CaseIterable {
    case match, replace
    
    var title: String {
        switch self {
        case .match: return "Match"
        case .replace: return "Replace"
        }
    }
}

enum RegexFlag: CaseIterable {
    case caseInsensitive, multiline, dotMatchesLineSeparators
    
    var title: String {
        switch self {
        case .caseInsensitive: return "Case Insensitive"
        case .multiline: return "Multiline"
        case .dotMatchesLineSeparators: return "Dot All"
        }
    }
    
    var description: String {
        switch self {
        case .caseInsensitive: return "Ignore uppercase/lowercase differences"
        case .multiline: return "^ and $ match start/end of lines"
        case .dotMatchesLineSeparators: return ". matches newline characters"
        }
    }
}

struct RegexMatch {
    let match: String
    let range: Range<Int>
    let groups: [String]
}

struct RegexPattern {
    let name: String
    let regex: String
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .blue : .secondary)
                .font(.system(size: 16))
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            configuration.label
                .font(.system(size: 12))
        }
    }
}

private let commonPatterns = [
    RegexPattern(name: "Email", regex: "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"),
    RegexPattern(name: "Phone", regex: "\\([0-9]{3}\\) [0-9]{3}-[0-9]{4}"),
    RegexPattern(name: "URL", regex: "https?://[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}"),
    RegexPattern(name: "IPv4", regex: "\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\b"),
    RegexPattern(name: "Hex Color", regex: "#[A-Fa-f0-9]{6}|#[A-Fa-f0-9]{3}"),
    RegexPattern(name: "Date", regex: "\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4}"),
    RegexPattern(name: "Time", regex: "\\d{1,2}:\\d{2}(?::\\d{2})?\\s?(?:AM|PM)?"),
    RegexPattern(name: "Numbers", regex: "\\d+"),
    RegexPattern(name: "Words", regex: "\\w+")
]

private let sampleText = """
Contact Information:
Email: john.doe@example.com
Phone: (555) 123-4567
Website: https://www.example.com
IP Address: 192.168.1.1

Date: 12/25/2023
Time: 3:30 PM
Hex Color: #FF5733

Some numbers: 123, 456, 789
Mixed text with UPPERCASE and lowercase words.
"""

#Preview {
    RegexTestView()
}
