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
import Foundation
import Combine
import FirebaseAnalytics

struct HTTPRequestView: View {
    let screenName = "HTTP Request"
    @State private var httpMethod: HTTPMethod = .GET
    @State private var urlInput: String = ""
    @State private var headers: [HTTPHeader] = [HTTPHeader()]
    @State private var authType: AuthType = .none
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var bearerToken: String = ""
    @State private var requestBody: String = ""
    @State private var skipTLSVerify: Bool = false
    @State private var timeout: Double = 30.0
    
    @State private var isLoading: Bool = false
    @State private var requestStartTime: Date?
    @State private var responseTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var elapsedTime: TimeInterval = 0
    
    @State private var response: HTTPResponseData?
    @State private var responseViewMode: ResponseViewMode = .preview
    @State private var selectedRequestTab: RequestTab = .headers
    @State private var selectedResponseTab: ResponseTab = .body
    @State private var isStreaming: Bool = false
    @State private var streamingContent: String = ""
    
    @State private var urlSession: URLSession?
    @State private var currentTask: URLSessionDataTask?
    @State private var requestHistory: [HTTPRequestHistoryItem] = []
    @State private var showHistory: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(screenName)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Request URL and Controls
            HStack(spacing: 10) {
                Picker("", selection: $httpMethod) {
                    ForEach(HTTPMethod.allCases, id: \.self) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal, 0)
                .frame(width: 100)
                
                TextField("Enter URL", text: $urlInput)
                    .textFieldStyle(.roundedBorder)
                
                Button(action: {
                    if isLoading {
                        cancelRequest()
                    } else {
                        sendRequest()
                    }
                }) {
                    HStack {
                        if isLoading {
                            Text("Cancel")
                        } else {
                            Image(systemName: "paperplane.fill")
                            Text("Send")
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(isLoading ? .red : .blue)
                .disabled(urlInput.isEmpty)
                
                Button(action: {
                    showHistory.toggle()
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .buttonStyle(.bordered)
                .disabled(requestHistory.isEmpty)
                .help("Request History")
            }
            
            
            HStack(alignment: .top, spacing: 20) {
                // Request Configuration
                VStack(alignment: .leading, spacing: 15) {

                    HStack {
                        Text("Request")
                        .font(.headline)

                        Spacer()

                        Toggle("Skip TLS Verify", isOn: $skipTLSVerify)

                        HStack {
                            Text("Timeout")
                            TextField("30", value: $timeout, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 50)
                            Text("s")
                        }
                    }
                    .font(.caption)
                    
                    Picker("", selection: $selectedRequestTab) {
                        ForEach(RequestTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // Content based on selected tab
                    Group {
                        switch selectedRequestTab {
                        case .headers:
                            headersView
                        case .auth:
                            authView
                        case .body:
                            bodyView
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                // Response Display or History
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text(showHistory ? "Request History" : "Response")
                            .font(.headline)
                        
                        if showHistory {
                            Spacer()
                            Button("Clear History") {
                                requestHistory.removeAll()
                            }
                            .buttonStyle(.bordered)
                            .disabled(requestHistory.isEmpty)
                        } else if let response = response {
                            Spacer()
                            Text("Status: \(response.statusCode)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(statusColor(response.statusCode))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                            
                            Text("Time: \(String(format: "%.0f", responseTime * 1000))ms")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if showHistory {
                        // History content
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(requestHistory) { item in
                                    historyItemView(item: item)
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppConstants.controlBackground)
                        .cornerRadius(10)
                    } else {
                        // Response content
                        ZStack {
                            VStack(spacing: 15) {
                                if response != nil || isStreaming {
                                    Picker("", selection: $selectedResponseTab) {
                                        ForEach(ResponseTab.allCases, id: \.self) { tab in
                                            Text(tab.rawValue).tag(tab)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }
                                
                                if let response = response {
                                    responseView(response)
                                } else if isStreaming {
                                    streamingResponseView
                                } else {
                                    Text("Response will appear here")
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                        .background(AppConstants.controlBackground)
                                        .cornerRadius(10)
                                }
                            }
                            .opacity(isLoading ? 0.3 : 1.0)
                            .disabled(isLoading)
                            
                            if isLoading {
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                    Text("Elapsed: \(String(format: "%.1f", elapsedTime))s")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(AppConstants.controlBackground.opacity(0.8))
                                .cornerRadius(10)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .onAppear {
            setupURLSession()
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
    private var headersView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Headers")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Button("Add Header") {
                    headers.append(HTTPHeader())
                }
                .buttonStyle(.bordered)
            }
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(headers.indices, id: \.self) { index in
                        HStack {
                            TextField("Header", text: $headers[index].key)
                                .textFieldStyle(.roundedBorder)
                            
                            Text(":")
                                .foregroundColor(.secondary)
                            
                            TextField("Value", text: $headers[index].value)
                                .textFieldStyle(.roundedBorder)
                            
                            Button(action: {
                                headers.remove(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            // Common Headers
            VStack(alignment: .leading, spacing: 4) {
                Text("Common Headers:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    Button("Content-Type: application/json") {
                        addOrUpdateHeader("Content-Type", "application/json")
                    }
                    Button("Accept: application/json") {
                        addOrUpdateHeader("Accept", "application/json")
                    }
                    Button("User-Agent") {
                        addOrUpdateHeader("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36")
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var authView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Picker("Authentication", selection: $authType) {
                ForEach(AuthType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .pickerStyle(.segmented)
            
            switch authType {
            case .none:
                Text("No authentication required")
                    .foregroundColor(.secondary)
                    .italic()
                
            case .basic:
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        TextField("Username", text: $username)
                            .textFieldStyle(.roundedBorder)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("Use Sample") {
                            username = "root@example.com"
                            password = "Complexpass#123"
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
            case .bearer:
                VStack(alignment: .leading, spacing: 10) {
                    Text("Bearer Token:")
                        .font(.caption)
                    TextField("Enter bearer token", text: $bearerToken)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var bodyView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Request Body")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                
                Button("Clear") {
                    requestBody = ""
                }
                .buttonStyle(.bordered)
            }
            
            ZStack(alignment: .topLeading) {
                CodeEditor.httpBody(text: $requestBody)
                    .frame(maxHeight: .infinity)
                
                if requestBody.isEmpty {
                    Text("Enter request body (JSON, XML, form data, etc.)")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
            }
            
            // Sample Bodies
            VStack(alignment: .leading, spacing: 4) {
                Text("Sample Bodies:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    Button("JSON") {
                        requestBody = """
                        {
                            "key": "value",
                            "number": 123,
                            "boolean": true
                        }
                        """
                    }
                    Button("Form Data") {
                        requestBody = "key1=value1&key2=value2"
                    }
                    Button("XML") {
                        requestBody = """
                        <?xml version="1.0" encoding="UTF-8"?>
                        <root>
                            <item>value</item>
                        </root>
                        """
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func responseView(_ response: HTTPResponseData) -> some View {
        // Content based on selected tab
        Group {
            switch selectedResponseTab {
            case .body:
                // Response Body
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Picker("View Mode", selection: $responseViewMode) {
                            ForEach(ResponseViewMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Spacer()
                        
                        Button("Copy Response") {
                            copyToClipboard(response.body)
                        }
                        .buttonStyle(.bordered)
                        
                        if response.isDownloadable {
                            Button("Save to File") {
                                saveResponseToFile(response)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    Group {
                        if responseViewMode == .raw {
                            // Raw mode - show original response as plain text
                            ScrollView {
                                Text(response.body)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(5)
                            }
                            .background(AppConstants.controlBackground)
                            .cornerRadius(8)
                            .frame(maxHeight: .infinity)
                        } else {
                            // Preview mode - use CodeEditor with proper formatting
                            if response.contentType.contains("application/json") {
                                CodeEditor.json(text: .constant(formatResponseBody(response)))
                                    .frame(maxHeight: .infinity)
                            } else {
                                ScrollView {
                                    Text(formatResponseBody(response))
                                        .font(.system(.body, design: .monospaced))
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(5)
                                }
                                .background(AppConstants.controlBackground)
                                .cornerRadius(8)
                                .frame(maxHeight: .infinity)
                            }
                        }
                    }
                }
                
            case .headers:
                // Response Headers
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Response Headers")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Button("Copy Headers") {
                            let headersText = response.headers.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
                            copyToClipboard(headersText)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(response.headers.indices, id: \.self) { index in
                                HStack {
                                    Text("\(response.headers[index].key):")
                                        .fontWeight(.medium)
                                        .frame(maxWidth: 150, alignment: .leading)
                                    
                                    Text(response.headers[index].value)
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .font(.system(.caption, design: .monospaced))
                                .padding(.vertical, 2)
                            }
                        }
                        .padding()
                    }
                    .background(AppConstants.controlBackground)
                    .cornerRadius(8)
                    .frame(maxHeight: .infinity)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var streamingResponseView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Streaming Response (SSE)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("Copy Stream") {
                    copyToClipboard(streamingContent)
                }
                .buttonStyle(.bordered)
            }
            
            // Use CodeEditor for better formatting, especially for JSON streams
            CodeEditor.plain(text: .constant(streamingContent))
                .frame(minHeight: 200)
        }
    }
    
    private func setupURLSession() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout * 2
        
        urlSession = URLSession(configuration: configuration)
    }
    
    private func sendRequest() {
        guard !urlInput.isEmpty,
              let url = URL(string: urlInput) else {
            return
        }
        
        // Switch back to response view if history is showing
        if showHistory {
            showHistory = false
        }
        
        isLoading = true
        requestStartTime = Date()
        elapsedTime = 0
        response = nil
        isStreaming = false
        streamingContent = ""
        
        // Start timer
        startTimer()
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        request.timeoutInterval = timeout
        
        // Add headers
        for header in headers {
            if !header.key.isEmpty && !header.value.isEmpty {
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        
        // Add authentication
        switch authType {
        case .none:
            break
        case .basic:
            if !username.isEmpty {
                let credentials = "\(username):\(password)"
                if let credentialsData = credentials.data(using: .utf8) {
                    let base64Credentials = credentialsData.base64EncodedString()
                    request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
                }
            }
        case .bearer:
            if !bearerToken.isEmpty {
                request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
            }
        }
        
        // Add body for applicable methods
        if httpMethod.hasBody && !requestBody.isEmpty {
            request.httpBody = requestBody.data(using: .utf8)
        }
        
        // Configure SSL verification
        if skipTLSVerify {
            let config = URLSessionConfiguration.default
            urlSession = URLSession(configuration: config, delegate: TLSBypassDelegate(), delegateQueue: nil)
        } else {
            setupURLSession()
        }
        
        // Save to history before sending
        saveToHistory()
        
        // Send request
        currentTask = urlSession?.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.handleResponse(data: data, response: response, error: error)
            }
        }
        
        currentTask?.resume()
    }
    
    private func cancelRequest() {
        currentTask?.cancel()
        stopTimer()
        isLoading = false
        isStreaming = false
    }
    
    private func handleResponse(data: Data?, response: URLResponse?, error: Error?) {
        stopTimer()
        isLoading = false
        
        if let error = error {
            self.response = HTTPResponseData(
                statusCode: 0,
                headers: [],
                body: "Error: \(error.localizedDescription)",
                contentType: "text/plain",
                data: nil
            )
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            self.response = HTTPResponseData(
                statusCode: 0,
                headers: [],
                body: "Invalid response",
                contentType: "text/plain",
                data: nil
            )
            return
        }
        
        responseTime = Date().timeIntervalSince(requestStartTime ?? Date())
        
        let headers = httpResponse.allHeaderFields.compactMap { key, value in
            HTTPHeader(key: String(describing: key), value: String(describing: value))
        }
        
        let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "text/plain"
        
        let bodyString: String
        if let data = data {
            if contentType.hasPrefix("application/json") {
                bodyString = formatJSON(data) ?? String(data: data, encoding: .utf8) ?? "Binary data"
            } else if contentType.hasPrefix("text/") || contentType.contains("xml") {
                bodyString = String(data: data, encoding: .utf8) ?? "Binary data"
            } else if contentType.contains("text/event-stream") {
                // Handle SSE streaming
                bodyString = String(data: data, encoding: .utf8) ?? "Binary data"
            } else {
                bodyString = "Binary data (\(data.count) bytes)"
            }
        } else {
            bodyString = "No response body"
        }
        
        self.response = HTTPResponseData(
            statusCode: httpResponse.statusCode,
            headers: headers,
            body: bodyString,
            contentType: contentType,
            data: data
        )
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let startTime = requestStartTime {
                elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func statusColor(_ statusCode: Int) -> Color {
        switch statusCode {
        case 200..<300:
            return .green
        case 300..<400:
            return .orange
        case 400..<500:
            return .red
        case 500..<600:
            return .red
        default:
            return .gray
        }
    }
    
    private func formatResponseBody(_ response: HTTPResponseData) -> String {
        // Preview mode - format based on content type
        if response.contentType.contains("application/json") {
            // Ensure JSON is properly formatted for CodeEditor
            if let data = response.data {
                return formatJSON(data) ?? response.body
            }
            return response.body
        }
        
        return response.body
    }
    
    private func formatJSON(_ data: Data) -> String? {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
            return String(data: prettyData, encoding: .utf8)
        } catch {
            return nil
        }
    }
    
    private func addOrUpdateHeader(_ key: String, _ value: String) {
        if let index = headers.firstIndex(where: { $0.key == key }) {
            headers[index].value = value
        } else {
            headers.append(HTTPHeader(key: key, value: value))
        }
    }
    
    private func saveResponseToFile(_ response: HTTPResponseData) {
        guard let data = response.data else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.data]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "response_data"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try data.write(to: url)
            } catch {
                print("Failed to save file: \(error)")
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    
    @ViewBuilder
    private func historyItemView(item: HTTPRequestHistoryItem) -> some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.method.rawValue)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(methodColor(item.method))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    
                    Text(item.url)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    Text(item.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if !item.headers.isEmpty {
                    Text("\(item.headers.count) headers")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if !item.body.isEmpty {
                    Text("Body: \(item.body.prefix(50))\(item.body.count > 50 ? "..." : "")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Button(action: {
                replayRequest(item)
                showHistory = false
            }) {
                Image(systemName: "paperplane.fill")
            }
            .buttonStyle(.bordered)
            .help("Replay Request")
        }
        .padding(4)
        .background(AppConstants.controlBackground)
        .cornerRadius(6)
        .onTapGesture {
            replayRequest(item)
            showHistory = false
        }
    }
    
    private func methodColor(_ method: HTTPMethod) -> Color {
        switch method {
        case .GET: return .blue
        case .POST: return .green
        case .PUT: return .orange
        case .DELETE: return .red
        case .PATCH: return .purple
        case .HEAD: return .gray
        case .OPTIONS: return .brown
        }
    }
    
    private func saveToHistory() {
        let historyItem = HTTPRequestHistoryItem(
            id: UUID(),
            method: httpMethod,
            url: urlInput,
            headers: headers.filter { !$0.key.isEmpty && !$0.value.isEmpty },
            authType: authType,
            username: username,
            password: password,
            bearerToken: bearerToken,
            body: requestBody,
            skipTLSVerify: skipTLSVerify,
            timeout: timeout,
            timestamp: Date()
        )
        
        // Remove duplicate URLs
        requestHistory.removeAll { $0.method == httpMethod && $0.url == urlInput }
        
        // Add to beginning and limit to 20 items
        requestHistory.insert(historyItem, at: 0)
        if requestHistory.count > 20 {
            requestHistory.removeLast()
        }
    }
    
    private func replayRequest(_ item: HTTPRequestHistoryItem) {
        httpMethod = item.method
        urlInput = item.url
        headers = item.headers.isEmpty ? [HTTPHeader()] : item.headers
        authType = item.authType
        username = item.username
        password = item.password
        bearerToken = item.bearerToken
        requestBody = item.body
        skipTLSVerify = item.skipTLSVerify
        timeout = item.timeout
    }
    
    private func saveState() {
        let defaults = UserDefaults.standard
        
        // Save current request state
        defaults.set(httpMethod.rawValue, forKey: "HTTPRequest.method")
        defaults.set(urlInput, forKey: "HTTPRequest.url")
        defaults.set(authType == .basic ? "basic" : (authType == .bearer ? "bearer" : "none"), forKey: "HTTPRequest.authType")
        defaults.set(username, forKey: "HTTPRequest.username")
        defaults.set(password, forKey: "HTTPRequest.password")
        defaults.set(bearerToken, forKey: "HTTPRequest.bearerToken")
        defaults.set(requestBody, forKey: "HTTPRequest.body")
        defaults.set(skipTLSVerify, forKey: "HTTPRequest.skipTLS")
        defaults.set(timeout, forKey: "HTTPRequest.timeout")
        
        // Save headers
        let headersData = headers.compactMap { header in
            if !header.key.isEmpty || !header.value.isEmpty {
                return ["key": header.key, "value": header.value]
            }
            return nil
        }
        defaults.set(headersData, forKey: "HTTPRequest.headers")
        
        // Save history
        let historyData = requestHistory.map { item in
            [
                "id": item.id.uuidString,
                "method": item.method.rawValue,
                "url": item.url,
                "authType": item.authType == .basic ? "basic" : (item.authType == .bearer ? "bearer" : "none"),
                "username": item.username,
                "password": item.password,
                "bearerToken": item.bearerToken,
                "body": item.body,
                "skipTLSVerify": item.skipTLSVerify,
                "timeout": item.timeout,
                "timestamp": item.timestamp.timeIntervalSince1970,
                "headers": item.headers.map { ["key": $0.key, "value": $0.value] }
            ] as [String: Any]
        }
        defaults.set(historyData, forKey: "HTTPRequest.history")
    }
    
    private func loadState() {
        let defaults = UserDefaults.standard
        
        // Load current request state
        if let methodString = defaults.string(forKey: "HTTPRequest.method"),
           let method = HTTPMethod(rawValue: methodString) {
            httpMethod = method
        }
        
        urlInput = defaults.string(forKey: "HTTPRequest.url") ?? ""
        
        let authTypeString = defaults.string(forKey: "HTTPRequest.authType") ?? "none"
        authType = authTypeString == "basic" ? .basic : (authTypeString == "bearer" ? .bearer : .none)
        
        username = defaults.string(forKey: "HTTPRequest.username") ?? ""
        password = defaults.string(forKey: "HTTPRequest.password") ?? ""
        bearerToken = defaults.string(forKey: "HTTPRequest.bearerToken") ?? ""
        requestBody = defaults.string(forKey: "HTTPRequest.body") ?? ""
        skipTLSVerify = defaults.bool(forKey: "HTTPRequest.skipTLS")
        timeout = defaults.double(forKey: "HTTPRequest.timeout")
        if timeout == 0 { timeout = 30.0 }
        
        // Load headers
        if let headersData = defaults.array(forKey: "HTTPRequest.headers") as? [[String: String]] {
            headers = headersData.map { HTTPHeader(key: $0["key"] ?? "", value: $0["value"] ?? "") }
            if headers.isEmpty {
                headers = [HTTPHeader()]
            }
        }
        
        // Load history
        if let historyData = defaults.array(forKey: "HTTPRequest.history") as? [[String: Any]] {
            requestHistory = historyData.compactMap { dict in
                guard let idString = dict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let methodString = dict["method"] as? String,
                      let method = HTTPMethod(rawValue: methodString),
                      let url = dict["url"] as? String,
                      let authTypeString = dict["authType"] as? String,
                      let username = dict["username"] as? String,
                      let password = dict["password"] as? String,
                      let bearerToken = dict["bearerToken"] as? String,
                      let body = dict["body"] as? String,
                      let skipTLSVerify = dict["skipTLSVerify"] as? Bool,
                      let timeout = dict["timeout"] as? Double,
                      let timestamp = dict["timestamp"] as? TimeInterval,
                      let headersData = dict["headers"] as? [[String: String]] else {
                    return nil
                }
                
                let authType: AuthType = authTypeString == "basic" ? .basic : (authTypeString == "bearer" ? .bearer : .none)
                let headers = headersData.map { HTTPHeader(key: $0["key"] ?? "", value: $0["value"] ?? "") }
                
                return HTTPRequestHistoryItem(
                    id: id,
                    method: method,
                    url: url,
                    headers: headers,
                    authType: authType,
                    username: username,
                    password: password,
                    bearerToken: bearerToken,
                    body: body,
                    skipTLSVerify: skipTLSVerify,
                    timeout: timeout,
                    timestamp: Date(timeIntervalSince1970: timestamp)
                )
            }
        }
    }
}

// MARK: - Data Models

enum HTTPMethod: String, CaseIterable {
    case GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS
    
    var hasBody: Bool {
        switch self {
        case .POST, .PUT, .PATCH:
            return true
        case .GET, .DELETE, .HEAD, .OPTIONS:
            return false
        }
    }
}

enum AuthType: CaseIterable {
    case none, basic, bearer
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .basic: return "Basic Auth"
        case .bearer: return "Bearer Token"
        }
    }
}

enum RequestTab: String, CaseIterable {
    case headers = "Headers"
    case auth = "Auth"
    case body = "Body"
}

enum ResponseTab: String, CaseIterable {
    case body = "Body"
    case headers = "Headers"
}

enum ResponseViewMode: String, CaseIterable {
    case preview = "preview"
    case raw = "raw"
    
    var displayName: String {
        switch self {
        case .preview: return "Preview"
        case .raw: return "Raw"
        }
    }
}

struct HTTPHeader {
    var key: String = ""
    var value: String = ""
}

struct HTTPResponseData {
    let statusCode: Int
    let headers: [HTTPHeader]
    let body: String
    let contentType: String
    let data: Data?
    
    var isDownloadable: Bool {
        return data != nil && !contentType.hasPrefix("text/") && !contentType.contains("json")
    }
}

struct HTTPRequestHistoryItem: Identifiable {
    let id: UUID
    let method: HTTPMethod
    let url: String
    let headers: [HTTPHeader]
    let authType: AuthType
    let username: String
    let password: String
    let bearerToken: String
    let body: String
    let skipTLSVerify: Bool
    let timeout: Double
    let timestamp: Date
}

// MARK: - TLS Bypass Delegate

class TLSBypassDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}

#Preview {
    HTTPRequestView()
}
