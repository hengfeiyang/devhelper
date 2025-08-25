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
import CodeMirror_SwiftUI

struct CodeEditor: View {
    @Binding var text: String
    let mode: Mode
    let theme: CodeViewTheme
    let fontSize: Int
    let showInvisibleCharacters: Bool
    let lineWrapping: Bool
    let readOnly: Bool
    
    init(
        text: Binding<String>,
        mode: Mode = CodeMode.javascript.mode(),
        theme: CodeViewTheme = .devhelperNight,
        fontSize: Int = 12,
        showInvisibleCharacters: Bool = false,
        lineWrapping: Bool = true,
        readOnly: Bool = false
    ) {
        self._text = text
        self.mode = mode
        self.theme = theme
        self.fontSize = fontSize
        self.showInvisibleCharacters = showInvisibleCharacters
        self.lineWrapping = lineWrapping
        self.readOnly = readOnly
    }
    
    var body: some View {
        CodeView(
            code: $text,
            mode: mode,
            theme: theme,
            fontSize: fontSize,
            showInvisibleCharacters: showInvisibleCharacters,
            lineWrapping: lineWrapping,
            readOnly: String(readOnly)
        )
        .onLoadSuccess {
            print("CodeMirror loaded successfully")
        }
        .onContentChange { newCode in
            text = newCode
        }
        .onLoadFail { error in
            print("CodeMirror load failed: \(error.localizedDescription)")
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
}

// Convenience initializers for common use cases
extension CodeEditor {
    // For JSON editing with syntax highlighting
    static func json(text: Binding<String>, readOnly: Bool = false) -> CodeEditor {
        CodeEditor(
            text: text,
            mode: CodeMode.json.mode(),
            theme: .devhelperNight,
            fontSize: 12,
            readOnly: readOnly
        )
    }
    
    // For plain text (no syntax highlighting)
    static func plain(text: Binding<String>, readOnly: Bool = false) -> CodeEditor {
        CodeEditor(
            text: text,
            mode: CodeMode.text.mode(),
            theme: .devhelperNight,
            fontSize: 12,
            readOnly: readOnly
        )
    }
    
    // For HTTP request body (JSON/XML)
    static func httpBody(text: Binding<String>, readOnly: Bool = false) -> CodeEditor {
        CodeEditor(
            text: text,
            mode: CodeMode.json.mode(),
            theme: .devhelperNight,
            fontSize: 12,
            readOnly: readOnly
        )
    }
    
    // For Swift code
    static func swift(text: Binding<String>, readOnly: Bool = false) -> CodeEditor {
        CodeEditor(
            text: text,
            mode: CodeMode.swift.mode(),
            theme: .devhelperNight,
            fontSize: 12,
            readOnly: readOnly
        )
    }
    
    // For JavaScript code
    static func javascript(text: Binding<String>, readOnly: Bool = false) -> CodeEditor {
        CodeEditor(
            text: text,
            mode: CodeMode.javascript.mode(),
            theme: .devhelperNight,
            fontSize: 12,
            readOnly: readOnly
        )
    }
    
    // For Python code
    static func python(text: Binding<String>, readOnly: Bool = false) -> CodeEditor {
        CodeEditor(
            text: text,
            mode: CodeMode.python.mode(),
            theme: .devhelperNight,
            fontSize: 12,
            readOnly: readOnly
        )
    }
    
    // For HTML code
    static func html(text: Binding<String>, readOnly: Bool = false) -> CodeEditor {
        CodeEditor(
            text: text,
            mode: CodeMode.html.mode(),
            theme: .devhelperNight,
            fontSize: 12,
            readOnly: readOnly
        )
    }
    
    // For CSS code
    static func css(text: Binding<String>, readOnly: Bool = false) -> CodeEditor {
        CodeEditor(
            text: text,
            mode: CodeMode.css.mode(),
            theme: .devhelperNight,
            fontSize: 12,
            readOnly: readOnly
        )
    }
    
    // For SQL code
    static func sql(text: Binding<String>, readOnly: Bool = false) -> CodeEditor {
        CodeEditor(
            text: text,
            mode: CodeMode.sql.mode(),
            theme: .devhelperNight,
            fontSize: 12,
            readOnly: readOnly
        )
    }
    
    // For XML code
    static func xml(text: Binding<String>, readOnly: Bool = false) -> CodeEditor {
        CodeEditor(
            text: text,
            mode: CodeMode.xml.mode(),
            theme: .devhelperNight,
            fontSize: 12,
            readOnly: readOnly
        )
    }
    
    // For YAML code
    static func yaml(text: Binding<String>, readOnly: Bool = false) -> CodeEditor {
        CodeEditor(
            text: text,
            mode: CodeMode.yaml.mode(),
            theme: .devhelperNight,
            fontSize: 12,
            readOnly: readOnly
        )
    }
    
    // For Markdown
    static func markdown(text: Binding<String>, readOnly: Bool = false) -> CodeEditor {
        CodeEditor(
            text: text,
            mode: CodeMode.markdown.mode(),
            theme: .devhelperNight,
            fontSize: 12,
            readOnly: readOnly
        )
    }
    
    // For Shell scripts
    static func shell(text: Binding<String>, readOnly: Bool = false) -> CodeEditor {
        CodeEditor(
            text: text,
            mode: CodeMode.shell.mode(),
            theme: .devhelperNight,
            fontSize: 12,
            readOnly: readOnly
        )
    }
}

// Diff Editor for comparing two texts
struct CodeDiffEditor: View {
    @Binding var leftContent: String
    @Binding var rightContent: String
    let mode: Mode
    let theme: CodeViewTheme
    let fontSize: Int
    let showInvisibleCharacters: Bool
    let lineWrapping: Bool
    let readOnly: Bool
    
    init(
        leftContent: Binding<String>,
        rightContent: Binding<String>,
        mode: Mode = CodeMode.json.mode(),
        theme: CodeViewTheme = .devhelperNight,
        fontSize: Int = 12,
        showInvisibleCharacters: Bool = false,
        lineWrapping: Bool = true,
        readOnly: Bool = false
    ) {
        self._leftContent = leftContent
        self._rightContent = rightContent
        self.mode = mode
        self.theme = theme
        self.fontSize = fontSize
        self.showInvisibleCharacters = showInvisibleCharacters
        self.lineWrapping = lineWrapping
        self.readOnly = readOnly
    }
    
    var body: some View {
        CodeDiffView(
            leftContent: $leftContent,
            rightContent: $rightContent,
            mode: mode,
            theme: theme,
            fontSize: fontSize,
            showInvisibleCharacters: showInvisibleCharacters,
            lineWrapping: lineWrapping,
            readOnly: readOnly
        )
        .onLoadSuccess {
            print("CodeDiffView loaded successfully")
        }
        .onContentChange { _ in
            // Handle content change if needed
        }
        .onLoadFail { error in
            print("CodeDiffView load failed: \(error.localizedDescription)")
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
}

// Convenience initializers for CodeDiffEditor
extension CodeDiffEditor {
    // For JSON diff with syntax highlighting
    static func json(leftContent: Binding<String>, rightContent: Binding<String>, readOnly: Bool = true) -> CodeDiffEditor {
        CodeDiffEditor(
            leftContent: leftContent,
            rightContent: rightContent,
            mode: CodeMode.json.mode(),
            theme: .devhelperNight,
            fontSize: 12,
            readOnly: readOnly
        )
    }
}
