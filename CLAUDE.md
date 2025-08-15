# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
DevHelper is a native macOS application built with SwiftUI that provides essential developer utilities in a single, unified interface. The app contains 14 fully-functional tools commonly used by developers, with search functionality and modern UI design. Version 1.9.0 released.

## Tools Implemented

### 1. Timestamp Converter (`TimestampConverterView.swift`)
- **Status**: ✅ Complete
- **Features**: Auto-detection of timestamp formats (seconds/milliseconds/microseconds/nanoseconds), bidirectional conversion, timezone support (Local/UTC), current timestamp generation
- **UI**: Two-column layout with real-time conversion, **selectable text results**
- **Recent Updates**: Fixed result selectability issue - users can now select and copy results

### 2. Unit Converter (`UnitConverterView.swift`)
- **Status**: ✅ Complete
- **Features**: 7 categories (Data, Time, Length, Weight, Temperature, Area, Volume), real-time conversion, special temperature handling
- **UI**: Category picker with from/to unit selection, Data category in first position
- **Recent Updates**: Added Time category with comprehensive time unit conversions (nanoseconds to years)

### 3. JSON Formatter (`JSONFormatterView.swift`)
- **Status**: ✅ Complete
- **Features**: Format (pretty print), minify, validate, escape/unescape for strings, JSON diff/compare mode, syntax error highlighting
- **UI**: Two-panel layout with mode selection, three-panel layout for diff mode
- **Recent Updates**: Added unescape functionality for escaped JSON strings, diff mode for JSON comparison with side-by-side view

### 4. Base64 Encode/Decode (`Base64View.swift`)
- **Status**: ✅ Complete
- **Features**: Text encoding/decoding, URL-safe Base64 variant, swap functionality
- **UI**: Tabbed interface with encode/decode modes
- **Recent Updates**: Renamed from "Base64 Encoder/Decoder" to "Base64 Encode/Decode"

### 5. Regex Test (`RegexTestView.swift`)
- **Status**: ✅ Complete
- **Features**: Pattern matching, capture groups, replacement, common patterns library, regex flags
- **UI**: Pattern input with results display and common pattern buttons

### 6. UUID Generator (`UUIDGeneratorView.swift`)
- **Status**: ✅ Complete
- **Features**: Multiple UUID versions (v1, v4, v5, v7), multiple formats, bulk generation (1-100), UUID validation, common pattern examples, **UUID v7 timestamp extraction**
- **UI**: Generation controls with scrollable results list
- **Recent Updates**: Added UUID v7 support with timestamp-ordered generation and automatic timestamp extraction from v7 UUIDs

### 7. URL Tools (`URLToolsView.swift`)
- **Status**: ✅ Complete
- **Features**: URL encoding/decoding, comprehensive URL parsing, query parameter breakdown
- **UI**: Three-tab interface (Encoder/Decoder/Parser)

### 8. IP Query (`IPQueryView.swift`)
- **Status**: ✅ Complete
- **Features**: Dual IP detection (international vs China networks), current IP discovery, IP geolocation query, comprehensive location information
- **UI**: Two-column layout with smart dual IP display, sample IP buttons, detailed location breakdown
- **Recent Updates**: Added User-Agent headers for bot detection avoidance, uses Baidu API for reliable China IP detection

### 9. HTTP Request (`HTTPRequestView.swift`)
- **Status**: ✅ Complete
- **Features**: Full HTTP client with all methods (GET/POST/PUT/DELETE/etc), headers management, Basic/Bearer authentication, request body support, TLS verification skip, response timing, SSE streaming support, binary download, JSON tree view, request history
- **UI**: Split layout with request configuration (headers/auth/body tabs) and response display (body/headers/tree), real-time timer, status code indicators, copy/save functionality
- **Recent Updates**: Added JSON tree view for structured response exploration, improved request history display

### 10. QR Code (`QRCodeView.swift`)
- **Status**: ✅ Complete
- **Features**: QR code generation with multiple sizes (128x128 to 1024x1024+ custom), error correction levels, QR code scanning from files/clipboard, URL detection and opening
- **UI**: Tabbed interface (Generate/Scan), two-column layouts with visual flow indicators, size-aware generation, image preview for scanning
- **Generation**: Real-time QR code creation, copy to clipboard, save to file with proper entitlements, dynamic sizing with pixel indicators
- **Scanning**: File selection, clipboard paste, image preview with scan results, automatic URL recognition

