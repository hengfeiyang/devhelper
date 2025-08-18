# Gemini Development Guide for DevHelper

This document provides a development overview for the DevHelper macOS application, intended to guide future development by Gemini.

## Project Overview

DevHelper is a macOS application built with SwiftUI that offers a collection of essential tools for developers. The application features a clean, modern interface with a sidebar for easy navigation between different tools.

### Core Technologies

- **UI Framework:** SwiftUI
- **Language:** Swift
- **Analytics:** Firebase Analytics
- **Dependencies:**
  - `firebase-ios-sdk`: For analytics and tracking.
  - `CodeMirror-SwiftUI`: Provides a code editor with syntax highlighting for tools like the JSON and SQL formatters.
  - `arrow-swift`, `duckdb-swift`: Used for data processing, likely within the Parquet Viewer tool.

### Project Structure

The project is organized into the following key directories and files:

- **`DevHelper/`**: The main source code directory for the application.
  - **`DevHelperApp.swift`**: The entry point of the application, responsible for initializing Firebase and setting up the main window.
  - **`ContentView.swift`**: The root view of the application. It uses a `NavigationSplitView` to create the main layout with a sidebar for tool selection and a detail view to display the selected tool.
  - **`Models/`**: Contains the data models for the application.
    - **`ToolType.swift`**: An essential enum that defines all the available tools. It includes properties for the tool's title and icon, making it easy to add new tools.
  - **`Views/`**: Contains the SwiftUI views for each individual tool. Each view is self-contained and implements the logic for its specific functionality.
  - **`Components/`**: Contains reusable SwiftUI components, such as `CodeEditor.swift`.
- **`DevHelper.xcodeproj/`**: The Xcode project file.

## Development Workflow

### Adding a New Tool

To add a new tool to DevHelper, follow these steps:

1.  **Create the View:**
    - Create a new SwiftUI view file in the `DevHelper/Views/` directory (e.g., `NewToolView.swift`).
    - Implement the UI and logic for the new tool within this view.

2.  **Update `ToolType.swift`:**
    - Add a new case to the `ToolType` enum in `DevHelper/Models/ToolType.swift`.
    - Provide a `title` and `iconName` for the new tool in the corresponding computed properties.

3.  **Integrate into `ContentView.swift`:**
    - Add a new `case` to the `switch` statement in the `detail` view of `ContentView.swift`.
    - In the new `case`, instantiate and display the new tool's view (e.g., `case .newTool: NewToolView()`).

### Areas for Future Development

- **New Tools:** The modular architecture makes it easy to add new tools. Some potential ideas include:
  - Hash generator (MD5, SHA-1, SHA-256)
  - Color picker and converter (Hex, RGB, HSL)
  - Cron job editor/validator
  - Network information tool (e.g., `ifconfig`, `ping`)
- **UI/UX Enhancements:**
  - Implement a settings screen for customizing application behavior (e.g., theme, default tool).
  - Add keyboard shortcuts for switching between tools.
  - Improve state restoration to remember the content within each tool across app launches.
- **Refactoring and Code Quality:**
  - Extract reusable logic from individual tool views into shared services or view models to reduce code duplication.
  - Add unit tests for the business logic within each tool.
- **Performance:**
  - For tools that handle large amounts of data (like the Parquet Viewer), consider offloading processing to background threads to keep the UI responsive.
