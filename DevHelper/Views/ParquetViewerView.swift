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
import UniformTypeIdentifiers
import AppKit
import DuckDB
import Arrow
import FlatBuffers
import FirebaseAnalytics

// Data row structure for Table view
struct ParquetRow: Identifiable {
    let id = UUID()
    let values: [String]
    
    subscript(index: Int) -> String {
        guard index < values.count else { return "" }
        return values[index]
    }
}

// Schema information structure
struct SchemaInfo: Identifiable {
    let id = UUID()
    let columnName: String
    let dataType: String
    let nullable: String
}

// Metadata key/value row structure
struct MetadataRow: Identifiable {
    let id = UUID()
    let key: String
    let value: String
}

enum FileType {
    case parquet
    case arrow
}

struct ParquetViewerView: View {
    let screenName = "Parquet Viewer"
    @State private var selectedTab = "schema"
    @State private var fileURL: URL?
    @State private var fileName: String = ""
    @State private var parquetFilePath: String = ""
    @State private var fileType: FileType = .parquet
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    @State private var tableRows: [ParquetRow] = []
    @State private var columnNames: [String] = []
    @State private var columnTypes: [String] = []
    @State private var schemaRows: [SchemaInfo] = []
    @State private var metadata: String = ""
    @State private var metadataRows: [MetadataRow] = []
    
    @State private var rowCount: Int = 0
    @State private var columnCount: Int = 0
    @State private var fileSize: String = ""
    
    @State private var selectedRows = Set<ParquetRow.ID>()

    // SQL playground state
    @State private var sqlInput: String = "SELECT * FROM tbl LIMIT 50"
    @State private var resolvedSQL: String = ""
    @State private var sqlIsRunning: Bool = false
    @State private var sqlErrorMessage: String?
    @State private var sqlRows: [ParquetRow] = []
    @State private var sqlColumnNames: [String] = []
    @State private var sqlColumnTypes: [String] = []
    @State private var sqlReturnedRowCount: Int = 0
    @State private var showSQLEditor: Bool = false
    @State private var isDragOver: Bool = false

    private let maxPreviewRows = 50
    
