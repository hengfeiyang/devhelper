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

struct JSONFormatterView: View {
    let screenName = "JSON Formatter"
    @State private var jsonInput: String = ""
    @State private var jsonInput2: String = ""
    @State private var jsonOutput: String = ""
    @State private var selectedMode: JSONMode = .format
    @State private var validationMessage: String = ""
    @State private var isValid: Bool = true
    
    var body: some View {
        VStack(spacing: 20) {
            Text(screenName)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Mode Selection
            Picker("Mode", selection: $selectedMode) {
                ForEach(JSONMode.allCases, id: \.self) { mode in
                    Text(mode.title)
                        .tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedMode) { _, _ in
                processJSON()
            }
            
            if selectedMode == .diff {
                // Diff Mode Layout - Three columns
                HStack(alignment: .top, spacing: 15) {
                    // Left JSON Input
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("JSON 1 (Original)")
                                .font(.headline)
                            Spacer()
                            Button("Clear") {
                                jsonInput = ""
                                processJSON()
                            }
                            .buttonStyle(.borderless)
                        }
                        
                        CodeEditor.json(text: $jsonInput)
                            .padding(5)
                            .frame(maxHeight: .infinity)
                            .onChange(of: jsonInput) { _, _ in
                                processJSON()
                            }
                        
                        Text("\(jsonInput.count) characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Right JSON Input
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("JSON 2 (Comparison)")
                                .font(.headline)
                            Spacer()
                            Button("Clear") {
                                jsonInput2 = ""
                                processJSON()
                            }
                            .buttonStyle(.borderless)
                        }
                        
                        CodeEditor.json(text: $jsonInput2)
                            .padding(5)
                            .frame(maxHeight: .infinity)
                            .onChange(of: jsonInput2) { _, _ in
                                processJSON()
                            }
                        
                        Text("\(jsonInput2.count) characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Diff Results
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Differences")
                                .font(.headline)
                            Spacer()
                            Button("Copy") {
                                copyToClipboard(jsonOutput)
                            }
                            .buttonStyle(.borderless)
                            .disabled(jsonOutput.isEmpty)
                        }
                        
                        ScrollView {
                            Text(jsonOutput.isEmpty ? "Differences will appear here" : jsonOutput)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        .padding(5)
                        .frame(maxHeight: .infinity)
                        .background(AppConstants.lightGrayBackground)
                        .cornerRadius(8)
                        
                        if !validationMessage.isEmpty {
                            Text(validationMessage)
                                .font(.caption)
                                .foregroundColor(isValid ? .green : .red)
                        }
                    }
                }
                .padding(.horizontal, 0)
            } else {
                // Standard Mode Layout - Two columns
                HStack(alignment: .top, spacing: 20) {
                    // Input Section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("JSON Input")
                                .font(.headline)
                            Spacer()
                            Button("Clear") {
                                jsonInput = ""
                                jsonOutput = ""
                                validationMessage = ""
                            }
                            .buttonStyle(.borderless)
                        }
                        
                        CodeEditor.json(text: $jsonInput)
                            .padding(5)
                            .frame(maxHeight: .infinity)
                            .onChange(of: jsonInput) { _, _ in
                                processJSON()
                            }
                        
                        HStack {
                            Text("\(jsonInput.count) characters")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if !validationMessage.isEmpty {
                                Text(validationMessage)
                                    .font(.caption)
                                    .foregroundColor(isValid ? .green : .red)
                            }
                        }
                    }
                    
                    Image(systemName: "arrow.right")
                        .font(.title)
                        .foregroundColor(.blue)
                        .frame(maxHeight: .infinity, alignment: .center)
                    
                    // Output Section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("JSON Output")
                                .font(.headline)
                            Spacer()
                            Button("Copy") {
                                copyToClipboard(jsonOutput)
                            }
                            .buttonStyle(.borderless)
                            .disabled(jsonOutput.isEmpty)
                        }
                        
                        CodeEditor.json(text: .constant(jsonOutput.isEmpty ? "Formatted JSON will appear here" : jsonOutput), readOnly: true)
                            .padding(5)
                            .frame(maxHeight: .infinity)
                        
                        Text("\(jsonOutput.count) characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 0)
            }
            
            // Action Buttons
            HStack(spacing: 20) {
                Button("Sample") {
                    if selectedMode == .diff {
                        jsonInput = sampleJSON1
                        jsonInput2 = sampleJSON2
                    } else {
                        jsonInput = sampleJSON
                    }
                    processJSON()
                }
                .buttonStyle(.bordered)
                
                Button("Format") {
                    selectedMode = .format
                    processJSON()
                }
                .buttonStyle(.bordered)
                
                Button("Minify") {
                    selectedMode = .minify
                    processJSON()
                }
                .buttonStyle(.bordered)
                
                Button("Validate") {
                    selectedMode = .validate
                    processJSON()
                }
                .buttonStyle(.bordered)
                
                Button("Escape") {
                    selectedMode = .escape
                    processJSON()
                }
                .buttonStyle(.bordered)
                
                Button("Unescape") {
                    selectedMode = .unescape
                    processJSON()
                }
                .buttonStyle(.bordered)
                
                Button("Diff") {
                    selectedMode = .diff
                    processJSON()
                }
                .buttonStyle(.bordered)
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
    
    private func processJSON() {
        guard !jsonInput.isEmpty else {
            jsonOutput = ""
            validationMessage = ""
            return
        }
        
        switch selectedMode {
        case .format:
            formatJSON()
        case .minify:
            minifyJSON()
        case .validate:
            validateJSON()
        case .escape:
            escapeJSON()
        case .unescape:
            unescapeJSON()
        case .diff:
            diffJSON()
        }
    }
    
    private func formatJSON() {
        guard let data = jsonInput.data(using: .utf8) else {
            jsonOutput = "Error: Unable to process input"
            isValid = false
            return
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            let formattedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])
            jsonOutput = String(data: formattedData, encoding: .utf8) ?? "Error: Unable to format JSON"
            isValid = true
            validationMessage = "✅ Valid JSON"
        } catch {
            let errorDetails = parseJSONError(error, input: jsonInput)
            jsonOutput = errorDetails
            isValid = false
            validationMessage = "❌ Invalid JSON"
        }
    }
    
