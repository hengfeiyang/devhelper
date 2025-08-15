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

struct ContentView: View {
    @State private var selectedTool: ToolType = .timestampConverter
    @State private var searchText: String = ""
    
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return "v\(version)"
        }
        return "v1.2"
    }
    
    var filteredTools: [ToolType] {
        if searchText.isEmpty {
            return ToolType.allCases
        } else {
            return ToolType.allCases.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DevHelper")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Developer Tools \(appVersion)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search tools...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
                
                List(filteredTools, selection: $selectedTool) { tool in
                    Label(tool.title, systemImage: tool.iconName)
                        .tag(tool)
                }
            }
            .frame(minWidth: 210, maxWidth: .infinity, alignment: .leading)
        } detail: {
            Group {
                switch selectedTool {
                case .timestampConverter:
                    TimestampConverterView()
                case .unitConverter:
                    UnitConverterView()
                case .jsonFormatter:
                    JSONFormatterView()
                case .sqlFormatter:
                    SQLFormatterView()
                case .htmlFormatter:
                    HTMLFormatterView()
                case .base64:
                    Base64View()
                case .jwt:
                    JWTView()
                case .regexTest:
                    RegexTestView()
                case .uuidGenerator:
                    UUIDGeneratorView()
                case .urlTools:
                    URLToolsView()
                case .ipQuery:
                    IPQueryView()
                case .httpRequest:
                    HTTPRequestView()
                case .qrCode:
                    QRCodeView()
                case .parquetViewer:
                    ParquetViewerView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 1000, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