### 11. SQL Formatter (`SQLFormatterView.swift`)
- **Status**: ✅ Complete
- **Features**: SQL formatting (pretty print), minification, basic syntax validation, support for common SQL statements
- **UI**: Two-column layout with mode selection (Format/Minify), real-time processing
- **Recent Updates**: Added comprehensive SQL formatting with proper indentation and keyword highlighting

### 12. HTML Formatter (`HTMLFormatterView.swift`)
- **Status**: ✅ Complete
- **Features**: HTML formatting (pretty print), minification, basic syntax validation, proper tag indentation
- **UI**: Two-column layout with mode selection (Format/Minify), real-time processing
- **Recent Updates**: Added HTML formatting with proper tag structure and indentation

### 13. JWT Encoder/Decoder (`JWTView.swift`)
- **Status**: ✅ Complete
- **Features**: JWT token decoding with header/payload extraction, JWT encoding with HMAC algorithms (HS256/HS384/HS512), signature verification, custom claims support
- **UI**: Tabbed interface (Encode/Decode), comprehensive JWT token analysis, algorithm selection
- **Recent Updates**: Added JWT processing with multiple HMAC algorithms and signature validation
- **Security**: Uses CryptoKit for secure HMAC operations

### 14. Parquet Viewer (`ParquetViewerView.swift`)
- **Status**: ✅ Complete - Full DuckDB integration
- **Features**: Complete Parquet file reading using DuckDB Swift library, schema extraction, data preview, metadata display
- **UI**: Tabbed interface (Data/Schema/Metadata), native SwiftUI table with fixed column widths, schema table with column_name/data_type/nullable columns
- **Data Display**: Scrollable table with consistent column alignment, supports CSV and JSON export
- **Schema Display**: Table view with column information, supports CSV and JSON export
- **Metadata**: Two sections - File metadata (via `parquet_file_metadata()`) and Key-value metadata (via `parquet_kv_metadata()`)
- **Dependencies**: DuckDB Swift package integrated via SPM

## Architecture

### Project Structure
```
DevHelper/
├── DevHelper.xcodeproj/            # Xcode project configuration
│   └── project.xcworkspace/
│       └── xcshareddata/swiftpm/   # SPM package dependencies
├── DevHelper/
│   ├── DevHelperApp.swift          # Main app entry point
│   ├── ContentView.swift           # Navigation split view
│   ├── Models/
│   │   └── ToolType.swift          # Tool definitions
│   ├── Views/                      # All 14 tool implementations
│   │   ├── TimestampConverterView.swift
│   │   ├── UnitConverterView.swift
│   │   ├── JSONFormatterView.swift
│   │   ├── SQLFormatterView.swift
│   │   ├── HTMLFormatterView.swift
│   │   ├── Base64View.swift
│   │   ├── JWTView.swift
│   │   ├── URLToolsView.swift
│   │   ├── RegexTestView.swift
│   │   ├── UUIDGeneratorView.swift
│   │   ├── HTTPRequestView.swift
│   │   ├── IPQueryView.swift
│   │   ├── QRCodeView.swift
│   │   └── ParquetViewerView.swift
│   ├── Components/                 # Shared UI components
│   │   ├── CodeEditor.swift        # CodeMirror integration
│   │   └── TextEditor.swift        # Custom text editor
│   └── DevHelper.entitlements      # App sandbox permissions
├── DESIGN.md                       # Comprehensive design document
├── CLAUDE.md                       # This file - Claude Code guidance
└── README.md                       # User-facing documentation
```

### Technical Stack
- **Platform**: macOS 14.0+
- **Framework**: SwiftUI
- **Language**: Swift 5.0
- **Architecture**: MVVM pattern with @State and @Published
- **Navigation**: NavigationSplitView with sidebar

## Key Implementation Details

### Navigation Pattern
- All tools are defined in `ToolType` enum with titles and SF Symbols icons
- `ContentView` uses NavigationSplitView with sidebar selection and **search functionality**
- Each tool is a separate SwiftUI view with consistent styling
- **Search bar** in sidebar allows filtering tools by title