    private func minifyJSON() {
        guard let data = jsonInput.data(using: .utf8) else {
            jsonOutput = "Error: Unable to process input"
            isValid = false
            return
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            let minifiedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
            jsonOutput = String(data: minifiedData, encoding: .utf8) ?? "Error: Unable to minify JSON"
            isValid = true
            validationMessage = "✅ Valid JSON (minified)"
        } catch {
            jsonOutput = "Error: \(error.localizedDescription)"
            isValid = false
            validationMessage = "❌ Invalid JSON"
        }
    }
    
    private func validateJSON() {
        guard let data = jsonInput.data(using: .utf8) else {
            jsonOutput = "❌ Invalid JSON: Unable to process input"
            isValid = false
            validationMessage = "❌ Invalid JSON"
            return
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            var info = "✅ Valid JSON\n\n"
            
            if let dictionary = jsonObject as? [String: Any] {
                info += "Type: Object\n"
                info += "Properties: \(dictionary.keys.count)\n"
                info += "Keys: \(dictionary.keys.sorted().joined(separator: ", "))"
            } else if let array = jsonObject as? [Any] {
                info += "Type: Array\n"
                info += "Items: \(array.count)"
            } else {
                info += "Type: \(type(of: jsonObject))"
            }
            
            jsonOutput = info
            isValid = true
            validationMessage = "✅ Valid JSON"
        } catch {
            let errorDetails = parseJSONError(error, input: jsonInput)
            jsonOutput = "❌ Invalid JSON\n\n\(errorDetails)"
            isValid = false
            validationMessage = "❌ Invalid JSON"
        }
    }
    
    private func escapeJSON() {
        let escapedJSON = jsonInput
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
        
        jsonOutput = "\"\(escapedJSON)\""
        isValid = true
        validationMessage = "JSON escaped for string use"
    }
    
