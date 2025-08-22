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

struct Base64View: View {
    let screenName = "Base64 Encode/Decode"
    @State private var textInput: String = ""
    @State private var base64Output: String = ""
    @State private var base64Input: String = ""
    @State private var decodedOutput: String = ""
    @State private var isURLSafe: Bool = false
    @State private var processLineByLine: Bool = false
    @State private var selectedTab: Base64Tab = .encode
    
    var body: some View {
        VStack(spacing: 20) {
            Text(screenName)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Tab Selection
            Picker("Mode", selection: $selectedTab) {
                ForEach(Base64Tab.allCases, id: \.self) { tab in
                    Text(tab.title)
                        .tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            
            HStack(alignment: .top, spacing: 20) {
                if selectedTab == .encode {
                    // Encode Section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Text Input")
                                .font(.headline)
                            Spacer()
                            Button("Clear") {
                                textInput = ""
                                base64Output = ""
                            }
                            .buttonStyle(.borderless)
                        }
                        
                        TextEditor(text: $textInput)
                            .padding(5)
                            .frame(maxHeight: .infinity)
                            .onChange(of: textInput) { _, _ in
                                encodeText()
                            }
                        
                        Text("\(textInput.count) characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: "arrow.right")
                        .font(.title)
                        .foregroundColor(.blue)
                        .frame(maxHeight: .infinity, alignment: .center)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Base64 Output")
                                .font(.headline)
                            Spacer()
                            Button("Copy") {
                                copyToClipboard(base64Output)
                            }
                            .buttonStyle(.borderless)
                            .disabled(base64Output.isEmpty)
                        }
                        
                        ScrollView {
                            Text(base64Output.isEmpty ? "Base64 encoded text will appear here" : base64Output)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        .padding(5)
                        .frame(maxHeight: .infinity)
                        .background(AppConstants.lightGrayBackground)
                        .cornerRadius(8)
                        
                        Text("\(base64Output.count) characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    // Decode Section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Base64 Input")
                                .font(.headline)
                            Spacer()
                            Button("Clear") {
                                base64Input = ""
                                decodedOutput = ""
                            }
                            .buttonStyle(.borderless)
                        }
                        
                        TextEditor(text: $base64Input)
                            .padding(5)
                            .frame(maxHeight: .infinity)
                            .onChange(of: base64Input) { _, _ in
                                decodeBase64()
                            }
                        
                        Text("\(base64Input.count) characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: "arrow.right")
                        .font(.title)
                        .foregroundColor(.blue)
                        .frame(maxHeight: .infinity, alignment: .center)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Decoded Output")
                                .font(.headline)
                            Spacer()
                            Button("Copy") {
                                copyToClipboard(decodedOutput)
                            }
                            .buttonStyle(.borderless)
                            .disabled(decodedOutput.isEmpty)
                        }
                        
                        ScrollView {
                            Text(decodedOutput.isEmpty ? "Decoded text will appear here" : decodedOutput)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        .padding(5)
                        .frame(maxHeight: .infinity)
                        .background(AppConstants.lightGrayBackground)
                        .cornerRadius(8)
                        
                        Text("\(decodedOutput.count) characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 0)
            
            // Additional Tools
            HStack(spacing: 20) {
                Button("Sample") {
                    if selectedTab == .encode {
                        if processLineByLine {
                            textInput = "Hello, World!\nThis is line 2\nAnd this is line 3"
                        } else {
                            textInput = "Hello, World! This is a sample text for Base64 encoding."
                        }
                    } else {
                        if processLineByLine {
                            base64Input = "SGVsbG8sIFdvcmxkIQ==\nVGhpcyBpcyBsaW5lIDI=\nQW5kIHRoaXMgaXMgbGluZSAz"
                        } else {
                            base64Input = "SGVsbG8sIFdvcmxkISBUaGlzIGlzIGEgc2FtcGxlIHRleHQgZm9yIEJhc2U2NCBlbmNvZGluZy4="
                        }
                    }
                }
                .buttonStyle(.bordered)
                
                Button("Swap") {
                    if selectedTab == .encode && !base64Output.isEmpty {
                        base64Input = base64Output
                        selectedTab = .decode
                    } else if selectedTab == .decode && !decodedOutput.isEmpty {
                        textInput = decodedOutput
                        selectedTab = .encode
                    }
                }
                .buttonStyle(.bordered)
                .disabled((selectedTab == .encode && base64Output.isEmpty) || 
                         (selectedTab == .decode && decodedOutput.isEmpty))
                
                Spacer()
                
                Toggle("Line-by-Line", isOn: $processLineByLine)
                    .onChange(of: processLineByLine) { _, _ in
                        if selectedTab == .encode {
                            encodeText()
                        } else {
                            decodeBase64()
                        }
                    }
                
                
                Toggle("URL-Safe Base64", isOn: $isURLSafe)
                    .onChange(of: isURLSafe) { _, _ in
                        if selectedTab == .encode {
                            encodeText()
                        } else {
                            decodeBase64()
                        }
                    }
            }
            
            Spacer()
        }
        .padding()
        .onChange(of: selectedTab) { _, _ in
            if selectedTab == .encode {
                encodeText()
            } else {
                decodeBase64()
            }
        }
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
    
    private func encodeText() {
        guard !textInput.isEmpty else {
            base64Output = ""
            return
        }
        
        if processLineByLine {
            let lines = textInput.components(separatedBy: .newlines)
            let encodedLines = lines.map { line -> String in
                guard !line.isEmpty else { return "" }
                guard let data = line.data(using: .utf8) else {
                    return "Error: Unable to encode line"
                }
                
                if isURLSafe {
                    let base64 = data.base64EncodedString()
                    return base64
                        .replacingOccurrences(of: "+", with: "-")
                        .replacingOccurrences(of: "/", with: "_")
                        .replacingOccurrences(of: "=", with: "")
                } else {
                    return data.base64EncodedString()
                }
            }
            base64Output = encodedLines.joined(separator: "\n")
        } else {
            guard let data = textInput.data(using: .utf8) else {
                base64Output = "Error: Unable to encode text"
                return
            }
            
            if isURLSafe {
                let base64 = data.base64EncodedString()
                base64Output = base64
                    .replacingOccurrences(of: "+", with: "-")
                    .replacingOccurrences(of: "/", with: "_")
                    .replacingOccurrences(of: "=", with: "")
            } else {
                base64Output = data.base64EncodedString()
            }
        }
    }
    
    private func decodeBase64() {
        guard !base64Input.isEmpty else {
            decodedOutput = ""
            return
        }
        
        if processLineByLine {
            let lines = base64Input.components(separatedBy: .newlines)
            let decodedLines = lines.map { line -> String in
                guard !line.isEmpty else { return "" }
                
                var base64String = line.trimmingCharacters(in: .whitespaces)
                
                if isURLSafe {
                    // Convert URL-safe Base64 to standard Base64
                    base64String = base64String
                        .replacingOccurrences(of: "-", with: "+")
                        .replacingOccurrences(of: "_", with: "/")
                    
                    // Add padding if needed
                    while base64String.count % 4 != 0 {
                        base64String += "="
                    }
                }
                
                guard let data = Data(base64Encoded: base64String) else {
                    return "Error: Invalid Base64 input"
                }
                
                if let decodedString = String(data: data, encoding: .utf8) {
                    return decodedString
                } else {
                    return "Error: Unable to decode as UTF-8 text"
                }
            }
            decodedOutput = decodedLines.joined(separator: "\n")
        } else {
            var base64String = base64Input.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if isURLSafe {
                // Convert URL-safe Base64 to standard Base64
                base64String = base64String
                    .replacingOccurrences(of: "-", with: "+")
                    .replacingOccurrences(of: "_", with: "/")
                
                // Add padding if needed
                while base64String.count % 4 != 0 {
                    base64String += "="
                }
            }
            
            guard let data = Data(base64Encoded: base64String) else {
                decodedOutput = "Error: Invalid Base64 input"
                return
            }
            
            if let decodedString = String(data: data, encoding: .utf8) {
                decodedOutput = decodedString
            } else {
                decodedOutput = "Error: Unable to decode as UTF-8 text"
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(text, forType: .string)
    }
    
    private func saveState() {
        let defaults = UserDefaults.standard
        defaults.set(textInput, forKey: "Base64.textInput")
        defaults.set(base64Input, forKey: "Base64.base64Input")
        defaults.set(base64Output, forKey: "Base64.base64Output")
        defaults.set(decodedOutput, forKey: "Base64.decodedOutput")
        defaults.set(selectedTab.title, forKey: "Base64.selectedTab")
        defaults.set(isURLSafe, forKey: "Base64.isURLSafe")
        defaults.set(processLineByLine, forKey: "Base64.processLineByLine")
    }
    
    private func loadState() {
        let defaults = UserDefaults.standard
        textInput = defaults.string(forKey: "Base64.textInput") ?? ""
        base64Input = defaults.string(forKey: "Base64.base64Input") ?? ""
        base64Output = defaults.string(forKey: "Base64.base64Output") ?? ""
        decodedOutput = defaults.string(forKey: "Base64.decodedOutput") ?? ""
        isURLSafe = defaults.bool(forKey: "Base64.isURLSafe")
        processLineByLine = defaults.bool(forKey: "Base64.processLineByLine")
        
        if let tabTitle = defaults.string(forKey: "Base64.selectedTab") {
            selectedTab = Base64Tab.allCases.first { $0.title == tabTitle } ?? .encode
        }
        
        // If we have input, trigger processing
        if selectedTab == .encode && !textInput.isEmpty {
            encodeText()
        } else if selectedTab == .decode && !base64Input.isEmpty {
            decodeBase64()
        }
    }
}

enum Base64Tab: CaseIterable {
    case encode, decode
    
    var title: String {
        switch self {
        case .encode: return "Encode"
        case .decode: return "Decode"
        }
    }
}

#Preview {
    Base64View()
}