### Common UI Patterns
- **Two-column layouts**: Input/output sections with arrow indicators
- **Tabbed interfaces**: Multiple related functions in single tool
- **Copy functionality**: Ubiquitous copy-to-clipboard buttons
- **Sample data**: Quick testing with provided examples
- **Real-time processing**: Instant results as user types

### Shared Components
- Consistent button styling (`.bordered`, `.borderedProminent`)
- Monospace fonts for technical data
- Color coding (green for success, red for errors)
- Rounded border text field styling

## Build Configuration

### Target Settings
- **Bundle ID**: com.devhelper.DevHelper
- **Minimum macOS**: 14.0
- **Version**: 1.8.3 (Build 1)
- **Entitlements**: App Sandbox enabled, Hardened Runtime enabled
- **Swift Version**: 5.0

### Dependencies

#### Framework Dependencies
- **SwiftUI**: UI framework
- **Foundation**: Core utilities and networking
- **AppKit**: Clipboard access (NSPasteboard), file dialogs
- **CoreImage**: QR code generation with CIFilter.qrCodeGenerator()
- **Vision**: QR code scanning with VNDetectBarcodesRequest
- **UniformTypeIdentifiers**: Modern file type handling for save dialogs
- **CryptoKit**: JWT HMAC signature generation and verification

#### Swift Package Manager Dependencies
- **DuckDB**: Swift package for Parquet file reading (branch: v1.4.0-dev1354)
- **Arrow**: Apache Arrow Swift implementation (v21.0.0)
- **CodeMirror-SwiftUI**: Code editor integration (github.com/hengfeiyang/CodeMirror-SwiftUI)

## Recent Updates (Version 1.9+)

### Latest Features (Version 1.9+)
- **SQL Formatter Tool**: Complete SQL formatting and minification functionality
  - **SQL Formatting**: Pretty print SQL with proper indentation and keyword highlighting
  - **Minification**: Compress SQL by removing unnecessary whitespace
  - **Syntax Validation**: Basic SQL syntax checking with error reporting
  - **Real-time Processing**: Instant formatting as user types or pastes content
- **HTML Formatter Tool**: Comprehensive HTML formatting and minification
  - **HTML Formatting**: Pretty print HTML with proper tag indentation and structure
  - **Minification**: Compress HTML by removing unnecessary whitespace and formatting
  - **Syntax Validation**: Basic HTML structure validation
  - **Real-time Processing**: Instant formatting with live preview
- **JWT Encoder/Decoder Tool**: Full JWT token processing capabilities
  - **JWT Decoding**: Extract and display header, payload, and signature information
  - **JWT Encoding**: Create JWT tokens with custom claims and HMAC algorithms
  - **Algorithm Support**: HS256, HS384, HS512, and none algorithms
  - **Signature Verification**: Validate JWT signatures using provided secret keys
  - **Security Integration**: Uses CryptoKit for secure HMAC operations

### Previous Features (Version 1.8)
- **Parquet Viewer Tool**: Complete Parquet file reading with DuckDB integration
  - **Full Data Reading**: Uses DuckDB Swift library to read actual Parquet data
  - **Schema Table View**: Displays columns with name, data type, and nullable status
  - **Data Preview**: Native SwiftUI table with proper column alignment (150px fixed width)
  - **Export Options**: Both CSV and JSON export for data and schema
  - **Metadata Display**: File metadata via `parquet_file_metadata()` and key-value metadata via `parquet_kv_metadata()`
- **Time Unit Converter**: Added Time category with conversions from nanoseconds to years

### Previous Features (Version 1.7)
- **QR Code Tool**: Comprehensive QR code generation and scanning functionality
  - **Generation**: Multiple sizes (Small 128x128, Medium 256x256, Large 512x512, Extra Large 1024x1024, Custom size)
  - **Error Correction**: Configurable levels (L/M/Q/H) for different use cases
  - **File Operations**: Copy to clipboard, save to PNG with proper entitlements (read-write access)
  - **Scanning**: File selection, clipboard paste, image preview with scan results
  - **UI Enhancement**: Two-column layout with visual flow indicators, buttons positioned below QR code

