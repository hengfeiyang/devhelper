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
import CryptoKit
import Foundation

enum JWTTab: String, CaseIterable {
    case encode = "encode"
    case decode = "decode"
    
    var title: String {
        switch self {
        case .encode:
            return "Encode"
        case .decode:
            return "Decode"
        }
    }
}

enum JWTAlgorithm: String, CaseIterable {
    case hs256 = "HS256"
    case hs384 = "HS384"
    case hs512 = "HS512"
    case none = "none"
    
    var title: String {
        return self.rawValue
    }
}

struct JWTView: View {
    @State private var selectedTab: JWTTab = .decode
    @State private var jwtToken: String = ""
    @State private var headerText: String = ""
    @State private var payloadText: String = ""
    @State private var signatureText: String = ""
    @State private var secretKey: String = "your-256-bit-secret"
    @State private var isValidSignature: Bool = false
    @State private var selectedAlgorithm: JWTAlgorithm = .hs256
    @State private var errorMessage: String = ""
    @State private var encodedJWT: String = ""
    
    // Sample JWT with known secret key
    private let sampleJWT = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
    private let sampleSecretKey = "your-256-bit-secret"
    
    private let defaultHeader = """
    {
      "alg": "HS256",
      "typ": "JWT"
    }
    """
    
    private let defaultPayload = """
    {
      "sub": "1234567890",
      "name": "John Doe",
      "iat": 1516239022
    }
    """
    