    var body: some View {
        VStack(spacing: 20) {
            Text(screenName)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                Button(action: selectFile) {
                    Label("Select File", systemImage: "doc.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                
                if fileURL != nil {
                    Button(action: clearFile) {
                        Label("Clear", systemImage: "xmark.circle")
                    }
                    .buttonStyle(.bordered)
                }
            }

            if fileURL != nil {
                TabView(selection: $selectedTab) {
                    schemaView
                        .tabItem {
                            Label("Schema", systemImage: "list.bullet.rectangle")
                        }
                        .tag("schema")
                    dataView
                        .tabItem {
                            Label("Data", systemImage: "tablecells")
                        }
                        .tag("data")
                    metadataView
                        .tabItem {
                            Label("Metadata", systemImage: "info.circle")
                        }
                        .tag("metadata")
                }
                .frame(maxHeight: .infinity)
            } else {
                // Drop zone for drag and drop
                VStack(spacing: 20) {
                    Image(systemName: isDragOver ? "arrow.down.circle.fill" : "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(isDragOver ? .accentColor : .secondary)
                    
                    Text(isDragOver ? "Drop the file here" : "Select a Parquet or Arrow file to view its contents")
                        .font(.title3)
                        .foregroundColor(isDragOver ? .accentColor : .secondary)
                    
                    Text(isDragOver ? "Release to load the file" : "or drag and drop a file here")
                        .font(.caption)
                        .foregroundColor(isDragOver ? .accentColor : .secondary.opacity(0.6))
                    
                    Text("Click to browse files")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.top, 5)
                }
                .frame(width: 400, height: 300)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isDragOver ? Color.accentColor : Color.secondary.opacity(0.3),
                            style: StrokeStyle(lineWidth: isDragOver ? 3 : 2, dash: [8])
                        )
                        .background(
                            isDragOver ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.05)
                        )
                        .cornerRadius(12)
                )
                .scaleEffect(isDragOver ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isDragOver)
                .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
                    handleDrop(providers: providers)
                    return true
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectFile()
                }
            }
            
            if let errorMessage = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .textSelection(.enabled)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                AnalyticsParameterScreenName: screenName
            ])
        }
    }
    
    @ViewBuilder
    private var dataView: some View {
        VStack(alignment: .leading, spacing: 10) {
            dataHeaderView
            
            if isLoading {
                ProgressView("Loading data...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if sqlIsRunning {
                ProgressView("Running SQL…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !tableRows.isEmpty {
                tableContentView
            } else {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private var dataHeaderView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Data")
                    .font(.headline)
                Spacer()
                if rowCount > 0 {
                    Text("\(rowCount) rows × \(columnCount) columns")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if fileType == .parquet {
                    Toggle("SQL Editor", isOn: $showSQLEditor)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .help("Show SQL editor")
                }
                Button(action: exportToCSV) {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .disabled(tableRows.isEmpty)
                Button(action: exportToJSON) {
                    Label("Export JSON", systemImage: "doc.text")
                }
                .buttonStyle(.bordered)
                .disabled(tableRows.isEmpty)
            }
            .padding(.horizontal)

            if showSQLEditor {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("SQL")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Use \"tbl\" as the table for the selected Parquet file")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: runSQLQuery) {
                        Label(sqlIsRunning ? "Running…" : "Run", systemImage: sqlIsRunning ? "hourglass" : "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(fileURL == nil || sqlIsRunning || sqlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                CodeEditor.sql(text: $sqlInput)
                    .frame(minHeight: 80, maxHeight: 80)
                if let sqlErrorMessage = sqlErrorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle").foregroundColor(.red)
                        Text(sqlErrorMessage).font(.caption).foregroundColor(.red)
                            .textSelection(.enabled)
                    }
                    .padding(6)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            }
        }
    }
    
    private var tableContentView: some View {
        ParquetTableViewRepresentable(
            rows: tableRows,
            columns: columnNames,
            columnTypes: columnTypes,
            columnWidth: 150
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private struct RowCellView: View {
        let text: String
        var body: some View {
            Text(text)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.tail)
                .textSelection(.enabled)
                .help(text)
        }
    }
    
    private func tableHeaderRow(columnWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(columnNames.enumerated()), id: \.offset) { index, columnName in
                headerCell(columnName: columnName, index: index, columnWidth: columnWidth)
            }
        }
    }
    
    @ViewBuilder
    private func headerCell(columnName: String, index: Int, columnWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(columnName)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.bold)
                .lineLimit(1)
                .truncationMode(.tail)
            if index < columnTypes.count {
                Text(columnTypes[index])
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(8)
        .frame(width: columnWidth, alignment: .leading)
        .background(AppConstants.lightGrayBackground)
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
        )
    }
    
    private func tableDataRow(row: ParquetRow, rowIndex: Int, columnWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<columnNames.count, id: \.self) { colIndex in
                dataCell(value: row[colIndex], rowIndex: rowIndex, columnWidth: columnWidth)
            }
        }
    }
    
    private func dataCell(value: String, rowIndex: Int, columnWidth: CGFloat) -> some View {
        Text(value)
            .font(.system(.caption, design: .monospaced))
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(8)
            .frame(width: columnWidth, alignment: .leading)
            .background(rowIndex % 2 == 0 ? Color.clear : Color.gray.opacity(0.05))
            .overlay(
                Rectangle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
            )
            .textSelection(.enabled)
            .help(value) // Show full text on hover
    }
    
    private var schemaView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Schema Information")
                    .font(.headline)
                
                Spacer()
                
                if !schemaRows.isEmpty {
                    Text("\(schemaRows.count) columns")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: exportSchemaToCSV) {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .disabled(schemaRows.isEmpty)
                
                Button(action: exportSchemaToJSON) {
                    Label("Export JSON", systemImage: "doc.text")
                }
                .buttonStyle(.bordered)
                .disabled(schemaRows.isEmpty)
            }
            .padding(.horizontal)
            
            if schemaRows.isEmpty {
                Text("No schema information available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                SchemaTableViewRepresentable(rows: schemaRows)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var sqlTableContentView: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 0) {
                // Header row
                HStack(spacing: 0) {
                    ForEach(Array(sqlColumnNames.enumerated()), id: \.offset) { index, columnName in
                        sqlHeaderCell(columnName: columnName, index: index)
                    }
                }

                // Data rows
                ForEach(Array(sqlRows.enumerated()), id: \.element.id) { rowIndex, row in
                    HStack(spacing: 0) {
                        ForEach(0..<sqlColumnNames.count, id: \.self) { colIndex in
                            sqlDataCell(value: row[colIndex], rowIndex: rowIndex)
                        }
                    }
                }
            }
        }
        .background(Color.gray.opacity(0.05))
    }

    @ViewBuilder
    private func sqlHeaderCell(columnName: String, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(columnName)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.bold)
                .lineLimit(1)
                .truncationMode(.tail)
            if index < sqlColumnTypes.count {
                Text(sqlColumnTypes[index])
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(8)
        .frame(width: 150, alignment: .leading)
        .background(AppConstants.lightGrayBackground)
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private func sqlDataCell(value: String, rowIndex: Int) -> some View {
        Text(value)
            .font(.system(.caption, design: .monospaced))
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(8)
            .frame(width: 150, alignment: .leading)
            .background(rowIndex % 2 == 0 ? Color.clear : Color.gray.opacity(0.05))
            .overlay(
                Rectangle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
            )
            .textSelection(.enabled)
            .help(value)
    }

    private var metadataView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("File Metadata")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { copyToClipboard(metadata) }) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .disabled(metadata.isEmpty)
            }
            .padding(.horizontal)
            
            if metadataRows.isEmpty {
                ScrollView {
                    Text(metadata.isEmpty ? "No metadata available" : metadata)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            } else {
                MetadataTableViewRepresentable(rows: metadataRows)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.title = "Select Parquet or Arrow File"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            UTType(filenameExtension: "parquet") ?? .data,
            UTType(filenameExtension: "arrow") ?? .data,
            UTType(filenameExtension: "feather") ?? .data,
            UTType(filenameExtension: "ipc") ?? .data
        ]
        
        if panel.runModal() == .OK, let url = panel.url {
            loadFile(url)
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (data, error) in
            if let error = error {
                print("Error loading dropped item: \(error)")
                return
            }
            
            guard let data = data as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }
            
            // Check if the file has a supported extension
            let ext = url.pathExtension.lowercased()
            let supportedExtensions = ["parquet", "arrow", "feather", "ipc"]
            
            guard supportedExtensions.contains(ext) else {
                DispatchQueue.main.async {
                    self.errorMessage = "Unsupported file type. Please use .parquet, .arrow, .feather, or .ipc files."
                }
                return
            }
            
            // Load the file on the main thread
            DispatchQueue.main.async {
                self.loadFile(url)
            }
        }
    }
    
    private func clearFile() {
        fileURL = nil
        fileName = ""
        tableRows = []
        columnNames = []
        columnTypes = []
        schemaRows = []
        metadata = ""
        metadataRows = []
        rowCount = 0
        columnCount = 0
        fileSize = ""
        errorMessage = nil
        selectedRows = Set<ParquetRow.ID>()
        // Reset SQL state
        sqlInput = "SELECT * FROM tbl LIMIT 50"
        resolvedSQL = ""
        sqlIsRunning = false
        sqlErrorMessage = nil
        sqlRows = []
        sqlColumnNames = []
        sqlColumnTypes = []
        sqlReturnedRowCount = 0
        selectedTab = "schema"
    }
    
    private func loadFile(_ url: URL) {
        fileURL = url
        fileName = url.lastPathComponent
        parquetFilePath = url.path
        isLoading = true
        errorMessage = nil
        selectedTab = "schema"
        
        // Detect file type based on extension
        let ext = url.pathExtension.lowercased()
        if ext == "parquet" {
            fileType = .parquet
        } else if ext == "arrow" || ext == "feather" || ext == "ipc" {
            fileType = .arrow
        } else {
            // Default to parquet if unknown
            fileType = .parquet
        }
        
        // Get file size
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let size = attributes[.size] as? Int64 {
                fileSize = formatFileSize(size)
            }
        } catch {
            print("Failed to get file attributes: \(error)")
        }
        
        Task {
            if fileType == .arrow {
                await parseArrowFile(url)
            } else {
                await parseParquetFileWithDuckDB(url)
            }
        }
    }
    
    private func parseParquetFileWithDuckDB(_ url: URL) async {
        do {
            // Create in-memory database
            let database = try Database(store: .inMemory)
            let connection = try database.connect()
            
            // Get row count first
            let countResult = try connection.query("""
                SELECT COUNT(*) FROM read_parquet('\(url.path)')
            """)
            
            if let countColumn = countResult.first {
                let count = countColumn.cast(to: Int64.self)[DBInt(0)] ?? 0
                await MainActor.run {
                    self.rowCount = Int(count)
                }
            }
            
            // Get schema information
            let schemaResult = try connection.query("""
                DESCRIBE SELECT * FROM read_parquet('\(url.path)')
            """)
            
            var colNames: [String] = []
            var colTypes: [String] = []
            var schemaInfoRows: [SchemaInfo] = []
            
            if schemaResult.count >= 3 {
                let columnNameCol = schemaResult[0]
                let columnTypeCol = schemaResult[1]
                let nullableCol = schemaResult[2]
                
                let nameStrings = columnNameCol.cast(to: String.self)
                let typeStrings = columnTypeCol.cast(to: String.self)
                let nullableStrings = nullableCol.cast(to: String.self)
                
                for i in 0..<nameStrings.count {
                    let idx = DBInt(i)
                    let name = nameStrings[idx] ?? "unknown"
                    let type = typeStrings[idx] ?? "unknown"
                    let nullable = nullableStrings[idx] ?? "unknown"
                    
                    colNames.append(name)
                    colTypes.append(type)
                    
                    // Create schema info row for table display
                    schemaInfoRows.append(SchemaInfo(
                        columnName: name,
                        dataType: type,
                        nullable: nullable == "YES" ? "Yes" : "No"
                    ))
                }
            }
            
            await MainActor.run {
                self.columnNames = colNames
                self.columnTypes = colTypes
                self.columnCount = colNames.count
                self.schemaRows = schemaInfoRows
            }
            
            // Do not auto-populate preview rows; the Data tab will be driven by SQL input
            
            // Get Parquet file metadata
            var metadataRows: [MetadataRow] = []
            metadataRows.append(MetadataRow(key: "File Name", value: fileName))
            
            // Query parquet_metadata function
            let fileMetadataResult = try connection.query("""
                SELECT * FROM parquet_file_metadata('\(url.path)')
            """)
            
            if !fileMetadataResult.isEmpty && fileMetadataResult[0].count > 0 {
                // Extract metadata fields
                if fileMetadataResult.count >= 6 {
                    let createdByCol = fileMetadataResult[1].cast(to: String.self)
                    let numRowsCol = fileMetadataResult[2].cast(to: Int64.self) 
                    let numRowGroupsCol = fileMetadataResult[3].cast(to: Int64.self)
                    let formatVersionCol = fileMetadataResult[4].cast(to: Int64.self)
                    let encryptionAlgorithmCol = fileMetadataResult[5].cast(to: String.self)
                    
                    if let createdBy = createdByCol[0] {
                        metadataRows.append(MetadataRow(key: "Created By", value: createdBy))
                    }
                    if !fileSize.isEmpty {
                        metadataRows.append(MetadataRow(key: "File Size", value: fileSize))
                    }
                    metadataRows.append(MetadataRow(key: "Total Columns", value: String(columnCount)))
                    if let numRows = numRowsCol[0] {
                        metadataRows.append(MetadataRow(key: "Total Rows", value: String(numRows)))
                    }
                    if let numRowGroups = numRowGroupsCol[0] {
                        metadataRows.append(MetadataRow(key: "Total Row Groups", value: String(numRowGroups)))
                    }
                    if let formatVersion = formatVersionCol[0] {
                        metadataRows.append(MetadataRow(key: "Format Version", value: String(formatVersion)))
                    }
                    if let encryptionAlgorithm = encryptionAlgorithmCol[0] {
                        metadataRows.append(MetadataRow(key: "Encryption Algorithm", value: encryptionAlgorithm))
                    } 
                }
            }
            
            // Query parquet_kv_metadata function
            let kvMetadataResult = try connection.query("""
                SELECT file_name::STRING, key::STRING, value::STRING FROM (SELECT * FROM parquet_kv_metadata('\(url.path)'))
            """)
            
            if !kvMetadataResult.isEmpty && kvMetadataResult.count > 0 {
                _ = kvMetadataResult[0].cast(to: String.self) // file_name column
                let keyCol = kvMetadataResult[1].cast(to: String.self)
                let valueCol = kvMetadataResult[2].cast(to: String.self)
                
                // Iterate through all rows in the result set
                for i in 0..<keyCol.count {
                    let idx = DBInt(i)
                    if let key = keyCol[idx], let value = valueCol[idx] {
                        metadataRows.append(MetadataRow(key: key, value: value))
                    }
                }
            } else {
                metadataRows.append(MetadataRow(key: "Key-Value Metadata", value: "None found"))
            }
            
            await MainActor.run {
                self.metadataRows = metadataRows
                // Generate the text version for the copy button
                self.metadata = self.generateMetadataText(from: metadataRows)
                self.isLoading = false
                // Default to Schema tab on load
                self.selectedTab = "schema"
                // Auto-run default SQL once file is loaded so Data is ready when user switches
                self.sqlInput = "SELECT * FROM tbl LIMIT \(maxPreviewRows)"
                self.runSQLQuery()
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load Parquet file: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func parseArrowFile(_ url: URL) async {
        // Read the Arrow file using ArrowReader
        let arrowReader = ArrowReader()
        let result = arrowReader.fromFile(url)
        
        switch result {
        case .success(let arrowResult):
                // Calculate total row count
                var totalRows = 0
                for batch in arrowResult.batches {
                    totalRows += Int(batch.length)
                }
                
                // Get column count from schema
                let columnCount = arrowResult.schema?.fields.count ?? 0
                
                await MainActor.run {
                    self.rowCount = totalRows
                    self.columnCount = columnCount
                }
                
                // Extract schema information
                var colNames: [String] = []
                var colTypes: [String] = []
                var schemaInfoRows: [SchemaInfo] = []
                
                for field in arrowResult.schema?.fields ?? [] {
                    let name = field.name
                    let typeStr = getArrowTypeDescription(field.type)
                    let nullable = field.isNullable ? "Yes" : "No"
                    
                    colNames.append(name)
                    colTypes.append(typeStr)
                    
                    schemaInfoRows.append(SchemaInfo(
                        columnName: name,
                        dataType: typeStr,
                        nullable: nullable
                    ))
                }
                
                await MainActor.run {
                    self.columnNames = colNames
                    self.columnTypes = colTypes
                    self.schemaRows = schemaInfoRows
                }
                
                // Load data preview (first maxPreviewRows rows from all batches)
                var rows: [ParquetRow] = []
                var rowsLoaded = 0
                
                for batch in arrowResult.batches {
                    if rowsLoaded >= maxPreviewRows {
                        break
                    }
                    
                    let rowsToLoad = min(Int(batch.length), maxPreviewRows - rowsLoaded)
                    
                    // Get the number of columns from the schema
                    let numColumns = arrowResult.schema?.fields.count ?? 0
                    
                    for rowIndex in 0..<rowsToLoad {
                        var rowValues: [String] = []
                        
                        // Extract value for each column
                        for colIndex in 0..<numColumns {
                            let value = extractValueFromBatch(batch, columnIndex: colIndex, rowIndex: rowIndex)
                            rowValues.append(value)
                        }
                        
                        rows.append(ParquetRow(values: rowValues))
                        rowsLoaded += 1
                    }
                }
                
                await MainActor.run {
                    self.tableRows = rows
                }
                
                // Build metadata information
                var metadataRows: [MetadataRow] = []
                metadataRows.append(MetadataRow(key: "File Name", value: fileName))
                metadataRows.append(MetadataRow(key: "File Size", value: fileSize))
                metadataRows.append(MetadataRow(key: "Total Columns", value: String(columnCount)))
                metadataRows.append(MetadataRow(key: "Total Batches", value: String(arrowResult.batches.count)))
                metadataRows.append(MetadataRow(key: "Total Rows", value: String(totalRows)))
                metadataRows.append(MetadataRow(key: "Format", value: "Apache Arrow IPC"))
                
                // Arrow Swift doesn't expose schema metadata
                metadataRows.append(MetadataRow(key: "Schema Metadata", value: "Not available"))
                
                await MainActor.run {
                    self.metadataRows = metadataRows
                    // Generate the text version for the copy button
                    self.metadata = self.generateMetadataText(from: metadataRows)
                    self.isLoading = false
                    // For Arrow files, we don't have SQL support, so don't auto-run SQL
                    self.showSQLEditor = false
                }
                
        case .failure(let error):
            await MainActor.run {
                self.errorMessage = "Failed to load Arrow file: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func getArrowTypeDescription(_ type: ArrowType) -> String {
        switch type.id {
        case .boolean: return "Boolean"
        case .int8: return "Int8"
        case .int16: return "Int16"
        case .int32: return "Int32"
        case .int64: return "Int64"
        case .uint8: return "UInt8"
        case .uint16: return "UInt16"
        case .uint32: return "UInt32"
        case .uint64: return "UInt64"
        case .float: return "Float32"
        case .double: return "Float64"
        case .string: return "String"
        case .binary: return "Binary"
        case .date32: return "Date32"
        case .date64: return "Date64"
        case .time32: return "Time32"
        case .time64: return "Time64"
        case .timestamp: return "Timestamp"
        case .decimal128: return "Decimal128"
        case .decimal256: return "Decimal256"
        case .list: return "List"
        case .strct: return "Struct"
        default: return "Unknown"
        }
    }
    
    private func extractValueFromBatch(_ batch: RecordBatch, columnIndex: Int, rowIndex: Int) -> String {
        // Get the field type for this column
        let schema = batch.schema
        guard let field = schema.fields[safe: columnIndex] else {
            return "ERROR"
        }
        
        let rowIdx = UInt(rowIndex)
        
        // Based on the field type, extract the appropriate data
        switch field.type.id {
        case .boolean:
            let array: ArrowArray<Bool> = batch.data(for: columnIndex)
            return array[rowIdx] != nil ? String(array[rowIdx]!) : "NULL"
            
        case .int8:
            let array: ArrowArray<Int8> = batch.data(for: columnIndex)
            return array[rowIdx] != nil ? String(array[rowIdx]!) : "NULL"
            
        case .int16:
            let array: ArrowArray<Int16> = batch.data(for: columnIndex)
            return array[rowIdx] != nil ? String(array[rowIdx]!) : "NULL"
            
        case .int32:
            let array: ArrowArray<Int32> = batch.data(for: columnIndex)
            return array[rowIdx] != nil ? String(array[rowIdx]!) : "NULL"
            
        case .int64:
            let array: ArrowArray<Int64> = batch.data(for: columnIndex)
            return array[rowIdx] != nil ? String(array[rowIdx]!) : "NULL"
            
        case .uint8:
            let array: ArrowArray<UInt8> = batch.data(for: columnIndex)
            return array[rowIdx] != nil ? String(array[rowIdx]!) : "NULL"
            
        case .uint16:
            let array: ArrowArray<UInt16> = batch.data(for: columnIndex)
            return array[rowIdx] != nil ? String(array[rowIdx]!) : "NULL"
            
        case .uint32:
            let array: ArrowArray<UInt32> = batch.data(for: columnIndex)
            return array[rowIdx] != nil ? String(array[rowIdx]!) : "NULL"
            
        case .uint64:
            let array: ArrowArray<UInt64> = batch.data(for: columnIndex)
            return array[rowIdx] != nil ? String(array[rowIdx]!) : "NULL"
            
        case .float:
            let array: ArrowArray<Float> = batch.data(for: columnIndex)
            return array[rowIdx] != nil ? String(array[rowIdx]!) : "NULL"
            
        case .double:
            let array: ArrowArray<Double> = batch.data(for: columnIndex)
            return array[rowIdx] != nil ? String(array[rowIdx]!) : "NULL"
            
        case .string:
            let array: ArrowArray<String> = batch.data(for: columnIndex)
            return array[rowIdx] ?? "NULL"
            
        case .date32:
            let array: ArrowArray<Date32> = batch.data(for: columnIndex)
            if let days = array[rowIdx] {
                let date = Date(timeIntervalSince1970: TimeInterval(days) * 86400)
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter.string(from: date)
            }
            return "NULL"
            
        case .date64:
            let array: ArrowArray<Date64> = batch.data(for: columnIndex)
            if let milliseconds = array[rowIdx] {
                let date = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                return formatter.string(from: date)
            }
            return "NULL"
            
        default:
            return "Unsupported"
        }
    }

    private func runSQLQuery() {
        guard !parquetFilePath.isEmpty else { return }
        sqlIsRunning = true
        sqlErrorMessage = nil
        sqlRows = []
        sqlColumnNames = []
        sqlColumnTypes = []
        sqlReturnedRowCount = 0
        // Build actual SQL by replacing tbl with read_parquet('<file>') under the hood
        resolvedSQL = buildResolvedSQL(from: sqlInput)

        Task {
            do {
                let database = try Database(store: .inMemory)
                let connection = try database.connect()

                // Expose the parquet file as a view named `tbl`
                let escapedPath = parquetFilePath.replacingOccurrences(of: "'", with: "''")
                _ = try connection.query("""
                    CREATE OR REPLACE VIEW tbl AS SELECT * FROM read_parquet('\(escapedPath)')
                """)

                let trimmed = sqlInput.trimmingCharacters(in: .whitespacesAndNewlines)
                if isSelectOrWithQuery(trimmed) {
                    // Get schema for result
                    let describeResult = try connection.query("""
                        DESCRIBE \(trimmed)
                    """)

                    var colNames: [String] = []
                    var colTypes: [String] = []
                    if describeResult.count >= 2 {
                        let nameCol = describeResult[0].cast(to: String.self)
                        let typeCol = describeResult[1].cast(to: String.self)
                        for i in 0..<(nameCol.count) {
                            let idx = DBInt(i)
                            colNames.append(nameCol[idx] ?? "")
                            colTypes.append(typeCol[idx] ?? "")
                        }
                    }

                    let dataResult = try connection.query(trimmed)

                    var rows: [ParquetRow] = []
                    if !dataResult.isEmpty {
                        let numRows = dataResult[0].count
                        for rowIdx in 0..<numRows {
                            var rowValues: [String] = []
                            for column in dataResult {
                                let value = extractValueFromColumn(column, at: rowIdx)
                                rowValues.append(value)
                            }
                            rows.append(ParquetRow(values: rowValues))
                        }
                    }

            await MainActor.run {
                // Reflect results to the main data table
                self.columnNames = colNames
                self.columnTypes = colTypes
                self.tableRows = rows
                self.rowCount = rows.count
                self.columnCount = colNames.count
                // Keep SQL-specific mirrors in sync (optional)
                self.sqlColumnNames = colNames
                self.sqlColumnTypes = colTypes
                self.sqlRows = rows
                self.sqlReturnedRowCount = rows.count
                self.sqlIsRunning = false
            }
                } else {
                    // Non-SELECT statements
                    _ = try connection.query(trimmed)
                    await MainActor.run {
                        self.tableRows = []
                        self.columnNames = []
                        self.columnTypes = []
                        self.rowCount = 0
                        self.columnCount = 0
                        self.sqlRows = []
                        self.sqlColumnNames = []
                        self.sqlColumnTypes = []
                        self.sqlReturnedRowCount = 0
                        self.sqlIsRunning = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.sqlErrorMessage = "SQL error: \(error.localizedDescription)"
                    self.sqlIsRunning = false
                }
            }
        }
    }

    private func isSelectOrWithQuery(_ sql: String) -> Bool {
        let lower = sql.lowercased()
        return lower.hasPrefix("select") || lower.hasPrefix("with ")
    }

    private func buildResolvedSQL(from input: String) -> String {
        guard !parquetFilePath.isEmpty else { return input }
        let escapedPath = parquetFilePath.replacingOccurrences(of: "'", with: "''")
        let replacement = "read_parquet('\(escapedPath)')"
        // Replace word-boundary occurrences of tbl (case-insensitive)
        do {
            let regex = try NSRegularExpression(pattern: "(?i)\\btbl\\b")
            let range = NSRange(location: 0, length: (input as NSString).length)
            return regex.stringByReplacingMatches(in: input, options: [], range: range, withTemplate: replacement)
        } catch {
            return input.replacingOccurrences(of: "tbl", with: replacement)
        }
    }

    
    private func exportToCSV() {
        let savePanel = NSSavePanel()
        savePanel.title = "Export as CSV"
        savePanel.nameFieldStringValue = fileName.replacingOccurrences(of: ".parquet", with: ".csv")
        savePanel.allowedContentTypes = [UTType.commaSeparatedText]
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            // For export, we need to load all data - do this in a separate query
            Task {
                await exportAllDataAsCSV(to: url)
            }
        }
    }
    
    private func exportAllDataAsCSV(to url: URL) async {
        do {
            // Export current result shown in the Data tab
            var csvContent = columnNames.map { "\"\($0)\"" }.joined(separator: ",") + "\n"
            for row in tableRows {
                let line = row.values.map { "\"\($0)\"" }.joined(separator: ",")
                csvContent += line + "\n"
            }
            try csvContent.write(to: url, atomically: true, encoding: .utf8)
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to export CSV: \(error.localizedDescription)"
            }
        }
    }
    
    private func exportSchemaToCSV() {
        let savePanel = NSSavePanel()
        savePanel.title = "Export Schema as CSV"
        savePanel.nameFieldStringValue = fileName.replacingOccurrences(of: ".parquet", with: "_schema.csv")
        savePanel.allowedContentTypes = [UTType.commaSeparatedText]
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            var csvContent = "Column Name,Data Type,Nullable\n"
            
            for row in schemaRows {
                csvContent += "\"\(row.columnName)\",\"\(row.dataType)\",\"\(row.nullable)\"\n"
            }
            
            do {
                try csvContent.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                self.errorMessage = "Failed to export schema: \(error.localizedDescription)"
            }
        }
    }
    
    private func exportSchemaToJSON() {
        let savePanel = NSSavePanel()
        savePanel.title = "Export Schema as JSON"
        savePanel.nameFieldStringValue = fileName.replacingOccurrences(of: ".parquet", with: "_schema.json")
        savePanel.allowedContentTypes = [UTType.json]
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            var jsonArray: [[String: String]] = []
            
            for row in schemaRows {
                let jsonObject: [String: String] = [
                    "column_name": row.columnName,
                    "data_type": row.dataType,
                    "nullable": row.nullable
                ]
                jsonArray.append(jsonObject)
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: [.prettyPrinted, .sortedKeys])
                try jsonData.write(to: url)
            } catch {
                self.errorMessage = "Failed to export schema as JSON: \(error.localizedDescription)"
            }
        }
    }
    
    private func exportToJSON() {
        let savePanel = NSSavePanel()
        savePanel.title = "Export as JSON"
        savePanel.nameFieldStringValue = fileName.replacingOccurrences(of: ".parquet", with: ".json")
        savePanel.allowedContentTypes = [UTType.json]
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            // For export, we need to load all data - do this in a separate query
            Task {
                await exportAllDataAsJSON(to: url)
            }
        }
    }
    
    private func exportAllDataAsJSON(to url: URL) async {
        do {
            // Export current result shown in the Data tab
            var jsonArray: [[String: String]] = []
            for row in tableRows {
                var jsonObject: [String: String] = [:]
                for (idx, name) in columnNames.enumerated() {
                    jsonObject[name] = row[idx]
                }
                jsonArray.append(jsonObject)
            }
            let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: [.prettyPrinted, .sortedKeys])
            try jsonData.write(to: url)
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to export JSON: \(error.localizedDescription)"
            }
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func extractValueFromColumn(_ column: DuckDB.Column<Void>, at index: Int) -> String {
        let idx = DBInt(index)
        
        // Try to cast to various types and extract the value
        // The cast method doesn't return optional, so we access directly
        
        // First try String as it's most common
        let stringColumn = column.cast(to: String.self)
        if let value = stringColumn[idx] {
            return value
        }
        
        // Try Int64
        let int64Column = column.cast(to: Int64.self)
        if let value = int64Column[idx] {
            return String(value)
        }
        
        // Try Int32
        let int32Column = column.cast(to: Int32.self)
        if let value = int32Column[idx] {
            return String(value)
        }
        
        // Try Double
        let doubleColumn = column.cast(to: Double.self)
        if let value = doubleColumn[idx] {
            // Format double with reasonable precision
            if value.truncatingRemainder(dividingBy: 1) == 0 {
                return String(Int(value))
            } else {
                return String(value)
            }
        }
        
        // Try Float
        let floatColumn = column.cast(to: Float.self)
        if let value = floatColumn[idx] {
            return String(value)
        }
        
        // Try Bool
        let boolColumn = column.cast(to: Bool.self)
        if let value = boolColumn[idx] {
            return value ? "true" : "false"
        }
        
        // Try DuckDB.Date (not Foundation.Date)
        let dateColumn = column.cast(to: DuckDB.Date.self)
        if let value = dateColumn[idx] {
            // DuckDB.Date has a description property
            return String(describing: value)
        }
        
        // If all else fails, return NULL
        return "NULL"
    }
    
    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func generateMetadataText(from rows: [MetadataRow]) -> String {
        var text = ""
        for row in rows {
            text += "\(row.key): \(row.value)\n"
        }
        return text
    }
}