    private func unescapeJSON() {
        var unescapedJSON = jsonInput
        
        // Remove outer quotes if present
        if unescapedJSON.hasPrefix("\"") && unescapedJSON.hasSuffix("\"") {
            unescapedJSON = String(unescapedJSON.dropFirst().dropLast())
        }
        
        // Unescape JSON escape sequences
        let unescaped = unescapedJSON
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\r", with: "\r")
            .replacingOccurrences(of: "\\t", with: "\t")
            .replacingOccurrences(of: "\\\"", with: "\"")
            .replacingOccurrences(of: "\\\\", with: "\\")
            .replacingOccurrences(of: "\\/", with: "/")
            .replacingOccurrences(of: "\\b", with: "\u{8}")
            .replacingOccurrences(of: "\\f", with: "\u{c}")
        
        // Handle unicode escape sequences \uXXXX
        var result = unescaped
        let unicodePattern = #"\\u([0-9a-fA-F]{4})"#
        if let regex = try? NSRegularExpression(pattern: unicodePattern) {
            let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))
            
            // Process matches in reverse order to maintain string indices
            for match in matches.reversed() {
                if let range = Range(match.range, in: result),
                   let hexRange = Range(match.range(at: 1), in: result) {
                    let hexString = String(result[hexRange])
                    if let unicodeValue = UInt32(hexString, radix: 16),
                       let unicodeScalar = UnicodeScalar(unicodeValue) {
                        result.replaceSubrange(range, with: String(Character(unicodeScalar)))
                    }
                }
            }
        }
        
        jsonOutput = result
        isValid = true
        validationMessage = "JSON unescaped from string format"
    }
    
    private func diffJSON() {
        // Handle empty inputs
        guard !jsonInput.isEmpty || !jsonInput2.isEmpty else {
            jsonOutput = ""
            validationMessage = "Enter JSON in both fields to compare"
            isValid = false
            return
        }
        
        if jsonInput.isEmpty {
            jsonOutput = "JSON 1 is empty"
            validationMessage = "JSON 1 is empty"
            isValid = false
            return
        }
        
        if jsonInput2.isEmpty {
            jsonOutput = "JSON 2 is empty"
            validationMessage = "JSON 2 is empty"
            isValid = false
            return
        }
        
        // Parse both JSON inputs
        guard let data1 = jsonInput.data(using: .utf8),
              let data2 = jsonInput2.data(using: .utf8) else {
            jsonOutput = "Error: Unable to process input"
            validationMessage = "❌ Invalid input"
            isValid = false
            return
        }
        
        do {
            let json1 = try JSONSerialization.jsonObject(with: data1, options: [])
            let json2 = try JSONSerialization.jsonObject(with: data2, options: [])
            
            let differences = findDifferences(json1: json1, json2: json2, path: "")
            
            if differences.isEmpty {
                jsonOutput = "✅ JSONs are identical"
                validationMessage = "✅ No differences found"
                isValid = true
            } else {
                let diffReport = differences.joined(separator: "\n\n")
                jsonOutput = "❌ Found \(differences.count) difference(s):\n\n\(diffReport)"
                validationMessage = "❌ Found \(differences.count) difference(s)"
                isValid = false
            }
            
        } catch let error1 {
            // Try to parse second JSON to give more specific error
            do {
                _ = try JSONSerialization.jsonObject(with: data2, options: [])
                jsonOutput = "❌ JSON 1 is invalid\n\nError: \(error1.localizedDescription)"
                validationMessage = "❌ JSON 1 is invalid"
            } catch {
                jsonOutput = "❌ Both JSONs are invalid\n\nJSON 1 Error: \(error1.localizedDescription)\nJSON 2 Error: \(error.localizedDescription)"
                validationMessage = "❌ Both JSONs are invalid"
            }
            isValid = false
        }
    }
    
    private func findDifferences(json1: Any, json2: Any, path: String) -> [String] {
        var differences: [String] = []
        
        // Check if types are different
        let type1 = type(of: json1)
        let type2 = type(of: json2)
        
        if String(describing: type1) != String(describing: type2) {
            differences.append("📍 Path: \(path.isEmpty ? "root" : path)\n🔄 Type mismatch:\n   JSON 1: \(String(describing: type1))\n   JSON 2: \(String(describing: type2))")
            return differences
        }
        
        // Compare based on type
        if let dict1 = json1 as? [String: Any], let dict2 = json2 as? [String: Any] {
            differences.append(contentsOf: compareDictionaries(dict1: dict1, dict2: dict2, path: path))
        } else if let array1 = json1 as? [Any], let array2 = json2 as? [Any] {
            differences.append(contentsOf: compareArrays(array1: array1, array2: array2, path: path))
        } else {
            // Compare primitive values
            let value1Str = formatValue(json1)
            let value2Str = formatValue(json2)
            
            if value1Str != value2Str {
                differences.append("📍 Path: \(path.isEmpty ? "root" : path)\n🔄 Value changed:\n   JSON 1: \(value1Str)\n   JSON 2: \(value2Str)")
            }
        }
        
        return differences
    }
    
    private func compareDictionaries(dict1: [String: Any], dict2: [String: Any], path: String) -> [String] {
        var differences: [String] = []
        
        // Find keys only in dict1 (removed keys)
        let onlyInDict1 = Set(dict1.keys).subtracting(Set(dict2.keys))
        for key in onlyInDict1.sorted() {
            let keyPath = path.isEmpty ? key : "\(path).\(key)"
            differences.append("📍 Path: \(keyPath)\n➖ Removed from JSON 2:\n   \(formatValue(dict1[key]!))")
        }
        
        // Find keys only in dict2 (added keys)
        let onlyInDict2 = Set(dict2.keys).subtracting(Set(dict1.keys))
        for key in onlyInDict2.sorted() {
            let keyPath = path.isEmpty ? key : "\(path).\(key)"
            differences.append("📍 Path: \(keyPath)\n➕ Added in JSON 2:\n   \(formatValue(dict2[key]!))")
        }
        
        // Compare common keys
        let commonKeys = Set(dict1.keys).intersection(Set(dict2.keys))
        for key in commonKeys.sorted() {
            let keyPath = path.isEmpty ? key : "\(path).\(key)"
            differences.append(contentsOf: findDifferences(json1: dict1[key]!, json2: dict2[key]!, path: keyPath))
        }
        
        return differences
    }
    
    private func compareArrays(array1: [Any], array2: [Any], path: String) -> [String] {
        var differences: [String] = []
        
        if array1.count != array2.count {
            differences.append("📍 Path: \(path.isEmpty ? "root" : path)\n📏 Array length changed:\n   JSON 1: \(array1.count) items\n   JSON 2: \(array2.count) items")
        }
        
        let maxCount = max(array1.count, array2.count)
        for i in 0..<maxCount {
            let indexPath = path.isEmpty ? "[\(i)]" : "\(path)[\(i)]"
            
            if i >= array1.count {
                differences.append("📍 Path: \(indexPath)\n➕ Added in JSON 2:\n   \(formatValue(array2[i]))")
            } else if i >= array2.count {
                differences.append("📍 Path: \(indexPath)\n➖ Removed from JSON 2:\n   \(formatValue(array1[i]))")
            } else {
                differences.append(contentsOf: findDifferences(json1: array1[i], json2: array2[i], path: indexPath))
            }
        }
        
        return differences
    }
    
    private func formatValue(_ value: Any) -> String {
        if let str = value as? String {
            return "\"\(str)\""
        } else if let num = value as? NSNumber {
            // Check if it's a boolean
            if CFBooleanGetTypeID() == CFGetTypeID(num) {
                return num.boolValue ? "true" : "false"
            }
            return "\(num)"
        } else if value is NSNull {
            return "null"
        } else if let dict = value as? [String: Any] {
            return "{ \(dict.count) properties }"
        } else if let array = value as? [Any] {
            return "[ \(array.count) items ]"
        } else {
            return "\(value)"
        }
    }
    
    private func parseJSONError(_ error: Error, input: String) -> String {
        let nsError = error as NSError
        var errorMessage = "Error parsing JSON:\n\n"
        
        // Try to extract line and character position from the error
        if let debugDescription = nsError.userInfo[NSDebugDescriptionErrorKey] as? String {
            // Look for character position in the debug description
            if let charRange = debugDescription.range(of: "character ") {
                let afterChar = debugDescription[charRange.upperBound...]
                if let endRange = afterChar.firstIndex(where: { !$0.isNumber }) {
                    let charPositionStr = afterChar[..<endRange]
                    if let charPosition = Int(charPositionStr) {
                        let (line, column, context) = findLineAndColumn(in: input, at: charPosition)
                        errorMessage += "📍 Error at Line \(line), Column \(column)\n"
                        errorMessage += "\n\(context)\n\n"
                    }
                }
            }
            
            // Add the original error description
            errorMessage += "Details: \(debugDescription)"
        } else {
            // Fallback to basic error description
            errorMessage += error.localizedDescription
            
            // Try to identify common JSON errors by analyzing the input
            if let errorDetail = analyzeJSONError(input) {
                errorMessage += "\n\n" + errorDetail
            }
        }
        
        return errorMessage
    }
    
    private func findLineAndColumn(in text: String, at position: Int) -> (line: Int, column: Int, context: String) {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        var currentPosition = 0
        var lineNumber = 1
        
        for line in lines {
            let lineLength = line.count + 1 // +1 for the newline
            if currentPosition + lineLength > position {
                let column = position - currentPosition + 1
                
                // Create context with error pointer
                var context = ""
                
                // Show previous line if exists
                if lineNumber > 1 && lineNumber <= lines.count {
                    let prevLine = lines[lineNumber - 2]
                    context += "\(lineNumber - 1): \(prevLine)\n"
                }
                
                // Show current line with error indicator
                context += "\(lineNumber): \(line)\n"
                context += String(repeating: " ", count: String(lineNumber).count + 2 + column - 1) + "^ Error here"
                
                // Show next line if exists
                if lineNumber < lines.count {
                    let nextLine = lines[lineNumber]
                    context += "\n\(lineNumber + 1): \(nextLine)"
                }
                
                return (lineNumber, column, context)
            }
            currentPosition += lineLength
            lineNumber += 1
        }
        
        return (lineNumber, 1, "Position out of range")
    }
    
    private func analyzeJSONError(_ input: String) -> String? {
        var issues: [String] = []
        
        // Check for common JSON errors
        let lines = input.split(separator: "\n", omittingEmptySubsequences: false)
        
        for (index, line) in lines.enumerated() {
            let lineNum = index + 1
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Check for trailing commas
            if trimmedLine.hasSuffix(",}") || trimmedLine.hasSuffix(",]") {
                issues.append("⚠️ Line \(lineNum): Trailing comma before closing bracket")
            }
            
            // Check for single quotes (JSON requires double quotes)
            if trimmedLine.contains("'") {
                // Rough check - might have false positives
                let singleQuoteCount = trimmedLine.filter { $0 == "'" }.count
                if singleQuoteCount % 2 == 0 && singleQuoteCount > 0 {
                    issues.append("⚠️ Line \(lineNum): JSON requires double quotes, not single quotes")
                }
            }
            
            // Check for missing quotes on keys
            if trimmedLine.contains(":") && !trimmedLine.hasPrefix("//") {
                let beforeColon = trimmedLine.split(separator: ":").first ?? ""
                let trimmedKey = beforeColon.trimmingCharacters(in: .whitespaces)
                if !trimmedKey.isEmpty && !trimmedKey.hasPrefix("\"") && !trimmedKey.hasPrefix("{") && !trimmedKey.hasPrefix("[") {
                    issues.append("⚠️ Line \(lineNum): Object keys must be quoted")
                }
            }
            
            // Check for unclosed strings
            let quoteCount = trimmedLine.filter { $0 == "\"" }.count
            let escapedQuoteCount = trimmedLine.components(separatedBy: "\\\"").count - 1
            let unescapedQuotes = quoteCount - escapedQuoteCount
            if unescapedQuotes % 2 != 0 {
                issues.append("⚠️ Line \(lineNum): Unclosed string (odd number of quotes)")
            }
        }
        
        // Check for unmatched brackets
        let openBraces = input.filter { $0 == "{" }.count
        let closeBraces = input.filter { $0 == "}" }.count
        if openBraces != closeBraces {
            issues.append("⚠️ Unmatched braces: \(openBraces) { vs \(closeBraces) }")
        }
        
        let openBrackets = input.filter { $0 == "[" }.count
        let closeBrackets = input.filter { $0 == "]" }.count
        if openBrackets != closeBrackets {
            issues.append("⚠️ Unmatched brackets: \(openBrackets) [ vs \(closeBrackets) ]")
        }
        
        return issues.isEmpty ? nil : "Possible issues:\n" + issues.joined(separator: "\n")
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(text, forType: .string)
    }
    
    private func saveState() {
        let defaults = UserDefaults.standard
        defaults.set(jsonInput, forKey: "JSONFormatter.jsonInput")
        defaults.set(jsonInput2, forKey: "JSONFormatter.jsonInput2")
        defaults.set(jsonOutput, forKey: "JSONFormatter.jsonOutput")
        defaults.set(selectedMode.title, forKey: "JSONFormatter.selectedMode")
        defaults.set(validationMessage, forKey: "JSONFormatter.validationMessage")
        defaults.set(isValid, forKey: "JSONFormatter.isValid")
    }
    
    private func loadState() {
        let defaults = UserDefaults.standard
        jsonInput = defaults.string(forKey: "JSONFormatter.jsonInput") ?? ""
        jsonInput2 = defaults.string(forKey: "JSONFormatter.jsonInput2") ?? ""
        jsonOutput = defaults.string(forKey: "JSONFormatter.jsonOutput") ?? ""
        validationMessage = defaults.string(forKey: "JSONFormatter.validationMessage") ?? ""
        isValid = defaults.bool(forKey: "JSONFormatter.isValid")
        
        if let modeTitle = defaults.string(forKey: "JSONFormatter.selectedMode") {
            selectedMode = JSONMode.allCases.first { $0.title == modeTitle } ?? .format
        }
        
        // If we have input, trigger processing
        if !jsonInput.isEmpty || !jsonInput2.isEmpty {
            processJSON()
        }
    }
}