    var body: some View {
        VStack(spacing: 20) {
            Text("JWT Encoder/Decoder")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Picker("Mode", selection: $selectedTab) {
                ForEach(JWTTab.allCases, id: \.self) { tab in
                    Text(tab.title)
                        .tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            if selectedTab == .decode {
                decodeView
            } else {
                encodeView
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var encodeView: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Algorithm")
                                .font(.headline)
                            Spacer()
                            Picker("", selection: $selectedAlgorithm) {
                                ForEach(JWTAlgorithm.allCases, id: \.self) { alg in
                                    Text(alg.title).tag(alg)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 100)
                            .onChange(of: selectedAlgorithm) { _, _ in
                                updateHeaderAlgorithm()
                                encodeJWT()
                            }
                        }
                        
                        HStack {
                            Text("Header")
                                .font(.headline)
                            Spacer()
                            Button("Default") {
                                headerText = defaultHeader
                                encodeJWT()
                            }
                            .buttonStyle(.borderless)
                        }
                        
                        TextEditor(text: $headerText)
                            .font(.system(.body, design: .monospaced))
                            .padding(5)
                            .frame(maxHeight: .infinity)
                            .onChange(of: headerText) { _, _ in
                                encodeJWT()
                            }
                    }
                    .frame(maxHeight: .infinity)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Payload")
                                .font(.headline)
                            Spacer()
                            Button("Default") {
                                payloadText = defaultPayload
                                encodeJWT()
                            }
                            .buttonStyle(.borderless)
                        }
                        
                        TextEditor(text: $payloadText)
                            .font(.system(.body, design: .monospaced))
                            .padding(5)
                            .frame(maxHeight: .infinity)
                            .onChange(of: payloadText) { _, _ in
                                encodeJWT()
                            }
                    }
                    .frame(maxHeight: .infinity)
                    
                    if selectedAlgorithm != .none {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Secret Key")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("Secret key", text: $secretKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: secretKey) { _, _ in
                                    encodeJWT()
                                }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                Image(systemName: "arrow.right")
                    .font(.title)
                    .foregroundColor(.blue)
                    .frame(maxHeight: .infinity, alignment: .center)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Encoded JWT")
                            .font(.headline)
                        Spacer()
                        Button("Copy") {
                            copyToClipboard(encodedJWT)
                        }
                        .buttonStyle(.borderless)
                        .disabled(encodedJWT.isEmpty)
                    }
                    
                    ScrollView {
                        Text(encodedJWT.isEmpty ? "Encoded JWT will appear here" : encodedJWT)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .padding(5)
                    .frame(maxHeight: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    if !encodedJWT.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Token Structure:")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            let parts = encodedJWT.split(separator: ".")
                            if parts.count >= 1 {
                                HStack(spacing: 5) {
                                    Circle().fill(Color.red.opacity(0.5)).frame(width: 8, height: 8)
                                    Text("Header: \(parts[0].prefix(40))...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            if parts.count >= 2 {
                                HStack(spacing: 5) {
                                    Circle().fill(Color.purple.opacity(0.5)).frame(width: 8, height: 8)
                                    Text("Payload: \(parts[1].prefix(40))...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            if parts.count >= 3 && selectedAlgorithm != .none {
                                HStack(spacing: 5) {
                                    Circle().fill(Color.blue.opacity(0.5)).frame(width: 8, height: 8)
                                    Text("Signature: \(parts[2].prefix(40))...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onAppear {
            if headerText.isEmpty {
                headerText = defaultHeader
            }
            if payloadText.isEmpty {
                payloadText = defaultPayload
            }
            encodeJWT()
        }
    }
    

    private var decodeView: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("JWT Token")
                            .font(.headline)
                        Spacer()
                        Button("Sample") {
                            jwtToken = sampleJWT
                            secretKey = sampleSecretKey
                            decodeJWT()
                        }
                        .buttonStyle(.borderless)
                        Button("Paste") {
                            if let clipboardContent = NSPasteboard.general.string(forType: .string) {
                                jwtToken = clipboardContent
                                decodeJWT()
                            }
                        }
                        .buttonStyle(.borderless)
                        Button("Clear") {
                            clearDecode()
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    TextEditor(text: $jwtToken)
                        .font(.system(.body, design: .monospaced))
                        .padding(5)
                        .frame(maxHeight: .infinity)
                        .onChange(of: jwtToken) { _, _ in
                            decodeJWT()
                        }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Secret Key (for signature verification)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("Secret key", text: $secretKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: secretKey) { _, _ in
                                    if !jwtToken.isEmpty {
                                        verifySignature()
                                    }
                                }
                            
                            if !jwtToken.isEmpty {
                                Image(systemName: isValidSignature ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(isValidSignature ? .green : .red)
                                    .help(isValidSignature ? "Signature Valid" : "Signature Invalid")
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                Image(systemName: "arrow.right")
                    .font(.title)
                    .foregroundColor(.blue)
                    .frame(maxHeight: .infinity, alignment: .center)
                
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Header")
                                .font(.headline)
                            Spacer()
                            Button("Copy") {
                                copyToClipboard(headerText)
                            }
                            .buttonStyle(.borderless)
                            .disabled(headerText.isEmpty)
                        }
                        
                        ScrollView {
                            Text(headerText.isEmpty ? "Header will appear here" : headerText)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        .padding(5)
                        .frame(maxHeight: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .frame(maxHeight: .infinity)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("Payload")
                                .font(.headline)
                            Spacer()
                            Button("Copy") {
                                copyToClipboard(payloadText)
                            }
                            .buttonStyle(.borderless)
                            .disabled(payloadText.isEmpty)
                        }
                        
                        ScrollView {
                            Text(payloadText.isEmpty ? "Payload will appear here" : payloadText)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        .padding(5)
                        .frame(maxHeight: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .frame(maxHeight: .infinity)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("Signature")
                                .font(.headline)
                            Spacer()
                            Button("Copy") {
                                copyToClipboard(signatureText)
                            }
                            .buttonStyle(.borderless)
                            .disabled(signatureText.isEmpty)
                        }
                        
                        ScrollView {
                            Text(signatureText.isEmpty ? "Signature will appear here" : signatureText)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        .padding(5)
                        .frame(height: 60)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private func decodeJWT() {
        errorMessage = ""
        guard !jwtToken.isEmpty else {
            clearDecodeResults()
            return
        }
        
        let parts = jwtToken.split(separator: ".")
        guard parts.count >= 2 else {
            errorMessage = "Invalid JWT format. Expected header.payload.signature"
            clearDecodeResults()
            return
        }
        
        // Decode header
        if let headerData = base64URLDecode(String(parts[0])),
           let headerJSON = try? JSONSerialization.jsonObject(with: headerData, options: []) as? [String: Any],
           let headerFormatted = try? JSONSerialization.data(withJSONObject: headerJSON, options: [.prettyPrinted, .sortedKeys]),
           let headerString = String(data: headerFormatted, encoding: .utf8) {
            headerText = headerString
        } else {
            headerText = "Error decoding header"
        }
        
        // Decode payload
        if let payloadData = base64URLDecode(String(parts[1])),
           let payloadJSON = try? JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any],
           let payloadFormatted = try? JSONSerialization.data(withJSONObject: payloadJSON, options: [.prettyPrinted, .sortedKeys]),
           let payloadString = String(data: payloadFormatted, encoding: .utf8) {
            payloadText = payloadString
        } else {
            payloadText = "Error decoding payload"
        }
        
        // Display signature
        if parts.count >= 3 {
            signatureText = String(parts[2])
            verifySignature()
        } else {
            signatureText = "No signature (unsigned token)"
            isValidSignature = false
        }
    }
    
    private func encodeJWT() {
        errorMessage = ""
        encodedJWT = ""
        
        // Validate and encode header
        guard let headerData = headerText.data(using: .utf8),
              let _ = try? JSONSerialization.jsonObject(with: headerData, options: []) else {
            errorMessage = "Invalid JSON in header"
            return
        }
        
        // Validate and encode payload
        guard let payloadData = payloadText.data(using: .utf8),
              let _ = try? JSONSerialization.jsonObject(with: payloadData, options: []) else {
            errorMessage = "Invalid JSON in payload"
            return
        }
        
        let encodedHeader = base64URLEncode(headerData)
        let encodedPayload = base64URLEncode(payloadData)
        
        if selectedAlgorithm == .none {
            encodedJWT = "\(encodedHeader).\(encodedPayload)"
        } else {
            let signingInput = "\(encodedHeader).\(encodedPayload)"
            
            guard let signature = createSignature(signingInput: signingInput, secret: secretKey, algorithm: selectedAlgorithm) else {
                errorMessage = "Failed to create signature"
                return
            }
            
            encodedJWT = "\(signingInput).\(signature)"
        }
    }
    
    private func verifySignature() {
        let parts = jwtToken.split(separator: ".")
        guard parts.count >= 3 else {
            isValidSignature = false
            return
        }
        
        // Get algorithm from header
        guard let headerData = base64URLDecode(String(parts[0])),
              let headerJSON = try? JSONSerialization.jsonObject(with: headerData, options: []) as? [String: Any],
              let algString = headerJSON["alg"] as? String else {
            isValidSignature = false
            return
        }
        
        guard let algorithm = JWTAlgorithm(rawValue: algString) else {
            isValidSignature = false
            return
        }
        
        if algorithm == .none {
            isValidSignature = parts.count == 2 || (parts.count == 3 && parts[2].isEmpty)
            return
        }
        
        let signingInput = "\(parts[0]).\(parts[1])"
        let providedSignature = String(parts[2])
        
        if let expectedSignature = createSignature(signingInput: signingInput, secret: secretKey, algorithm: algorithm) {
            isValidSignature = expectedSignature == providedSignature
        } else {
            isValidSignature = false
        }
    }
    
    private func createSignature(signingInput: String, secret: String, algorithm: JWTAlgorithm) -> String? {
        guard let signingData = signingInput.data(using: .utf8),
              let keyData = secret.data(using: .utf8) else {
            return nil
        }
        
        let signature: Data
        
        switch algorithm {
        case .hs256:
            let key = SymmetricKey(data: keyData)
            signature = Data(HMAC<SHA256>.authenticationCode(for: signingData, using: key))
        case .hs384:
            let key = SymmetricKey(data: keyData)
            signature = Data(HMAC<SHA384>.authenticationCode(for: signingData, using: key))
        case .hs512:
            let key = SymmetricKey(data: keyData)
            signature = Data(HMAC<SHA512>.authenticationCode(for: signingData, using: key))
        case .none:
            return ""
        }
        
        return base64URLEncode(signature)
    }
    
    private func updateHeaderAlgorithm() {
        guard let headerData = headerText.data(using: .utf8),
              var headerJSON = try? JSONSerialization.jsonObject(with: headerData, options: []) as? [String: Any] else {
            return
        }
        
        headerJSON["alg"] = selectedAlgorithm.rawValue
        
        if let updatedData = try? JSONSerialization.data(withJSONObject: headerJSON, options: [.prettyPrinted, .sortedKeys]),
           let updatedString = String(data: updatedData, encoding: .utf8) {
            headerText = updatedString
        }
    }
    
    private func base64URLEncode(_ data: Data) -> String {
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    private func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if needed
        let remainder = base64.count % 4
        if remainder > 0 {
            base64.append(String(repeating: "=", count: 4 - remainder))
        }
        
        return Data(base64Encoded: base64)
    }
    
    private func clearDecode() {
        jwtToken = ""
        headerText = ""
        payloadText = ""
        signatureText = ""
        isValidSignature = false
        errorMessage = ""
    }
    
    private func clearDecodeResults() {
        headerText = ""
        payloadText = ""
        signatureText = ""
        isValidSignature = false
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

#Preview {
    JWTView()
}