// MARK: - NSTableView-backed SwiftUI wrapper for performant reuse
fileprivate struct ParquetTableViewRepresentable: NSViewRepresentable {
    let rows: [ParquetRow]
    let columns: [String]
    let columnTypes: [String]
    let columnWidth: CGFloat

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        let tableView = NSTableView()
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsMultipleSelection = false
        tableView.headerView = NSTableHeaderView()
        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        tableView.selectionHighlightStyle = .none
        tableView.focusRingType = .none

        // Create columns
        for (idx, name) in columns.enumerated() {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("col_\(idx)"))
            let typeSuffix = (idx < columnTypes.count && !columnTypes[idx].isEmpty) ? " (\(columnTypes[idx]))" : ""
            column.title = name + typeSuffix
            column.width = columnWidth
            column.minWidth = 60
            column.headerCell.alignment = .left
            tableView.addTableColumn(column)
        }

        scrollView.documentView = tableView
        context.coordinator.tableView = tableView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let tableView = nsView.documentView as? NSTableView else { return }

        // Update columns if schema changed
        if tableView.numberOfColumns != columns.count {
            while tableView.tableColumns.count > 0 { tableView.removeTableColumn(tableView.tableColumns[0]) }
            for (idx, name) in columns.enumerated() {
                let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("col_\(idx)"))
                let typeSuffix = (idx < columnTypes.count && !columnTypes[idx].isEmpty) ? " (\(columnTypes[idx]))" : ""
                column.title = name + typeSuffix
                column.width = columnWidth
                column.minWidth = 60
                column.headerCell.alignment = .left
                tableView.addTableColumn(column)
            }
        }

        context.coordinator.rows = rows
        context.coordinator.columns = columns
        context.coordinator.columnTypes = columnTypes
        tableView.reloadData()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(rows: rows, columns: columns, columnTypes: columnTypes)
    }

    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        var rows: [ParquetRow]
        var columns: [String]
        var columnTypes: [String]
        weak var tableView: NSTableView?

        init(rows: [ParquetRow], columns: [String], columnTypes: [String]) {
            self.rows = rows
            self.columns = columns
            self.columnTypes = columnTypes
        }

        func numberOfRows(in tableView: NSTableView) -> Int {
            rows.count
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            guard let tableColumn = tableColumn else { return nil }
            guard let columnIndex = tableView.tableColumns.firstIndex(of: tableColumn) else { return nil }
            let identifier = NSUserInterfaceItemIdentifier("cell_\(columnIndex)")

            if let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView {
                let value = (row < rows.count) ? rows[row][columnIndex] : ""
                cell.textField?.stringValue = value
                return cell
            } else {
                let cell = NSTableCellView()
                cell.identifier = identifier
                let value = (row < rows.count) ? rows[row][columnIndex] : ""
                let textField = NSTextField()
                textField.stringValue = value
                textField.font = NSFont.monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
                textField.lineBreakMode = NSLineBreakMode.byTruncatingTail
                textField.usesSingleLineMode = true
                textField.translatesAutoresizingMaskIntoConstraints = false
                textField.isEditable = false
                textField.isSelectable = true
                textField.isBordered = false
                textField.backgroundColor = NSColor.clear
                textField.allowsEditingTextAttributes = false
                textField.cell?.wraps = false
                textField.cell?.isScrollable = true
                cell.addSubview(textField)
                cell.textField = textField
                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 6),
                    textField.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor, constant: -6),
                    textField.topAnchor.constraint(equalTo: cell.topAnchor, constant: 4),
                    textField.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -4)
                ])
                return cell
            }
        }
    }
}

