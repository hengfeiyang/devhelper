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

struct URLToolsView: View {
    let screenName = "URL Tools"
    @State private var selectedTab: URLTab = .encoder
    @State private var textInput: String = ""
    @State private var encodedOutput: String = ""
    @State private var encodedInput: String = ""
    @State private var decodedOutput: String = ""
    @State private var urlInput: String = ""
    @State private var parsedComponents: URLComponents = URLComponents()
    @State private var queryParameters: [QueryParameter] = []
    @State private var useAlphanumericOnly: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(screenName)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Tab Selection
            Picker("Tool", selection: $selectedTab) {
                ForEach(URLTab.allCases, id: \.self) { tab in
                    Text(tab.title)
                        .tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            switch selectedTab {
            case .encoder:
                urlEncoderView()
            case .decoder:
                urlDecoderView()
            case .parser:
                urlParserView()
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
    
    @ViewBuilder
    private func urlEncoderView() -> some View {
        HStack(alignment: .top, spacing: 20) {
            // Input Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Text Input")
                        .font(.headline)
                    Spacer()
                    Button("Clear") {
                        textInput = ""
                        encodedOutput = ""
                    }
                    .buttonStyle(.borderless)
                }
                
                TextEditor(text: $textInput)
                    .padding(5)
                    .frame(maxHeight: .infinity)
                    .onChange(of: textInput) { _, _ in
                        encodeURL()
                    }
                
                HStack {
                    Text("\(textInput.count) characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    // Encoding options
                    Toggle("Alphanumeric Only", isOn: $useAlphanumericOnly)
                        .onChange(of: useAlphanumericOnly) { _, _ in
                            encodeURL()
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
                    Text("URL Encoded Output")
                        .font(.headline)
                    Spacer()
                    Button("Copy") {
                        copyToClipboard(encodedOutput)
                    }
                    .buttonStyle(.borderless)
                    .disabled(encodedOutput.isEmpty)
                }
                
                ScrollView {
                    Text(encodedOutput.isEmpty ? "URL encoded text will appear here" : encodedOutput)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .padding(5)
                .frame(maxHeight: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Text("\(encodedOutput.count) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 0)
        
        // Sample button
        HStack {
            Button("Sample") {
                textInput = "Hello World! @#$%^&*()+=[]{}|;:,.<>?"
                encodeURL()
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .padding(.horizontal, 0)
    }
    
    @ViewBuilder
    private func urlDecoderView() -> some View {
        HStack(alignment: .top, spacing: 20) {
            // Input Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("URL Encoded Input")
                        .font(.headline)
                    Spacer()
                    Button("Clear") {
                        encodedInput = ""
                        decodedOutput = ""
                    }
                    .buttonStyle(.borderless)
                }
                
                TextEditor(text: $encodedInput)
                    .padding(5)
                    .frame(maxHeight: .infinity)
                    .onChange(of: encodedInput) { _, _ in
                        decodeURL()
                    }
                
                Text("\(encodedInput.count) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Image(systemName: "arrow.right")
                .font(.title)
                .foregroundColor(.blue)
                .frame(maxHeight: .infinity, alignment: .center)
            
            // Output Section
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
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Text("\(decodedOutput.count) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 0)
        
        // Sample button
        HStack {
            Button("Sample") {
                encodedInput = "Hello%20World%21%20%40%23%24%25%5E%26%2A%28%29%2B%3D%5B%5D%7B%7D%7C%3B%3A%2C.%3C%3E%3F"
                decodeURL()
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .padding(.horizontal, 0)
    }
    
    @ViewBuilder
    private func urlParserView() -> some View {
        VStack(spacing: 20) {
            // URL Input
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("URL Input")
                        .font(.headline)
                    Spacer()
                    Button("Sample URL") {
                        urlInput = "https://api.example.com:8080/users?id=123&name=John%20Doe&active=true#section1"
                        parseURL()
                    }
                    .buttonStyle(.borderless)
                }
                
                TextField("Enter URL to parse", text: $urlInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: urlInput) { _, _ in
                        parseURL()
                    }
            }
            
            // Parsed Components
            HStack(spacing: 20) {
                // URL Components
                VStack(alignment: .leading, spacing: 15) {
                    Text("URL Components")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        componentRow("Scheme", parsedComponents.scheme ?? "")
                        componentRow("Host", parsedComponents.host ?? "")
                        componentRow("Port", parsedComponents.port?.description ?? "")
                        componentRow("Path", parsedComponents.path)
                        componentRow("Fragment", parsedComponents.fragment ?? "")
                    }
                    .font(.system(.body, design: .monospaced))
                }
                
                // Query Parameters
                VStack(alignment: .leading, spacing: 15) {
                    Text("Query Parameters")
                        .font(.headline)
                    
                    if queryParameters.isEmpty {
                        Text("No query parameters")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 5) {
                                ForEach(queryParameters.indices, id: \.self) { index in
                                    HStack {
                                        Text(queryParameters[index].key)
                                            .fontWeight(.medium)
                                        Text("=")
                                        Text(queryParameters[index].value)
                                        Spacer()
                                        Button(action: {
                                            copyToClipboard("\(queryParameters[index].key)=\(queryParameters[index].value)")
                                        }) {
                                            Image(systemName: "doc.on.doc")
                                                .foregroundColor(.blue)
                                        }
                                        .buttonStyle(.borderless)
                                        .font(.caption)
                                    }
                                    .font(.system(.body, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(4)
                                }
                            }
                        }
                        .frame(height: 150)
                    }
                }
            }
            .padding()
            
            // Reconstruct URL
            if !urlInput.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Reconstructed URL")
                        .font(.headline)
                    
                    HStack {
                        Text(reconstructURL())
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        
                        Button(action: {
                            copyToClipboard(reconstructURL())
                        }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func componentRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text("\(label):")
                .fontWeight(.medium)
                .frame(width: 80, alignment: .leading)
            Text(value.isEmpty ? "—" : value)
                .foregroundColor(value.isEmpty ? .secondary : .primary)
            Spacer()
            if !value.isEmpty {
                Button(action: {
                    copyToClipboard(value)
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(4)
    }
    
    private func encodeURL() {
        guard !textInput.isEmpty else {
            encodedOutput = ""
            return
        }
        
        let allowedCharacters: CharacterSet = useAlphanumericOnly ? .alphanumerics : .urlQueryAllowed
        encodedOutput = textInput.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? "Error: Unable to encode"
    }
    
    private func decodeURL() {
        guard !encodedInput.isEmpty else {
            decodedOutput = ""
            return
        }
        
        decodedOutput = encodedInput.removingPercentEncoding ?? "Error: Unable to decode"
    }
    
    private func parseURL() {
        guard !urlInput.isEmpty else {
            parsedComponents = URLComponents()
            queryParameters = []
            return
        }
        
        if let components = URLComponents(string: urlInput) {
            parsedComponents = components
            
            // Parse query parameters
            if let queryItems = components.queryItems {
                queryParameters = queryItems.map { QueryParameter(key: $0.name, value: $0.value ?? "") }
            } else {
                queryParameters = []
            }
        } else {
            parsedComponents = URLComponents()
            queryParameters = []
        }
    }
    
    private func reconstructURL() -> String {
        var components = parsedComponents
        
        // Reconstruct query items if we have parameters
        if !queryParameters.isEmpty {
            components.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        return components.url?.absoluteString ?? "Invalid URL"
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(text, forType: .string)
    }
    
    private func saveState() {
        let defaults = UserDefaults.standard
        defaults.set(textInput, forKey: "URLTools.textInput")
        defaults.set(encodedInput, forKey: "URLTools.encodedInput")
        defaults.set(encodedOutput, forKey: "URLTools.encodedOutput")
        defaults.set(decodedOutput, forKey: "URLTools.decodedOutput")
        defaults.set(urlInput, forKey: "URLTools.urlInput")
        defaults.set(selectedTab.title, forKey: "URLTools.selectedTab")
        defaults.set(useAlphanumericOnly, forKey: "URLTools.useAlphanumericOnly")
    }
    
    private func loadState() {
        let defaults = UserDefaults.standard
        textInput = defaults.string(forKey: "URLTools.textInput") ?? ""
        encodedInput = defaults.string(forKey: "URLTools.encodedInput") ?? ""
        encodedOutput = defaults.string(forKey: "URLTools.encodedOutput") ?? ""
        decodedOutput = defaults.string(forKey: "URLTools.decodedOutput") ?? ""
        urlInput = defaults.string(forKey: "URLTools.urlInput") ?? ""
        useAlphanumericOnly = defaults.bool(forKey: "URLTools.useAlphanumericOnly")
        
        if let tabTitle = defaults.string(forKey: "URLTools.selectedTab") {
            selectedTab = URLTab.allCases.first { $0.title == tabTitle } ?? .encoder
        }
        
        // If we have input, trigger processing
        if selectedTab == .encoder && !textInput.isEmpty {
            encodeURL()
        } else if selectedTab == .decoder && !encodedInput.isEmpty {
            decodeURL()
        } else if selectedTab == .parser && !urlInput.isEmpty {
            parseURL()
        }
    }
}

enum URLTab: CaseIterable {
    case encoder, decoder, parser
    
    var title: String {
        switch self {
        case .encoder: return "Encoder"
        case .decoder: return "Decoder"
        case .parser: return "Parser"
        }
    }
}

struct QueryParameter {
    let key: String
    let value: String
}

#Preview {
    URLToolsView()
}
