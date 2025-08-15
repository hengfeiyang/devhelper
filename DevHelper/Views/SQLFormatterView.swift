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

struct SQLFormatterView: View {
    let screenName = "SQL Formatter"
    @State private var sqlInput: String = ""
    @State private var sqlOutput: String = ""
    @State private var selectedMode: SQLMode = .format
    @State private var validationMessage: String = ""
    @State private var isValid: Bool = true
    
    var body: some View {
        VStack(spacing: 20) {
            Text(screenName)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Mode Selection
            Picker("Mode", selection: $selectedMode) {
                ForEach(SQLMode.allCases, id: \.self) { mode in
                    Text(mode.title)
                        .tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedMode) { _, _ in
                processSQL()
            }
            
            // Two-column Layout
            HStack(alignment: .top, spacing: 20) {
                // Input Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("SQL Input")
                            .font(.headline)
                        Spacer()
                        Button("Clear") {
                            sqlInput = ""
                            sqlOutput = ""
                            validationMessage = ""
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    CodeEditor.sql(text: $sqlInput)
                        .padding(5)
                        .frame(maxHeight: .infinity)
                        .onChange(of: sqlInput) { _, _ in
                            processSQL()
                        }
                    
                    HStack {
                        Text("\(sqlInput.count) characters")
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
                        Text("SQL Output")
                            .font(.headline)
                        Spacer()
                        Button("Copy") {
                            copyToClipboard(sqlOutput)
                        }
                        .buttonStyle(.borderless)
                        .disabled(sqlOutput.isEmpty)
                    }
                    
                    CodeEditor.sql(text: .constant(sqlOutput.isEmpty ? "Formatted SQL will appear here" : sqlOutput), readOnly: true)
                        .padding(5)
                        .frame(maxHeight: .infinity)
                    
                    Text("\(sqlOutput.count) characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 0)
            
            // Action Buttons
            HStack(spacing: 20) {
                Button("Sample") {
                    sqlInput = sampleSQL
                    processSQL()
                }
                .buttonStyle(.bordered)
                
                Button("Format") {
                    selectedMode = .format
                    processSQL()
                }
                .buttonStyle(.bordered)
                
                Button("Minify") {
                    selectedMode = .minify
                    processSQL()
                }
                .buttonStyle(.bordered)
                
                Button("Validate") {
                    selectedMode = .validate
                    processSQL()
                }
                .buttonStyle(.bordered)
                
                Button("Analyze") {
                    selectedMode = .analyze
                    processSQL()
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
    
    private func processSQL() {
        guard !sqlInput.isEmpty else {
            sqlOutput = ""
            validationMessage = ""
            return
        }
        
        switch selectedMode {
        case .format:
            formatSQL()
        case .minify:
            minifySQL()
        case .validate:
            validateSQL()
        case .analyze:
            analyzeSQL()
        }
    }
    
    private func formatSQL() {
        let formatted = formatSQLString(sqlInput)
        sqlOutput = formatted
        isValid = true
        validationMessage = "✅ SQL formatted"
    }
    
    private func minifySQL() {
        let minified = minifySQLString(sqlInput)
        sqlOutput = minified
        isValid = true
        validationMessage = "✅ SQL minified"
    }
    
    private func validateSQL() {
        let issues = validateSQLString(sqlInput)
        
        if issues.isEmpty {
            sqlOutput = "✅ SQL syntax appears valid\n\n" + getSQLInfo(sqlInput)
            isValid = true
            validationMessage = "✅ Valid SQL"
        } else {
            sqlOutput = "❌ SQL validation issues found:\n\n" + issues.joined(separator: "\n\n")
            isValid = false
            validationMessage = "❌ Found \(issues.count) issue(s)"
        }
    }
    
    private func analyzeSQL() {
        let analysis = analyzeSQLString(sqlInput)
        sqlOutput = analysis
        isValid = true
        validationMessage = "✅ SQL analyzed"
    }
    
    private func formatSQLString(_ sql: String) -> String {
        var result = sql.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove extra whitespace
        result = result.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        
        // Keywords that should be on new lines
        let newLineKeywords = [
            "SELECT", "FROM", "WHERE", "GROUP BY", "HAVING", "ORDER BY", "LIMIT",
            "INSERT", "UPDATE", "DELETE", "CREATE", "ALTER", "DROP",
            "INNER JOIN", "LEFT JOIN", "RIGHT JOIN", "FULL JOIN", "JOIN",
            "UNION", "UNION ALL", "INTERSECT", "EXCEPT",
            "WITH", "AS", "CASE", "WHEN", "THEN", "ELSE", "END"
        ]
        
        // Add line breaks before major keywords
        for keyword in newLineKeywords.sorted(by: { $0.count > $1.count }) {
            let pattern = #"\b"# + NSRegularExpression.escapedPattern(for: keyword) + #"\b"#
            result = result.replacingOccurrences(
                of: pattern,
                with: "\n" + keyword,
                options: [.regularExpression, .caseInsensitive]
            )
        }
        
        // Handle commas in SELECT statements
        result = result.replacingOccurrences(of: ",", with: ",\n    ")
        
        // Handle parentheses
        result = result.replacingOccurrences(of: "(", with: "(\n    ")
        result = result.replacingOccurrences(of: ")", with: "\n)")
        
        // Clean up multiple newlines and add proper indentation
        var lines = result.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        lines = lines.filter { !$0.isEmpty }
        
        var indentLevel = 0
        var formattedLines: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty { continue }
            
            // Adjust indent for closing parentheses
            if trimmedLine.hasPrefix(")") && indentLevel > 0 {
                indentLevel -= 1
            }
            
            // Add indented line
            let indent = String(repeating: "    ", count: indentLevel)
            formattedLines.append(indent + trimmedLine)
            
            // Adjust indent for opening parentheses and subqueries
            if trimmedLine.hasSuffix("(") {
                indentLevel += 1
            }
        }
        
        return formattedLines.joined(separator: "\n")
    }
    
    private func minifySQLString(_ sql: String) -> String {
        var result = sql
        
        // Remove comments
        result = result.replacingOccurrences(of: #"--.*$"#, with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: #"/\*[\s\S]*?\*/"#, with: "", options: .regularExpression)
        
        // Remove extra whitespace
        result = result.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        
        // Remove spaces around operators and punctuation
        let operators = ["=", "<", ">", "<=", ">=", "<>", "!=", "+", "-", "*", "/", "(", ")", ",", ";"]
        for op in operators {
            result = result.replacingOccurrences(of: " \(op) ", with: op)
            result = result.replacingOccurrences(of: " \(op)", with: op)
            result = result.replacingOccurrences(of: "\(op) ", with: op)
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func validateSQLString(_ sql: String) -> [String] {
        var issues: [String] = []
        let lowercaseSQL = sql.lowercased()
        
        // Check for basic SQL structure
        if !containsSQLKeywords(lowercaseSQL) {
            issues.append("⚠️ No SQL keywords detected (SELECT, INSERT, UPDATE, DELETE, CREATE, etc.)")
        }
        
        // Check for unmatched parentheses
        let openParens = sql.filter { $0 == "(" }.count
        let closeParens = sql.filter { $0 == ")" }.count
        if openParens != closeParens {
            issues.append("⚠️ Unmatched parentheses: \(openParens) opening vs \(closeParens) closing")
        }
        
        // Check for unmatched quotes
        let singleQuotes = sql.filter { $0 == "'" }.count
        let doubleQuotes = sql.filter { $0 == "\"" }.count
        if singleQuotes % 2 != 0 {
            issues.append("⚠️ Unmatched single quotes")
        }
        if doubleQuotes % 2 != 0 {
            issues.append("⚠️ Unmatched double quotes")
        }
        
        // Check for SELECT without FROM (unless it's a simple expression)
        if lowercaseSQL.contains("select") && !lowercaseSQL.contains("from") && !isSimpleSelectExpression(lowercaseSQL) {
            issues.append("⚠️ SELECT statement without FROM clause")
        }
        
        // Check for common syntax issues
        if lowercaseSQL.contains("where") && lowercaseSQL.contains("group by") {
            let whereIndex = lowercaseSQL.range(of: "where")?.lowerBound
            let groupByIndex = lowercaseSQL.range(of: "group by")?.lowerBound
            if let whereIdx = whereIndex, let groupIdx = groupByIndex, whereIdx > groupIdx {
                issues.append("⚠️ WHERE clause should come before GROUP BY")
            }
        }
        
        // Check for missing semicolon at end (if it looks like a complete statement)
        let trimmed = sql.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !trimmed.hasSuffix(";") && isCompleteStatement(lowercaseSQL) {
            issues.append("⚠️ Statement should end with semicolon (;)")
        }
        
        return issues
    }
    
    private func getSQLInfo(_ sql: String) -> String {
        var info = ""
        let lowercaseSQL = sql.lowercased()
        
        // Detect SQL statement types
        var statementTypes: [String] = []
        if lowercaseSQL.contains("select") { statementTypes.append("SELECT") }
        if lowercaseSQL.contains("insert") { statementTypes.append("INSERT") }
        if lowercaseSQL.contains("update") { statementTypes.append("UPDATE") }
        if lowercaseSQL.contains("delete") { statementTypes.append("DELETE") }
        if lowercaseSQL.contains("create") { statementTypes.append("CREATE") }
        if lowercaseSQL.contains("alter") { statementTypes.append("ALTER") }
        if lowercaseSQL.contains("drop") { statementTypes.append("DROP") }
        
        if !statementTypes.isEmpty {
            info += "Statement types: \(statementTypes.joined(separator: ", "))\n"
        }
        
        // Count clauses
        var clauses: [String] = []
        if lowercaseSQL.contains("where") { clauses.append("WHERE") }
        if lowercaseSQL.contains("group by") { clauses.append("GROUP BY") }
        if lowercaseSQL.contains("having") { clauses.append("HAVING") }
        if lowercaseSQL.contains("order by") { clauses.append("ORDER BY") }
        if lowercaseSQL.contains("limit") { clauses.append("LIMIT") }
        
        if !clauses.isEmpty {
            info += "Clauses: \(clauses.joined(separator: ", "))\n"
        }
        
        // Count joins
        let joinTypes = ["inner join", "left join", "right join", "full join", "cross join", "join"]
        var joinCount = 0
        for joinType in joinTypes {
            joinCount += countOccurrences(of: joinType, in: lowercaseSQL)
        }
        if joinCount > 0 {
            info += "Joins: \(joinCount)\n"
        }
        
        // Count subqueries (rough estimate)
        let subqueryCount = max(0, sql.filter { $0 == "(" }.count - 1)
        if subqueryCount > 0 {
            info += "Potential subqueries: \(subqueryCount)\n"
        }
        
        return info
    }
    
    private func analyzeSQLString(_ sql: String) -> String {
        var analysis = "📊 SQL Query Analysis\n\n"
        let lowercaseSQL = sql.lowercased()
        
        // Query complexity analysis
        analysis += "🔍 Complexity Analysis:\n"
        
        let selectCount = countOccurrences(of: "select", in: lowercaseSQL)
        let joinCount = countOccurrences(of: "join", in: lowercaseSQL)
        let subqueryCount = max(0, sql.filter { $0 == "(" }.count - joinCount)
        let whereConditions = countOccurrences(of: "and", in: lowercaseSQL) + countOccurrences(of: "or", in: lowercaseSQL) + 1
        
        analysis += "• SELECT statements: \(selectCount)\n"
        analysis += "• JOINs: \(joinCount)\n"
        analysis += "• Subqueries: \(subqueryCount)\n"
        analysis += "• WHERE conditions: \(whereConditions)\n\n"
        
        // Performance considerations
        analysis += "⚡ Performance Considerations:\n"
        
        if lowercaseSQL.contains("select *") {
            analysis += "⚠️  Using SELECT * - consider specifying columns\n"
        }
        
        if !lowercaseSQL.contains("where") && (lowercaseSQL.contains("select") || lowercaseSQL.contains("update") || lowercaseSQL.contains("delete")) {
            analysis += "⚠️  No WHERE clause - may affect large datasets\n"
        }
        
        if joinCount > 3 {
            analysis += "⚠️  Multiple JOINs (\(joinCount)) - consider query optimization\n"
        }
        
        if subqueryCount > 2 {
            analysis += "⚠️  Multiple subqueries - consider using JOINs or CTEs\n"
        }
        
        if lowercaseSQL.contains("order by") && !lowercaseSQL.contains("limit") {
            analysis += "⚠️  ORDER BY without LIMIT - may be expensive\n"
        }
        
        if lowercaseSQL.contains("like '%") && lowercaseSQL.contains("%'") {
            analysis += "⚠️  Leading wildcard in LIKE - cannot use indexes\n"
        }
        
        analysis += "\n"
        
        // Security considerations
        analysis += "🔐 Security Notes:\n"
        if sql.contains("--") {
            analysis += "ℹ️  Contains SQL comments\n"
        }
        
        analysis += "ℹ️  Always use parameterized queries for user input\n"
        analysis += "ℹ️  Validate and sanitize all input data\n\n"
        
        // Suggestions
        analysis += "💡 Suggestions:\n"
        analysis += "• Use EXPLAIN to analyze execution plan\n"
        analysis += "• Consider indexing columns used in WHERE, JOIN, ORDER BY\n"
        analysis += "• Use LIMIT for large result sets\n"
        analysis += "• Consider using CTEs for complex subqueries\n"
        
        return analysis
    }
    
    private func containsSQLKeywords(_ sql: String) -> Bool {
        let keywords = ["select", "insert", "update", "delete", "create", "alter", "drop", "with"]
        return keywords.contains { sql.contains($0) }
    }
    
    private func isSimpleSelectExpression(_ sql: String) -> Bool {
        // Check if it's a simple SELECT expression like "SELECT 1" or "SELECT NOW()"
        let pattern = #"^\s*select\s+[\w\(\)\s\,\*\+\-\/]+\s*$"#
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        return regex.firstMatch(in: sql, range: NSRange(sql.startIndex..., in: sql)) != nil
    }
    
    private func isCompleteStatement(_ sql: String) -> Bool {
        let statementKeywords = ["select", "insert", "update", "delete", "create", "alter", "drop"]
        return statementKeywords.contains { sql.contains($0) }
    }
    
    private func countOccurrences(of substring: String, in string: String) -> Int {
        return string.components(separatedBy: substring).count - 1
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(text, forType: .string)
    }
    
    private func saveState() {
        let defaults = UserDefaults.standard
        defaults.set(sqlInput, forKey: "SQLFormatter.sqlInput")
        defaults.set(sqlOutput, forKey: "SQLFormatter.sqlOutput")
        defaults.set(selectedMode.title, forKey: "SQLFormatter.selectedMode")
        defaults.set(validationMessage, forKey: "SQLFormatter.validationMessage")
        defaults.set(isValid, forKey: "SQLFormatter.isValid")
    }
    
    private func loadState() {
        let defaults = UserDefaults.standard
        sqlInput = defaults.string(forKey: "SQLFormatter.sqlInput") ?? ""
        sqlOutput = defaults.string(forKey: "SQLFormatter.sqlOutput") ?? ""
        validationMessage = defaults.string(forKey: "SQLFormatter.validationMessage") ?? ""
        isValid = defaults.bool(forKey: "SQLFormatter.isValid")
        
        if let modeTitle = defaults.string(forKey: "SQLFormatter.selectedMode") {
            selectedMode = SQLMode.allCases.first { $0.title == modeTitle } ?? .format
        }
        
        // If we have input, trigger processing
        if !sqlInput.isEmpty {
            processSQL()
        }
    }
}

enum SQLMode: CaseIterable {
    case format, minify, validate, analyze
    
    var title: String {
        switch self {
        case .format: return "Format"
        case .minify: return "Minify"
        case .validate: return "Validate"
        case .analyze: return "Analyze"
        }
    }
}

private let sampleSQL = """
SELECT u.id, u.name, u.email, p.title as project_title, COUNT(t.id) as task_count FROM users u INNER JOIN projects p ON u.id = p.user_id LEFT JOIN tasks t ON p.id = t.project_id WHERE u.active = 1 AND p.status = 'active' AND t.completed = 0 GROUP BY u.id, p.id HAVING COUNT(t.id) > 0 ORDER BY u.name, task_count DESC LIMIT 10;
"""

#Preview {
    SQLFormatterView()
}