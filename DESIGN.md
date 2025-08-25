# DevHelper - Design Document

## Overview
DevHelper is a native macOS application built with SwiftUI that provides essential developer utilities in a single, easy-to-use interface. The app follows Apple's Human Interface Guidelines and provides a consistent, professional experience across all tools.

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
│   │   ├── CodeEditor.swift        # CodeMirror integration & diff editor
│   │   └── TextEditor.swift        # Custom text editor
│   ├── Assets.xcassets/            # App icons and assets
│   ├── Preview Content/            # SwiftUI preview assets
│   └── DevHelper.entitlements      # App sandbox permissions
├── DESIGN.md                       # This design document
├── CLAUDE.md                       # Claude Code guidance
└── README.md                       # User-facing documentation
```

### Technical Stack
- **Platform**: macOS 14.0+
- **Framework**: SwiftUI
- **Language**: Swift 5.0
- **Architecture Pattern**: MVVM (Model-View-ViewModel)
- **Data Binding**: Combine framework with @Published and @State

## App Architecture

### Main Navigation
- **NavigationSplitView**: Primary navigation structure
- **Sidebar**: Tool selection with icons and titles, **search functionality**
- **Detail View**: Selected tool interface
- **Window Configuration**: Resizable with minimum size constraints
- **Search Bar**: Integrated search to filter tools by name

### Tool Integration Pattern
Each tool follows a consistent pattern:
1. **Enum Definition**: Added to `ToolType` enum
2. **Icon Assignment**: SF Symbols icon
3. **View Implementation**: SwiftUI view with consistent styling
4. **Navigation Integration**: Switch case in `ContentView`

## Tool Specifications

### 1. Timestamp Converter
**File**: `TimestampConverterView.swift`

**Features**:
- Auto-detection of timestamp formats (10/13/16/19 digits)
- Bidirectional conversion (timestamp ↔ human-readable)
- Timezone support (Local/UTC)
- Current timestamp generation
- Real-time conversion

**UI Components**:
- Two-column layout (timestamp input/output)
- Toggle for timezone selection
- Current timestamp button
- Copy functionality

**Implementation Details**:
- Uses `Date` and `DateFormatter` for conversions
- Automatic format detection based on digit count
- TimeInterval calculations for different precisions

### 2. Unit Converter
**File**: `UnitConverterView.swift`

**Features**:
- 7 unit categories: Data, Time, Length, Weight, Temperature, Area, Volume
- Real-time bidirectional conversion
- Swap units functionality
- Special temperature conversion logic
- Comprehensive time unit support (nanoseconds to years)

**UI Components**:
- Segmented picker for categories
- Dropdown menus for unit selection
- Numeric input with real-time updates
- Swap button for quick unit exchange

**Implementation Details**:
- `UnitCategory` enum with associated units
- `UnitData` struct for conversion multipliers
- Special handling for temperature conversions (C/F/K)
- Base unit conversion pattern
- Time conversions from nanoseconds to years

### 3. JSON Formatter
**File**: `JSONFormatterView.swift`

**Features**:
- Format (pretty print)
- Minify (remove whitespace)
- Validate with detailed feedback
- Escape/Unescape for string embedding
- JSON diff/compare mode with visual CodeMirror diff editor
- Syntax error highlighting
- Real-time syntax highlighting for JSON

**UI Components**:
- Segmented picker for modes (Format/Minify/Validate/Escape/Diff)
- Two-panel layout (input/output) for most modes
- Visual diff editor for diff mode with side-by-side JSON comparison
- Validation status indicator
- Sample JSON button
- CodeMirror integration for enhanced editing experience

**Implementation Details**:
- `JSONSerialization` for parsing and formatting
- Error handling with descriptive messages
- Real-time processing with input validation
- Character count tracking
- CodeMirror-SwiftUI integration for diff visualization
- `CodeDiffEditor` component for visual diff comparison

### 4. Base64 Encode/Decode
**File**: `Base64View.swift`

**Features**:
- Text encoding/decoding
- URL-safe Base64 variant
- Real-time conversion
- Swap functionality between modes
- Sample data for testing

**UI Components**:
- Tab-based interface (Encode/Decode)
- URL-safe toggle
- Two-panel layout per mode
- Sample and swap buttons

**Implementation Details**:
- `Data.base64EncodedString()` for encoding
- `Data(base64Encoded:)` for decoding
- URL-safe character substitution
- UTF-8 encoding/decoding

### 5. Regex Test
**File**: `RegexTestView.swift`

**Features**:
- Pattern testing with match highlighting
- Capture group display
- Flag support (case-insensitive, multiline, dotall)
- Match replacement functionality
- Common pattern library with descriptions

**UI Components**:
- Pattern input with flag toggles
- Test string area with match highlighting
- Results display with capture groups
- Common patterns button library
- Replace mode interface

**Implementation Details**:
- `NSRegularExpression` for pattern matching
- Real-time highlighting of matches
- Flag handling for regex options
- String replacement with capture group support

### 6. UUID Generator
**File**: `UUIDGeneratorView.swift`

**Features**:
- Multiple UUID versions (V1, V4, V5, V7)
- Bulk generation (1-100 UUIDs)
- Multiple format options
- UUID validation
- Common pattern examples
- UUID v7 timestamp extraction

**UI Components**:
- Version picker
- Format dropdown
- Bulk count stepper
- Scrollable UUID list with individual copy buttons
- Validation section with examples

**Implementation Details**:
- `UUID()` for generation
- Format transformations (hyphens, case, braces)
- Validation using `UUID(uuidString:)`
- Version detection from UUID structure
- UUID v7 timestamp-ordered generation
- Automatic timestamp extraction from v7 UUIDs

### 7. URL Tools
**File**: `URLToolsView.swift`

**Features**:
- URL encoding/decoding
- Complete URL parsing
- Query parameter breakdown
- URL reconstruction
- Component extraction

**UI Components**:
- Three-tab interface (Encoder/Decoder/Parser)
- Component breakdown tables
- Query parameter list
- URL reconstruction display

**Implementation Details**:
- `String.addingPercentEncoding()` for encoding
- `String.removingPercentEncoding()` for decoding
- `URLComponents` for parsing
- Query parameter array management

### 8. IP Query
**File**: `IPQueryView.swift`

**Features**:
- Dual IP detection (international vs China networks)
- Current IP address discovery
- IP geolocation query for any IP address
- Smart dual IP display (only when different)
- Comprehensive location information

**UI Components**:
- Two-column layout (My IP / Query IP)
- Dual IP display with clear labeling
- Sample IP buttons for quick testing
- Copy functionality for all IP addresses
- Detailed location breakdown

**Implementation Details**:
- Concurrent API calls using `DispatchGroup`
- ipinfo.io for international IP detection
- Baidu API for China network detection
- User-Agent headers to avoid bot detection
- Comprehensive error handling and validation

### 9. HTTP Request
**File**: `HTTPRequestView.swift`

**Features**:
- Complete HTTP client with all standard methods (GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS)
- Advanced headers management with add/remove functionality
- Common header shortcuts (Content-Type, Accept, User-Agent)
- Authentication support (None, Basic Auth, Bearer Token)
- Request body support for JSON, XML, form data, and raw text
- TLS verification bypass option for development/testing
- Configurable timeout settings
- Real-time request timer with elapsed time display
- Server-Sent Events (SSE) streaming support with live updates
- Response time measurement and display
- Binary data download with file save dialog
- JSON tree view for structured response exploration
- Request history with timeline display

**UI Components**:
- Split layout with request configuration and response display
- Tabbed request interface (Headers, Auth, Body)
- HTTP method dropdown and URL input field
- Real-time timer and cancel functionality
- Response tabs (Body, Headers) with raw/preview/tree modes
- Status code color indicators (green/orange/red)
- Copy and save functionality throughout
- Sample data buttons for quick testing

**Implementation Details**:
- `URLSession` with custom configuration for requests
- `URLSessionDelegate` for TLS bypass functionality
- Real-time timer using `Timer.scheduledTimer` for elapsed time
- Streaming response handling for SSE content types
- JSON formatting with `JSONSerialization` for preview mode
- Interactive JSON tree view with expand/collapse functionality
- File save functionality using `NSSavePanel`
- Comprehensive error handling for network issues
- Automatic content type detection for response formatting
- Thread-safe UI updates using `DispatchQueue.main.async`

### 10. QR Code
**File**: `QRCodeView.swift`

**Features**:
- QR code generation with multiple size options (Small 128x128, Medium 256x256, Large 512x512, Extra Large 1024x1024, Custom size)
- Configurable error correction levels (L/M/Q/H) for different reliability needs
- Real-time QR code generation as user types
- Copy generated QR code to clipboard functionality
- Save QR code as PNG file with proper filename formatting
- QR code scanning from image files or clipboard
- Image preview for scanning operations
- Automatic URL detection and opening from scan results
- Sample data buttons for quick testing (URL, text, WiFi)

**UI Components**:
- Tabbed interface (Generate/Scan) with segmented picker
- Two-column layouts with visual flow indicators (arrow icons)
- Size picker dropdown with descriptive labels
- Custom size text field for pixel-perfect dimensions
- Dynamic QR code preview with size indicators
- Action buttons positioned below QR code image
- Image preview section for scanning operations
- Scrollable scan result area with copy/open functionality

**Implementation Details**:
- `CoreImage.CIFilter.qrCodeGenerator()` for QR code generation
- `Vision.VNDetectBarcodesRequest` for QR code scanning
- Dynamic scaling calculation based on selected size
- `NSOpenPanel` for file selection with image content types
- `NSSavePanel` with `UniformTypeIdentifiers` for PNG saving
- `NSPasteboard` integration for clipboard operations
- Proper entitlements (`com.apple.security.files.user-selected.read-write`) for file operations
- Real-time UI updates using `onChange` modifiers
- Error handling for image processing and file operations

### 11. SQL Formatter
**File**: `SQLFormatterView.swift`

**Features**:
- SQL formatting with proper indentation and keyword highlighting
- SQL minification by removing unnecessary whitespace
- Basic syntax validation with error reporting
- Real-time processing as user types
- Support for common SQL statements (SELECT, INSERT, UPDATE, DELETE, etc.)
- Copy functionality for formatted results

**UI Components**:
- Segmented picker for mode selection (Format/Minify)
- Two-column layout (input/output) with arrow indicator
- Sample SQL buttons for quick testing
- Validation status indicator with error messages
- Character count display for input/output

**Implementation Details**:
- Custom SQL formatter with keyword recognition
- Indentation logic for nested queries and clauses
- Basic syntax validation using string parsing
- Real-time processing with input validation
- Error handling with descriptive feedback

### 12. HTML Formatter
**File**: `HTMLFormatterView.swift`

**Features**:
- HTML formatting with proper tag indentation and structure
- HTML minification by removing unnecessary whitespace
- Basic syntax validation with error reporting
- Real-time processing as user types
- Support for all standard HTML elements
- Copy functionality for formatted results

**UI Components**:
- Segmented picker for mode selection (Format/Minify)
- Two-column layout (input/output) with arrow indicator
- Sample HTML buttons for quick testing
- Validation status indicator with error messages
- Character count display for input/output

**Implementation Details**:
- Custom HTML formatter with tag recognition
- Proper indentation logic for nested elements
- Basic syntax validation using XML/HTML parsing principles
- Real-time processing with input validation
- Error handling with descriptive feedback

### 13. JWT Encoder/Decoder
**File**: `JWTView.swift`

**Features**:
- JWT token decoding with header and payload extraction
- JWT token encoding with custom claims support
- HMAC signature verification and generation
- Algorithm support (HS256, HS384, HS512, none)
- Base64URL encoding/decoding for JWT components
- Real-time processing and validation
- Sample JWT tokens for testing

**UI Components**:
- Tabbed interface (Encode/Decode)
- JWT token input/output areas
- Header and payload display sections
- Algorithm picker for encoding
- Secret key input for HMAC algorithms
- Signature verification status indicator
- Copy functionality throughout

**Implementation Details**:
- Uses `CryptoKit` for HMAC signature generation
- Base64URL encoding/decoding functions
- JSON parsing for header and payload
- Real-time JWT validation and parsing
- Support for common JWT claims (iss, sub, aud, exp, etc.)
- Error handling for malformed tokens
- Secure key handling for signature operations

### 14. Parquet Viewer
**File**: `ParquetViewerView.swift`

**Features**:
- Complete Parquet file reading using DuckDB Swift library
- Support arrow file reading using arrow Swift library
- Schema extraction with column details (name, type, nullable)
- Data preview with native SwiftUI table
- File metadata display via `parquet_file_metadata()`
- Key-value metadata display via `parquet_kv_metadata()`
- CSV and JSON export options for data and schema

**UI Components**:
- Tabbed interface (Data/Schema/Metadata)
- File selection button and filename display
- Native SwiftUI table with fixed column widths (150px)
- Schema table with column_name, data_type, nullable columns
- Two-section metadata display
- Export dropdown menu for each tab

**Implementation Details**:
- DuckDB Swift package integration via SPM
- Arrow Swfit package integration via SPM
- SQL queries for data extraction
- `DESCRIBE SELECT` for schema information
- `parquet_file_metadata()` and `parquet_kv_metadata()` functions
- Fixed-width table columns for consistent display
- CSV formatting with proper escaping
- JSON export with structured data

## UI Design Principles

### Color Scheme
- **Primary**: System accent color
- **Secondary**: Gray tones for subtle elements
- **Success**: Green for valid states
- **Error**: Red for invalid states
- **Background**: System background colors

### Typography
- **Headers**: `.largeTitle`, `.headline` weights
- **Body**: `.body` with monospace for code/data
- **Captions**: `.caption` for metadata
- **Monospace**: Used for all technical data display

### Layout Patterns
- **Two-Column**: Input/output sections with arrow indicator
- **Tabbed**: Multiple related tools in single view
- **Sidebar**: Main navigation with SF Symbols
- **Split View**: Resizable panels for complex tools

### Interactive Elements
- **Buttons**: Consistent styling with `.bordered` and `.borderedProminent`
- **Text Fields**: Rounded border style
- **Pickers**: Segmented for modes, menu for options
- **Copy Buttons**: Ubiquitous copy-to-clipboard functionality

## Data Models

### ToolType Enum
```swift
enum ToolType: String, CaseIterable, Identifiable {
    case timestampConverter, unitConverter, jsonFormatter, 
         sqlFormatter, htmlFormatter, base64, jwt, 
         urlTools, regexTest, uuidGenerator, httpRequest, 
         ipQuery, qrCode, parquetViewer
    
