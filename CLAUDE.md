# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview
DevHelper is a native macOS application built with SwiftUI that provides 14 essential developer utilities. Version 1.10.2 with enhanced JSON diff functionality.

## Key Tools & Status

All 14 tools are ✅ **Complete**:
1. **Timestamp Converter** - Bidirectional timestamp conversion with timezone support
2. **Unit Converter** - 7 categories (Data, Time, Length, Weight, Temperature, Area, Volume)
3. **JSON Formatter** - Format, validate, escape/unescape, **visual CodeMirror diff editor**
4. **Base64 Encode/Decode** - Text encoding/decoding with URL-safe variant
5. **Regex Test** - Pattern matching with capture groups and common patterns
6. **UUID Generator** - Multiple versions (v1, v4, v5, v7) with bulk generation
7. **URL Tools** - Encoding/decoding and comprehensive URL parsing
8. **IP Query** - Dual IP detection and geolocation queries
9. **HTTP Request** - Full HTTP client with SSE streaming and JSON tree view
10. **QR Code** - Generation and scanning with multiple sizes and error correction
11. **SQL Formatter** - Format and minify SQL with syntax validation
12. **HTML Formatter** - Format and minify HTML with proper indentation
13. **JWT Encoder/Decoder** - HMAC algorithms with CryptoKit security
14. **Parquet Viewer** - DuckDB integration for Parquet/Arrow file reading

## Architecture & Technical Stack
- **Platform**: macOS 14.0+ SwiftUI
- **Navigation**: NavigationSplitView with sidebar search
- **Dependencies**: DuckDB, Arrow, CodeMirror-SwiftUI via SPM
- **Security**: CryptoKit for JWT HMAC operations

## Build Commands
```bash
# Open in Xcode
open DevHelper.xcodeproj

# Build and run
xcodebuild -project DevHelper.xcodeproj -scheme DevHelper build

# Using MCP tools
mcp__XcodeBuildMCP__build_run_macos
```

## Recent Updates (v1.10.2)
- **JSON Formatter**: Enhanced with visual CodeMirror diff editor
- **CodeDiffEditor**: New component for side-by-side JSON comparison
- **Improved UX**: Replaced text-based diff with visual highlighting

## Development Notes
- Each tool is self-contained in `Views/` directory
- Consistent UI patterns: two-column layouts, copy buttons, sample data
- Uses `@State` for local view state management
- All tools have real-time processing and validation
- App Sandbox enabled with network and file permissions