fileprivate struct SchemaTableViewRepresentable: NSViewRepresentable {
    let rows: [SchemaInfo]

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        let tableView = NSTableView()
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsMultipleSelection = false
        tableView.headerView = NSTableHeaderView()
        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        tableView.rowHeight = 22
        tableView.intercellSpacing = NSSize(width: 0, height: 0)
        tableView.selectionHighlightStyle = .none
        tableView.focusRingType = .none

        let nameCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        nameCol.title = "Column Name"
        nameCol.width = 500
        nameCol.headerCell.alignment = .left
        tableView.addTableColumn(nameCol)

        let typeCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("type"))
        typeCol.title = "Data Type"
        typeCol.width = 150
        typeCol.headerCell.alignment = .left
        tableView.addTableColumn(typeCol)

        let nullableCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("nullable"))
        nullableCol.title = "Nullable"
        nullableCol.width = 100
        nullableCol.headerCell.alignment = .left
        tableView.addTableColumn(nullableCol)

        scrollView.documentView = tableView
        context.coordinator.tableView = tableView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.rows = rows
        (nsView.documentView as? NSTableView)?.reloadData()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(rows: rows)
    }

    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        var rows: [SchemaInfo]
        weak var tableView: NSTableView?

        init(rows: [SchemaInfo]) { self.rows = rows }

        func numberOfRows(in tableView: NSTableView) -> Int { rows.count }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            guard let tableColumn = tableColumn else { return nil }
            let identifier = NSUserInterfaceItemIdentifier("schema_\(tableColumn.identifier.rawValue)")

            let text: String
            switch tableColumn.identifier.rawValue {
            case "name": text = rows[row].columnName
            case "type": text = rows[row].dataType
            case "nullable": text = rows[row].nullable
            default: text = ""
            }

            if let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView {
                cell.textField?.stringValue = text
                return cell
            } else {
                let cell = NSTableCellView()
                cell.identifier = identifier
                let textField = NSTextField()
                textField.stringValue = text
                textField.font = NSFont.monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
                textField.lineBreakMode = .byTruncatingTail
                textField.usesSingleLineMode = true
                textField.translatesAutoresizingMaskIntoConstraints = false
                textField.isEditable = false
                textField.isSelectable = true
                textField.isBordered = false
                textField.backgroundColor = NSColor.clear
                textField.allowsEditingTextAttributes = false
                textField.cell?.wraps = false
                textField.cell?.isScrollable = true
                textField.cell?.truncatesLastVisibleLine = true
                cell.addSubview(textField)
                cell.textField = textField
                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 6),
                    textField.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor, constant: -6),
                    textField.topAnchor.constraint(equalTo: cell.topAnchor, constant: 4),
                    textField.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -4)
                ])
                return cell
            }
        }
    }
}

