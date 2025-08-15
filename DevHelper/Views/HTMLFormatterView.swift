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

struct HTMLFormatterView: View {
    let screenName = "HTML Formatter"
    @State private var htmlInput: String = ""
    @State private var htmlOutput: String = ""
    @State private var selectedMode: HTMLMode = .format
    @State private var validationMessage: String = ""
    @State private var isValid: Bool = true
    
    var body: some View {
        VStack(spacing: 20) {
            Text(screenName)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Mode Selection
            Picker("Mode", selection: $selectedMode) {
                ForEach(HTMLMode.allCases, id: \.self) { mode in
                    Text(mode.title)
                        .tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedMode) { _, _ in
                processHTML()
            }
            
            // Two-column Layout
            HStack(alignment: .top, spacing: 20) {
                // Input Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("HTML Input")
                            .font(.headline)
                        Spacer()
                        Button("Clear") {
                            htmlInput = ""
                            htmlOutput = ""
                            validationMessage = ""
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    CodeEditor.html(text: $htmlInput)
                        .padding(5)
                        .frame(maxHeight: .infinity)
                        .onChange(of: htmlInput) { _, _ in
                            processHTML()
                        }
                    
                    HStack {
                        Text("\(htmlInput.count) characters")
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
                        Text("HTML Output")
                            .font(.headline)
                        Spacer()
                        Button("Copy") {
                            copyToClipboard(htmlOutput)
                        }
                        .buttonStyle(.borderless)
                        .disabled(htmlOutput.isEmpty)
                    }
                    
                    CodeEditor.html(text: .constant(htmlOutput.isEmpty ? "Formatted HTML will appear here" : htmlOutput), readOnly: true)
                        .padding(5)
                        .frame(maxHeight: .infinity)
                    
                    Text("\(htmlOutput.count) characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 0)
            
            // Action Buttons
            HStack(spacing: 20) {
                Button("Sample") {
                    htmlInput = sampleHTML
                    processHTML()
                }
                .buttonStyle(.bordered)
                
                Button("Format") {
                    selectedMode = .format
                    processHTML()
                }
                .buttonStyle(.bordered)
                
                Button("Minify") {
                    selectedMode = .minify
                    processHTML()
                }
                .buttonStyle(.bordered)
                
                Button("Validate") {
                    selectedMode = .validate
                    processHTML()
                }
                .buttonStyle(.bordered)
                
                Button("Extract Text") {
                    selectedMode = .extractText
                    processHTML()
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
    
    private func processHTML() {
        guard !htmlInput.isEmpty else {
            htmlOutput = ""
            validationMessage = ""
            return
        }
        
        switch selectedMode {
        case .format:
            formatHTML()
        case .minify:
            minifyHTML()
        case .validate:
            validateHTML()
        case .extractText:
            extractText()
        }
    }
    
    private func formatHTML() {
        let formatted = formatHTMLString(htmlInput)
        htmlOutput = formatted
        isValid = true
        validationMessage = "✅ HTML formatted"
    }
    
    private func minifyHTML() {
        let minified = minifyHTMLString(htmlInput)
        htmlOutput = minified
        isValid = true
        validationMessage = "✅ HTML minified"
    }
    
    private func validateHTML() {
        let issues = validateHTMLString(htmlInput)
        
        if issues.isEmpty {
            htmlOutput = "✅ HTML is well-formed\n\n" + getHTMLInfo(htmlInput)
            isValid = true
            validationMessage = "✅ Valid HTML"
        } else {
            htmlOutput = "❌ HTML validation issues found:\n\n" + issues.joined(separator: "\n\n")
            isValid = false
            validationMessage = "❌ Found \(issues.count) issue(s)"
        }
    }
    
    private func extractText() {
        let text = extractTextFromHTML(htmlInput)
        htmlOutput = text
        isValid = true
        validationMessage = "✅ Text extracted"
    }
    
    private func formatHTMLString(_ html: String) -> String {
        var result = html
        var indentLevel = 0
        let indentSize = 2
        
        // Remove existing formatting
        result = result.replacingOccurrences(of: "\n", with: " ")
        result = result.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        
        // Add line breaks and indentation
        let pattern = #"(</?[^>]+>)"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))
        
        var formatted = ""
        var lastEnd = result.startIndex
        
        for match in matches {
            let range = Range(match.range, in: result)!
            let beforeTag = result[lastEnd..<range.lowerBound]
            let tag = result[range]
            
            // Add text before tag
            let trimmedBefore = beforeTag.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedBefore.isEmpty {
                if !formatted.isEmpty {
                    formatted += trimmedBefore
                }
            }
            
            // Check if it's a closing tag
            let isClosingTag = tag.hasPrefix("</")
            let isSelfClosingTag = tag.hasSuffix("/>") || isSelfClosingOrVoidTag(String(tag))
            
            // Adjust indent for closing tags
            if isClosingTag && indentLevel > 0 {
                indentLevel -= 1
            }
            
            // Add the tag with proper indentation
            if !formatted.isEmpty && !formatted.hasSuffix("\n") {
                formatted += "\n"
            }
            formatted += String(repeating: " ", count: indentLevel * indentSize) + tag
            
            // Adjust indent for opening tags
            if !isClosingTag && !isSelfClosingTag {
                indentLevel += 1
            }
            
            // Add newline after tag
            formatted += "\n"
            
            lastEnd = range.upperBound
        }
        
        // Add any remaining text
        let remaining = result[lastEnd...].trimmingCharacters(in: .whitespacesAndNewlines)
        if !remaining.isEmpty {
            formatted += remaining
        }
        
        return formatted.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func minifyHTMLString(_ html: String) -> String {
        var result = html
        
        // Remove comments
        result = result.replacingOccurrences(of: #"<!--[\s\S]*?-->"#, with: "", options: .regularExpression)
        
        // Remove extra whitespace
        result = result.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        
        // Remove whitespace around tags
        result = result.replacingOccurrences(of: #"\s*<\s*"#, with: "<", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\s*>\s*"#, with: ">", options: .regularExpression)
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func validateHTMLString(_ html: String) -> [String] {
        var issues: [String] = []
        
        // Basic HTML structure checks
        let hasHTML = html.lowercased().contains("<html")
        let hasHead = html.lowercased().contains("<head")
        let hasBody = html.lowercased().contains("<body")
        let hasTitle = html.lowercased().contains("<title")
        
        if hasHTML && !hasHead {
            issues.append("⚠️ Missing <head> section")
        }
        
        if hasHTML && !hasBody {
            issues.append("⚠️ Missing <body> section")
        }
        
        if hasHead && !hasTitle {
            issues.append("⚠️ Missing <title> tag in head section")
        }
        
        // Check for unclosed tags
        let tagPairs = findUnclosedTags(html)
        if !tagPairs.isEmpty {
            issues.append("⚠️ Unclosed tags found: \(tagPairs.joined(separator: ", "))")
        }
        
        // Check for invalid nesting
        let nestingIssues = checkNestingIssues(html)
        issues.append(contentsOf: nestingIssues)
        
        // Check for missing alt attributes on images
        if html.lowercased().contains("<img") {
            let imgPattern = #"<img[^>]*>"#
            let imgRegex = try! NSRegularExpression(pattern: imgPattern, options: .caseInsensitive)
            let imgMatches = imgRegex.matches(in: html, range: NSRange(html.startIndex..., in: html))
            
            for match in imgMatches {
                let range = Range(match.range, in: html)!
                let imgTag = html[range]
                if !imgTag.lowercased().contains("alt=") {
                    issues.append("⚠️ Image tag missing alt attribute: \(imgTag)")
                }
            }
        }
        
        return issues
    }
    
    private func getHTMLInfo(_ html: String) -> String {
        var info = ""
        
        // Count tags
        let tagPattern = #"<[^>]+>"#
        let tagRegex = try! NSRegularExpression(pattern: tagPattern)
        let tagCount = tagRegex.numberOfMatches(in: html, range: NSRange(html.startIndex..., in: html))
        info += "Total tags: \(tagCount)\n"
        
        // Count specific elements
        let elementCounts = [
            "div": html.lowercased().components(separatedBy: "<div").count - 1,
            "span": html.lowercased().components(separatedBy: "<span").count - 1,
            "p": html.lowercased().components(separatedBy: "<p").count - 1,
            "a": html.lowercased().components(separatedBy: "<a").count - 1,
            "img": html.lowercased().components(separatedBy: "<img").count - 1
        ]
        
        for (element, count) in elementCounts.sorted(by: { $0.value > $1.value }) {
            if count > 0 {
                info += "\(element.uppercased()): \(count)\n"
            }
        }
        
        return info
    }
    
    private func extractTextFromHTML(_ html: String) -> String {
        var text = html
        
        // Remove scripts and styles
        text = text.replacingOccurrences(of: #"<script[\s\S]*?</script>"#, with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: #"<style[\s\S]*?</style>"#, with: "", options: .regularExpression)
        
        // Remove comments
        text = text.replacingOccurrences(of: #"<!--[\s\S]*?-->"#, with: "", options: .regularExpression)
        
        // Remove all HTML tags
        text = text.replacingOccurrences(of: #"<[^>]*>"#, with: "", options: .regularExpression)
        
        // Decode HTML entities
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&#39;", with: "'")
        
        // Clean up whitespace
        text = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return text
    }
    
    private func findUnclosedTags(_ html: String) -> [String] {
        let tagPattern = #"</?([a-zA-Z][a-zA-Z0-9]*)[^>]*/?>"#
        let regex = try! NSRegularExpression(pattern: tagPattern, options: .caseInsensitive)
        let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
        
        var tagStack: [String] = []
        let voidTags = Set(["area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source", "track", "wbr"])
        
        for match in matches {
            let fullTagRange = Range(match.range, in: html)!
            let tagNameRange = Range(match.range(at: 1), in: html)!
            
            let fullTag = String(html[fullTagRange])
            let tagName = String(html[tagNameRange]).lowercased()
            
            if fullTag.hasPrefix("</") {
                // Closing tag
                if tagStack.last?.lowercased() == tagName {
                    tagStack.removeLast()
                }
            } else if !voidTags.contains(tagName) && !fullTag.hasSuffix("/>") {
                // Opening tag (not self-closing and not void)
                tagStack.append(tagName)
            }
        }
        
        return tagStack
    }
    
    private func checkNestingIssues(_ html: String) -> [String] {
        var issues: [String] = []
        
        // Check for invalid nesting patterns
        let invalidPatterns = [
            (#"<p[^>]*>[\s\S]*?<(div|p|h[1-6]|ul|ol|table)[^>]*>"#, "Block elements inside <p> tags"),
            (#"<button[^>]*>[\s\S]*?<button[^>]*>"#, "Nested <button> elements"),
            (#"<a[^>]*>[\s\S]*?<a[^>]*>"#, "Nested <a> elements"),
            (#"<form[^>]*>[\s\S]*?<form[^>]*>"#, "Nested <form> elements")
        ]
        
        for (pattern, message) in invalidPatterns {
            let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            if regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)) != nil {
                issues.append("⚠️ \(message)")
            }
        }
        
        return issues
    }
    
    private func isSelfClosingOrVoidTag(_ tag: String) -> Bool {
        let voidTags = Set(["area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source", "track", "wbr"])
        let tagName = tag.replacingOccurrences(of: #"</?([a-zA-Z][a-zA-Z0-9]*)[^>]*/?>"#, with: "$1", options: .regularExpression).lowercased()
        return tag.hasSuffix("/>") || voidTags.contains(tagName)
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(text, forType: .string)
    }
    
    private func saveState() {
        let defaults = UserDefaults.standard
        defaults.set(htmlInput, forKey: "HTMLFormatter.htmlInput")
        defaults.set(htmlOutput, forKey: "HTMLFormatter.htmlOutput")
        defaults.set(selectedMode.title, forKey: "HTMLFormatter.selectedMode")
        defaults.set(validationMessage, forKey: "HTMLFormatter.validationMessage")
        defaults.set(isValid, forKey: "HTMLFormatter.isValid")
    }
    
    private func loadState() {
        let defaults = UserDefaults.standard
        htmlInput = defaults.string(forKey: "HTMLFormatter.htmlInput") ?? ""
        htmlOutput = defaults.string(forKey: "HTMLFormatter.htmlOutput") ?? ""
        validationMessage = defaults.string(forKey: "HTMLFormatter.validationMessage") ?? ""
        isValid = defaults.bool(forKey: "HTMLFormatter.isValid")
        
        if let modeTitle = defaults.string(forKey: "HTMLFormatter.selectedMode") {
            selectedMode = HTMLMode.allCases.first { $0.title == modeTitle } ?? .format
        }
        
        // If we have input, trigger processing
        if !htmlInput.isEmpty {
            processHTML()
        }
    }
}

enum HTMLMode: CaseIterable {
    case format, minify, validate, extractText
    
    var title: String {
        switch self {
        case .format: return "Format"
        case .minify: return "Minify"
        case .validate: return "Validate"
        case .extractText: return "Extract Text"
        }
    }
}


private let sampleHTML = """
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sample HTML Page</title>
<style>
body { font-family: Arial, sans-serif; margin: 20px; }
.container { max-width: 800px; margin: 0 auto; }
.header { background-color: #f4f4f4; padding: 20px; border-radius: 5px; }
.content { margin-top: 20px; }
.footer { text-align: center; margin-top: 40px; color: #666; }
</style>
</head>
<body>
<div class="container">
<div class="header">
<h1>Welcome to Sample Page</h1>
<p>This is a sample HTML document with various elements.</p>
</div>
<div class="content">
<h2>Features</h2>
<ul>
<li>Semantic HTML structure</li>
<li>CSS styling</li>
<li>Proper nesting</li>
<li>Responsive design elements</li>
</ul>
<p>Here's a link to <a href="https://example.com">Example.com</a>.</p>
<img src="sample.jpg" alt="Sample image description">
</div>
<div class="footer">
<p>&copy; 2025 Sample Website. All rights reserved.</p>
</div>
</div>
</body>
</html>
"""

#Preview {
    HTMLFormatterView()
}