enum JSONMode: CaseIterable {
    case format, minify, validate, escape, unescape, diff
    
    var title: String {
        switch self {
        case .format: return "Format"
        case .minify: return "Minify"
        case .validate: return "Validate"
        case .escape: return "Escape"
        case .unescape: return "Unescape"
        case .diff: return "Diff"
        }
    }
}

private let sampleJSON = """
{
  "name": "John Doe",
  "age": 30,
  "isActive": true,
  "address": {
    "street": "123 Main St",
    "city": "New York",
    "zipCode": "10001"
  },
  "hobbies": ["reading", "coding", "hiking"],
  "contact": {
    "email": "john@example.com",
    "phone": null
  }
}
"""

private let sampleJSON1 = """
{
  "name": "John Doe",
  "age": 30,
  "isActive": true,
  "address": {
    "street": "123 Main St",
    "city": "New York",
    "zipCode": "10001"
  },
  "hobbies": ["reading", "coding", "hiking"],
  "contact": {
    "email": "john@example.com",
    "phone": null
  }
}
"""

private let sampleJSON2 = """
{
  "name": "Jane Smith",
  "age": 28,
  "isActive": true,
  "address": {
    "street": "456 Oak Ave",
    "city": "San Francisco",
    "zipCode": "94102",
    "country": "USA"
  },
  "hobbies": ["reading", "photography", "traveling"],
  "contact": {
    "email": "jane@example.com",
    "phone": "+1-555-0123"
  },
  "preferences": {
    "theme": "dark",
    "notifications": true
  }
}
"""

#Preview {
    JSONFormatterView()
}
