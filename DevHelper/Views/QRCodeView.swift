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
import CoreImage
import CoreImage.CIFilterBuiltins
import AVFoundation
import Vision
import UniformTypeIdentifiers
import FirebaseAnalytics

enum QRCodeTab: String, CaseIterable {
    case generate = "generate"
    case scan = "scan"
    
    var title: String {
        switch self {
        case .generate:
            return "Generate"
        case .scan:
            return "Scan"
        }
    }
}

enum QRCodeSize: String, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extraLarge"
    case custom = "custom"
    
    var title: String {
        switch self {
        case .small:
            return "Small (128x128)"
        case .medium:
            return "Medium (256x256)"
        case .large:
            return "Large (512x512)"
        case .extraLarge:
            return "Extra Large (1024x1024)"
        case .custom:
            return "Custom Size"
        }
    }
    
    var pixelSize: CGFloat {
        switch self {
        case .small:
            return 128
        case .medium:
            return 256
        case .large:
            return 512
        case .extraLarge:
            return 1024
        case .custom:
            return 256 // Default, will be overridden
        }
    }
    
    var displaySize: CGFloat {
        switch self {
        case .small:
            return 150
        case .medium:
            return 200
        case .large:
            return 250
        case .extraLarge:
            return 300
        case .custom:
            return 200 // Default display size
        }
    }
}

struct QRCodeView: View {
    let screenName = "QR Code"
    @State private var inputText: String = ""
    @State private var qrCodeImage: NSImage?
    @State private var scanResult: String = ""
    @State private var selectedTab: QRCodeTab = .generate
    @State private var errorMessage: String = ""
    @State private var isScanning: Bool = false
    @State private var correctionLevel: String = "M"
    @State private var qrCodeSize: QRCodeSize = .medium
    @State private var customSize: String = "512"
    @State private var previewImage: NSImage?
    