### Previous Features (Version 1.6)
- **UUID v7 Support**: Added timestamp-ordered UUID generation to UUID Generator
  - **UUID v7 Generation**: Creates timestamp-ordered UUIDs with embedded millisecond timestamps
  - **Timestamp Extraction**: Automatically extracts and displays embedded timestamps from UUID v7
  - Lexicographically sortable UUIDs for time-based ordering
- **JSON Unescape**: Enhanced JSON Formatter with bidirectional string processing
  - Handles all standard JSON escape sequences and Unicode sequences

### Previous Updates (Version 1.5)
- **JSON Differ**: Added comprehensive JSON comparison functionality to JSON Formatter
  - Side-by-side comparison view with three panels (JSON 1, JSON 2, Differences)
  - Real-time diff highlighting and detailed change detection
  - Integrated into existing JSON Formatter with seamless mode switching
- **JSON Tree View**: Enhanced HTTP Request tool with structured JSON response exploration
  - Interactive tree view for JSON responses with expand/collapse functionality
  - Hierarchical display of JSON objects and arrays
  - Improved readability for complex API responses

## Previous Updates (Version 1.4)

### Major New Feature
- **HTTP Request Tool**: Professional-grade HTTP client with comprehensive functionality
  - All HTTP methods (GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS)
  - Advanced headers management with common header shortcuts
  - Authentication support (Basic Auth, Bearer Token)
  - Request body support for JSON, XML, form data
  - TLS verification bypass option for development
  - Real-time request timer and response time measurement
  - Server-Sent Events (SSE) streaming support with real-time updates
  - Response viewing modes (Preview/Raw) with automatic JSON formatting
  - Binary data download functionality with file save dialog
  - Comprehensive error handling and status code visualization
  - Copy/save functionality for requests and responses

### Previous Updates (Version 1.3)
- **IP Query Tool**: Complete IP address discovery and geolocation
- **Dual IP detection**: International vs China network awareness
- **User-Agent headers**: Bot detection avoidance for API calls

## Common Development Tasks

### Adding a New Tool
1. Add case to `ToolType` enum in `Models/ToolType.swift`
2. Create new SwiftUI view file in `Views/`
3. Add switch case in `ContentView.swift`
4. Follow established UI patterns and styling

### Modifying Existing Tools
- Each tool is self-contained in its own file
- Use established state management patterns
- Maintain consistent UI styling and copy functionality

### Testing
- Each tool has sample data/examples for quick testing
- SwiftUI Previews available for all views
- Manual testing covers error cases and edge conditions

## Key Architecture Notes

### Tool Implementation Pattern
Each tool follows a consistent pattern:
1. **Enum definition** in `ToolType.swift` with title and SF Symbol icon
2. **SwiftUI View** in `Views/` directory with @State management
3. **Switch case** in `ContentView.swift` for navigation
4. **Common UI patterns**: Two-column layouts, copy buttons, sample data

### State Management
- Uses `@State` for local view state (input text, results, UI state)
- No complex state management - each tool is self-contained
- Real-time updates via `onChange` modifiers
- `@StateObject` for persistent data across view updates

### File Operations & Entitlements
- **Save operations** require `com.apple.security.files.user-selected.read-write` entitlement
- **Network requests** require `com.apple.security.network.client` entitlement  
- **Clipboard access** uses `NSPasteboard` (macOS) not `UIPasteboard` (iOS)
- **File dialogs**: Use `NSSavePanel` and `NSOpenPanel` for file operations

### Common Development Issues & Solutions
- **Xcode project updates**: When adding new Swift files, must manually update `.pbxproj` file or use Xcode GUI
- **macOS vs iOS APIs**: Avoid iOS-specific modifiers like `.keyboardType(.decimalPad)` - use macOS equivalents
- **File type handling**: Use `UniformTypeIdentifiers` for modern file operations
- **Image operations**: Use `CoreImage` for generation, `Vision` for recognition
- **SPM dependencies**: May need to resolve packages after pulling changes (`xcodebuild -resolvePackageDependencies`)
- **Code signing**: Ensure Development Team is set in project settings for automatic signing

## Future Enhancements

