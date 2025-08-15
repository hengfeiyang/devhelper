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

import Foundation

enum ToolType: String, CaseIterable, Identifiable {
    case timestampConverter = "timestamp"
    case unitConverter = "unit"
    case jsonFormatter = "json"
    case sqlFormatter = "sql"
    case htmlFormatter = "html"
    case base64 = "base64"
    case jwt = "jwt"
    case urlTools = "url"
    case regexTest = "regex"
    case uuidGenerator = "uuid"
    case httpRequest = "http"
    case ipQuery = "ip"
    case qrCode = "qrcode"
    case parquetViewer = "parquet"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .timestampConverter:
            return "Timestamp Converter"
        case .unitConverter:
            return "Unit Converter"
        case .jsonFormatter:
            return "JSON Formatter"
        case .sqlFormatter:
            return "SQL Formatter"
        case .htmlFormatter:
            return "HTML Formatter"
        case .base64:
            return "Base64 Encode/Decode"
        case .jwt:
            return "JWT Encoder/Decoder"
        case .urlTools:
            return "URL Tools"
        case .regexTest:
            return "Regex Test"
        case .uuidGenerator:
            return "UUID Generator"
        case .httpRequest:
            return "HTTP Request"
        case .ipQuery:
            return "IP Query"
        case .qrCode:
            return "QR Code"
        case .parquetViewer:
            return "Parquet Viewer"
        }
    }
    
    var iconName: String {
        switch self {
        case .timestampConverter:
            return "clock"
        case .unitConverter:
            return "scalemass"
        case .jsonFormatter:
            return "doc.text"
        case .sqlFormatter:
            return "cylinder.split.1x2"
        case .htmlFormatter:
            return "chevron.left.forwardslash.chevron.right"
        case .base64:
            return "6.circle"
        case .jwt:
            return "key.horizontal"
        case .urlTools:
            return "link"
        case .regexTest:
            return "magnifyingglass"
        case .uuidGenerator:
            return "dice"
        case .httpRequest:
            return "network"
        case .ipQuery:
            return "dot.radiowaves.left.and.right"
        case .qrCode:
            return "qrcode"
        case .parquetViewer:
            return "doc.text.magnifyingglass"
        }
    }
}