    private let correctionLevels = ["L", "M", "Q", "H"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text(screenName)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Picker("Mode", selection: $selectedTab) {
                ForEach(QRCodeTab.allCases, id: \.self) { tab in
                    Text(tab.title)
                        .tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            if selectedTab == .generate {
                generateView
            } else {
                scanView
            }

            Spacer()
        }
        .padding()
        .onChange(of: inputText) { _, _ in
            generateQRCode()
        }
        .onChange(of: correctionLevel) { _, _ in
            generateQRCode()
        }
        .onChange(of: qrCodeSize) { _, _ in
            generateQRCode()
        }
        .onChange(of: customSize) { _, _ in
            if qrCodeSize == .custom {
                generateQRCode()
            }
        }
        .onAppear {
            Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                AnalyticsParameterScreenName: screenName
            ])
        }
    }
    
    private var generateView: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Text Input")
                        .font(.headline)
                    Spacer()
                    Button("Clear") {
                        inputText = ""
                        qrCodeImage = nil
                        errorMessage = ""
                    }
                    .buttonStyle(.borderless)
                }
                
                TextEditor(text: $inputText)
                    .padding(5)
                    .frame(height: 250)   
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Error Correction Level:")
                            .font(.caption)
                        
                        Picker("Correction Level", selection: $correctionLevel) {
                            ForEach(correctionLevels, id: \.self) { level in
                                Text("\(level) - \(correctionLevelDescription(level))")
                                    .tag(level)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: 200)
                    }
                    
                    HStack {
                        Text("QR Code Size:")
                            .font(.caption)
                        
                        Picker("QR Code Size", selection: $qrCodeSize) {
                            ForEach(QRCodeSize.allCases, id: \.self) { size in
                                Text(size.title)
                                    .tag(size)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: 240)
                    }
                    
                    if qrCodeSize == .custom {
                        HStack {
                            Text("Custom Size (px):")
                                .font(.caption)
                            
                            TextField("512", text: $customSize)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                            
                            Text("px")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                HStack {
                    Button("Sample URL") {
                        inputText = "https://github.com/hengfeiyang/devhelper"
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Sample Text") {
                        inputText = "Hello, DevHelper QR Code!"
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Sample WiFi") {
                        inputText = "WIFI:T:WPA;S:MyNetwork;P:mypassword;;"
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Image(systemName: "arrow.right")
                .font(.title)
                .foregroundColor(.blue)
                .frame(height: 250, alignment: .center)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("QR Code")
                        .font(.headline)
                    Spacer()
                }
                
                if let qrImage = qrCodeImage {
                    VStack(spacing: 10) {
                        Image(nsImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: qrCodeSize.displaySize, height: qrCodeSize.displaySize)
                            .background(AppConstants.lightGrayBackground)
                            .cornerRadius(8)
                        
                        Text("\(Int(getCurrentPixelSize()))x\(Int(getCurrentPixelSize())) px")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 10) {
                            Button("Copy Image") {
                                copyImageToClipboard()
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Save Image") {
                                saveImage()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                } else if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .frame(width: qrCodeSize.displaySize, height: qrCodeSize.displaySize)
                        .background(AppConstants.lightGrayBackground)
                            .cornerRadius(8)
                } else {
                    Rectangle()
                        .fill(AppConstants.lightGrayBackground)
                        .frame(width: qrCodeSize.displaySize, height: qrCodeSize.displaySize)
                        .background(AppConstants.lightGrayBackground)
                        .cornerRadius(8)
                        .overlay(
                            Text("Enter text to generate QR code")
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        )
                }
            }
        }
    }
    
    private var scanView: some View {
        VStack(spacing: 20) {
            // Action buttons at the top
            HStack {
                Button("Select Image File") {
                    selectImageFile()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Paste from Clipboard") {
                    pasteImageFromClipboard()
                }
                .buttonStyle(.bordered)
                
                Button("Clear") {
                    scanResult = ""
                    errorMessage = ""
                    previewImage = nil
                }
                .buttonStyle(.borderless)
            }
            
            // Two-column layout: Image preview (left) and Scan result (right)
            HStack(alignment: .top, spacing: 20) {
                // Left column: Image preview
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Image Preview")
                            .font(.headline)
                        Spacer()
                    }
                    
                    if let preview = previewImage {
                        Image(nsImage: preview)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 256, maxHeight: 256)
                            .background(AppConstants.lightGrayBackground)
                            .cornerRadius(8)
                    } else {
                        Rectangle()
                            .fill(AppConstants.lightGrayBackground)
                            .frame(maxWidth: 256, maxHeight: 256)
                            .background(AppConstants.lightGrayBackground)
                            .cornerRadius(8)
                            .overlay(
                                Text("No image selected")
                                    .foregroundColor(.secondary)
                            )
                    }
                }
                
                Image(systemName: "arrow.right")
                    .font(.title)
                    .foregroundColor(.blue)
                    .frame(height: 250, alignment: .center)
                
                // Right column: Scan result
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Scan Result")
                            .font(.headline)
                        Spacer()
                    }
                    
                    if !scanResult.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            ScrollView {
                                Text(scanResult)
                                    .textSelection(.enabled)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(10)
                            }
                            .frame(height: 250)
                            .frame(maxWidth: .infinity)
                            .background(AppConstants.lightGrayBackground)
                            .cornerRadius(8)
                            
                            HStack {
                                Button("Copy") {
                                    copyToClipboard(scanResult)
                                }
                                .buttonStyle(.bordered)
                                
                                if scanResult.hasPrefix("http") {
                                    Button("Open URL") {
                                        if let url = URL(string: scanResult) {
                                            NSWorkspace.shared.open(url)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                }
                                
                                Spacer()
                            }
                        }
                    } else if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .frame(height: 250)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(AppConstants.lightGrayBackground)
                            .cornerRadius(8)
                    } else {
                        Rectangle()
                            .fill(AppConstants.lightGrayBackground)
                            .frame(height: 250)
                            .frame(maxWidth: .infinity)
                            .background(AppConstants.lightGrayBackground)
                            .cornerRadius(8)
                            .overlay(
                                Text("Select an image to scan QR code")
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            )
                    }
                }
            }
        }
    }
    
    private func correctionLevelDescription(_ level: String) -> String {
        switch level {
        case "L": return "Low (~7%)"
        case "M": return "Medium (~15%)"
        case "Q": return "Quartile (~25%)"
        case "H": return "High (~30%)"
        default: return ""
        }
    }
    
    private func getCurrentPixelSize() -> CGFloat {
        if qrCodeSize == .custom {
            return CGFloat(Int(customSize) ?? 512)
        } else {
            return qrCodeSize.pixelSize
        }
    }
    
    private func generateQRCode() {
        guard !inputText.isEmpty else {
            qrCodeImage = nil
            errorMessage = ""
            return
        }
        
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(inputText.utf8)
        filter.correctionLevel = correctionLevel
        
        if let outputImage = filter.outputImage {
            let pixelSize = getCurrentPixelSize()
            
            // Calculate scale factor based on the base QR code size (typically around 25-30 modules)
            // We use the extent size to determine the proper scaling
            let baseSize = outputImage.extent.width
            let scaleFactor = pixelSize / baseSize
            
            let transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                qrCodeImage = NSImage(cgImage: cgImage, size: NSSize(width: pixelSize, height: pixelSize))
                errorMessage = ""
            } else {
                qrCodeImage = nil
                errorMessage = "Failed to generate QR code"
            }
        } else {
            qrCodeImage = nil
            errorMessage = "Failed to create QR code filter"
        }
    }
    
    private func selectImageFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        
        if panel.runModal() == .OK {
            guard let url = panel.url else { return }
            scanQRCodeFromFile(url: url)
        }
    }
    
    private func pasteImageFromClipboard() {
        let pasteboard = NSPasteboard.general
        
        if let image = NSImage(pasteboard: pasteboard) {
            previewImage = image
            scanQRCodeFromImage(image: image)
        } else {
            errorMessage = "No image found in clipboard"
            scanResult = ""
            previewImage = nil
        }
    }
    
    private func scanQRCodeFromFile(url: URL) {
        guard let image = NSImage(contentsOf: url) else {
            errorMessage = "Failed to load image file"
            scanResult = ""
            previewImage = nil
            return
        }
        
        previewImage = image
        scanQRCodeFromImage(image: image)
    }
    
    private func scanQRCodeFromImage(image: NSImage) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            errorMessage = "Failed to process image"
            scanResult = ""
            return
        }
        
        let request = VNDetectBarcodesRequest { request, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Scan error: \(error.localizedDescription)"
                    self.scanResult = ""
                    return
                }
                
                guard let observations = request.results as? [VNBarcodeObservation],
                      !observations.isEmpty else {
                    self.errorMessage = "No QR code found in image"
                    self.scanResult = ""
                    return
                }
                
                if let firstCode = observations.first,
                   let payloadString = firstCode.payloadStringValue {
                    self.scanResult = payloadString
                    self.errorMessage = ""
                } else {
                    self.errorMessage = "Failed to decode QR code"
                    self.scanResult = ""
                }
            }
        }
        
        request.symbologies = [.qr]
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to scan image: \(error.localizedDescription)"
                    self.scanResult = ""
                }
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    private func copyImageToClipboard() {
        guard let image = qrCodeImage else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
    
    private func saveImage() {
        guard let image = qrCodeImage else { return }
        
        let panel = NSSavePanel()
        if #available(macOS 11.0, *) {
            panel.allowedContentTypes = [.png]
        } else {
            panel.allowedFileTypes = ["png"]
        }
        panel.nameFieldStringValue = "qrcode_\(Int(getCurrentPixelSize()))x\(Int(getCurrentPixelSize())).png"
        
        if panel.runModal() == .OK {
            guard let url = panel.url else { return }
            
            // Use a simpler approach to save the image
            do {
                // Get the image data directly
                if let tiffData = image.tiffRepresentation,
                   let bitmapRep = NSBitmapImageRep(data: tiffData) {
                    
                    // Convert to PNG
                    if let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                        try pngData.write(to: url)
                    }
                } else {
                    // Fallback: Create new bitmap and draw the image
                    let pixelSize = getCurrentPixelSize()
                    let size = NSSize(width: pixelSize, height: pixelSize)
                    
                    if let bitmapRep = NSBitmapImageRep(
                        bitmapDataPlanes: nil,
                        pixelsWide: Int(pixelSize),
                        pixelsHigh: Int(pixelSize),
                        bitsPerSample: 8,
                        samplesPerPixel: 4,
                        hasAlpha: false,
                        isPlanar: false,
                        colorSpaceName: .deviceRGB,
                        bytesPerRow: 0,
                        bitsPerPixel: 0
                    ) {
                        let context = NSGraphicsContext(bitmapImageRep: bitmapRep)
                        NSGraphicsContext.saveGraphicsState()
                        NSGraphicsContext.current = context
                        
                        image.draw(in: NSRect(origin: .zero, size: size))
                        
                        NSGraphicsContext.restoreGraphicsState()
                        
                        if let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                            try pngData.write(to: url)
                        }
                    }
                }
            } catch {
                print("Error saving QR code: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    QRCodeView()
}