### Potential Features
- **Preferences window**: User customization options
- **Themes**: Light/dark mode preferences
- **Keyboard shortcuts**: Quick access to common functions
- **Export/Import**: Save tool configurations
- **IP Query history**: Persistent storage for IP queries
- **Additional geolocation providers**: More IP data sources

### Technical Improvements
- **Performance**: Optimize for large text processing
- **Accessibility**: Enhanced VoiceOver support
- **Localization**: Multi-language support

## Development Commands

### Build & Run
```bash
# Open project in Xcode (recommended)
open DevHelper.xcodeproj

# Build for Debug configuration
xcodebuild -project DevHelper.xcodeproj -scheme DevHelper -configuration Debug build

# Build for Release configuration  
xcodebuild -project DevHelper.xcodeproj -scheme DevHelper -configuration Release build

# Clean build artifacts
xcodebuild -project DevHelper.xcodeproj -scheme DevHelper clean

# Archive for distribution
xcodebuild -project DevHelper.xcodeproj -scheme DevHelper -configuration Release archive

# Build and launch app (using Claude Code MCP tools)
# 1. Build: mcp__XcodeBuildMCP__build_mac_proj
# 2. Get app path: mcp__XcodeBuildMCP__get_mac_app_path_proj  
# 3. Launch: mcp__XcodeBuildMCP__launch_mac_app
```

### Swift Package Management
```bash
# Resolve package dependencies
xcodebuild -resolvePackageDependencies -project DevHelper.xcodeproj

# Update package dependencies
xcodebuild -project DevHelper.xcodeproj -scheme DevHelper -resolvePackageDependencies
```

### Testing & Validation
```bash
# Run tests (if available)
xcodebuild test -project DevHelper.xcodeproj -scheme DevHelper -destination 'platform=macOS'

# Analyze code for potential issues
xcodebuild analyze -project DevHelper.xcodeproj -scheme DevHelper

# Check for Swift lint issues (requires swiftlint)
swiftlint lint --path DevHelper/
```

### Xcode Project Management
- **Adding new tools**: Must add both the Swift file AND update the Xcode project file (.pbxproj)
- **Entitlements**: Located in `DevHelper.entitlements` - includes sandbox, network, and file read-write permissions
- **Target settings**: Bundle ID `com.devhelper.DevHelper`, minimum macOS 14.0

### Key Development Notes
- **External dependencies**: DuckDB, Arrow, CodeMirror-SwiftUI via Swift Package Manager
- **Package manager**: Swift Package Manager (SPM) for all external dependencies
- **App Sandbox enabled**: Network client access granted for IP Query and HTTP Request tools, file read-write for save operations
- **Target**: macOS 14.0+, requires Xcode 15.4+
- **Code signing**: Automatic with Development Team VS7S7V6J2F
- **Hardened Runtime**: Enabled with timestamp and runtime options

### Project Management
- **Design Document**: `DESIGN.md` contains comprehensive architecture details
- **This File**: `CLAUDE.md` provides context for future Claude sessions
- **README**: `README.md` contains user-facing project information

## Success Metrics
- ✅ All 14 essential tools fully implemented
- ✅ Consistent UI/UX across all tools
- ✅ Real-time processing and feedback
- ✅ Professional macOS native experience
- ✅ Comprehensive error handling
- ✅ Copy-to-clipboard functionality throughout
- ✅ Search functionality for quick tool access
- ✅ Selectable text in results areas
- ✅ File save/load operations with proper entitlements
- ✅ Streamlined feature set focused on core developer needs
- ✅ Security-focused implementations (JWT with CryptoKit)
- ✅ Code formatting capabilities (SQL, HTML, JSON)

---

**Last Updated**: Version 1.9.0 with new formatter tools.
**Latest Additions**: 
- SQL Formatter tool with formatting, minification, and syntax validation
- HTML Formatter tool with pretty printing and minification capabilities
- JWT Encoder/Decoder tool with HMAC algorithms and signature verification
- Enhanced security with CryptoKit integration for JWT processing
- Full Parquet file reading with DuckDB integration, schema/data/metadata display with export options
- CodeMirror integration for enhanced code editing capabilities
**Architecture**: SwiftUI with DuckDB, Arrow, CodeMirror-SwiftUI, and CryptoKit frameworks.