    var title: String { /* Display names */ }
    var iconName: String { /* SF Symbols */ }
}
```

### Supporting Models
- `UnitCategory` and `UnitData` for unit conversions
- `JSONMode` for JSON operations
- `SQLMode` for SQL formatting operations
- `HTMLMode` for HTML formatting operations
- `Base64Tab` for encoding modes
- `JWTTab` and `JWTAlgorithm` for JWT operations
- `UUIDVersion` and `UUIDFormat` for UUID options
- `URLTab` for URL tool modes
- `IPLocationInfo` and `BaiduIPInfo` for IP geolocation data
- `HTTPMethod` and `AuthType` for HTTP request configuration
- `HTTPHeader` and `HTTPResponseData` for request/response handling
- `RequestTab`, `ResponseTab`, and `ResponseViewMode` for HTTP UI state
- `QRCodeTab`, `QRCodeSize`, and `QRCodeCorrectionLevel` for QR code options

## Build Configuration

### Target Settings
- **Minimum macOS**: 14.0
- **Bundle Identifier**: com.devhelper.DevHelper
- **Version**: 1.9.0 (Build 1)
- **Swift Version**: 5.0
- **App Sandbox**: Enabled
- **Hardened Runtime**: Enabled
- **Network Access**: Enabled (for HTTP and IP Query tools)
- **File Access**: User-selected read-write

### Dependencies

#### Framework Dependencies
- **SwiftUI**: UI framework
- **Combine**: Reactive programming
- **Foundation**: Core utilities and networking
- **AppKit**: macOS integration (clipboard access, file dialogs)
- **CoreImage**: QR code generation with CIFilter
- **Vision**: QR code scanning with VNDetectBarcodesRequest
- **UniformTypeIdentifiers**: Modern file type handling
- **CryptoKit**: JWT HMAC signature generation and verification

#### Swift Package Manager Dependencies
- **DuckDB**: Swift package for Parquet file reading (branch: v1.4.0-dev1354)
- **Arrow**: Apache Arrow Swift implementation (v21.0.0)
- **CodeMirror-SwiftUI**: Code editor integration (github.com/hengfeiyang/CodeMirror-SwiftUI)
- **FlatBuffers**: Google FlatBuffers (v25.2.10) - Arrow dependency
- **Swift-Atomics**: Apple Swift Atomics (v1.3.0) - Arrow dependency

## Testing Strategy

### Manual Testing
- Each tool has sample data for quick testing
- Real-time feedback for immediate validation
- Error cases handled gracefully

### UI Testing
- SwiftUI Previews for rapid development
- Different window sizes and orientations
- Accessibility compliance

## Future Enhancements

### Planned Features
1. **Preferences**: User customization options
2. **Themes**: Light/dark mode preferences
3. **Export/Import**: Save tool configurations
4. **Shortcuts**: Keyboard shortcuts for common actions
5. **Request History**: Persistent storage for IP queries
6. **Additional IP Services**: More geolocation data providers

### Technical Improvements
- **Performance**: Optimize for large data processing
- **Memory**: Efficient handling of large text inputs
- **Accessibility**: VoiceOver support
- **Localization**: Multi-language support

## Maintenance Guidelines

### Code Organization
- Each tool in separate Swift file
- Consistent naming conventions
- Comprehensive documentation
- SwiftUI best practices

### Adding New Tools
1. Add case to `ToolType` enum
2. Create new SwiftUI view file
3. Add to ContentView switch statement
4. Update this design document
5. Add appropriate tests

### Styling Updates
- Modify shared UI components
- Update color scheme in Assets.xcassets
- Maintain consistency across all tools

## Deployment

### App Store Requirements
- Code signing configuration
- App icon in all required sizes
- Privacy policy for network access
- App Store Connect metadata

### Distribution Options
- Mac App Store
- Direct distribution with notarization
- Developer ID signing for enterprise

---

*This design document should be updated whenever significant changes are made to the app architecture or individual tools.*