fileprivate struct MetadataTableViewRepresentable: NSViewRepresentable {
    let rows: [MetadataRow]

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        let tableView = NSTableView()
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsMultipleSelection = false
        tableView.headerView = NSTableHeaderView()
        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        tableView.rowHeight = 22
        tableView.intercellSpacing = NSSize(width: 0, height: 0)
        tableView.selectionHighlightStyle = .none
        tableView.focusRingType = .none

        let keyCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("key"))
        keyCol.title = "Key"
        keyCol.width = 300
        keyCol.headerCell.alignment = .left
        tableView.addTableColumn(keyCol)

        let valueCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("value"))
        valueCol.title = "Value"
        valueCol.width = 600
        valueCol.headerCell.alignment = .left
        tableView.addTableColumn(valueCol)

        scrollView.documentView = tableView
        context.coordinator.tableView = tableView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.rows = rows
        (nsView.documentView as? NSTableView)?.reloadData()
    }

    func makeCoordinator() -> Coordinator { Coordinator(rows: rows) }

    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        var rows: [MetadataRow]
        weak var tableView: NSTableView?

        init(rows: [MetadataRow]) { self.rows = rows }

        func numberOfRows(in tableView: NSTableView) -> Int { rows.count }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            guard let tableColumn = tableColumn else { return nil }
            let identifier = NSUserInterfaceItemIdentifier("meta_\(tableColumn.identifier.rawValue)")

            let text: String
            switch tableColumn.identifier.rawValue {
            case "key": text = rows[row].key
            case "value": text = rows[row].value
            default: text = ""
            }

            if let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView {
                cell.textField?.stringValue = text
                return cell
            } else {
                let cell = NSTableCellView()
                cell.identifier = identifier
                let textField = NSTextField()
                textField.stringValue = text
                textField.font = NSFont.monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
                textField.lineBreakMode = .byTruncatingTail
                textField.usesSingleLineMode = true
                textField.translatesAutoresizingMaskIntoConstraints = false
                textField.isEditable = false
                textField.isSelectable = true
                textField.isBordered = false
                textField.backgroundColor = NSColor.clear
                textField.allowsEditingTextAttributes = false
                textField.cell?.wraps = false
                textField.cell?.isScrollable = true
                textField.cell?.truncatesLastVisibleLine = true
                cell.addSubview(textField)
                cell.textField = textField
                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 6),
                    textField.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor, constant: -6),
                    textField.topAnchor.constraint(equalTo: cell.topAnchor, constant: 4),
                    textField.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -4)
                ])
                return cell
            }
        }
    }
}
// Safe array access extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ParquetViewerView()
        .frame(width: 800, height: 600)
}