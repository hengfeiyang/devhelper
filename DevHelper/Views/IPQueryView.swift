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

struct IPQueryView: View {
    let screenName = "IP Query"
    @State private var myIPAddress: String = ""
    @State private var myIPDetails: IPLocationInfo? = nil
    @State private var chinaIPAddress: String = ""
    @State private var chinaIPDetails: BaiduIPInfo? = nil
    @State private var isLoadingMyIP: Bool = false
    @State private var showDualIP: Bool = false
    
    @State private var queryIPInput: String = ""
    @State private var queryIPDetails: IPLocationInfo? = nil
    @State private var isLoadingQuery: Bool = false
    @State private var queryError: String = ""
    @State private var sampleIPs: [String] = ["8.8.8.8", "1.1.1.1", "208.67.222.222"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text(screenName)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            HStack(alignment: .top, spacing: 40) {
                // My IP Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("My IP Address")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Button("Get My IP") {
                                getMyIPAddress()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isLoadingMyIP)
                            
                            if isLoadingMyIP {
                                ProgressView()
                                    .scaleEffect(0.5)
                                    .frame(width: 16, height: 16)
                            }
                        }
                        
                        if !myIPAddress.isEmpty || !chinaIPAddress.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                // International IP (ipinfo.io)
                                if !myIPAddress.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("IP:")
                                                .fontWeight(.medium)
                                            Text(myIPAddress)
                                                .font(.system(.body, design: .monospaced))
                                                .textSelection(.enabled)
                                            
                                            Button(action: {
                                                copyToClipboard(myIPAddress)
                                            }) {
                                                 Image(systemName: "doc.on.doc")
                                                .foregroundColor(.blue)
                                                .font(.caption)
                                            }
                                            .buttonStyle(.bordered)
                                            .help("Copy IP Address")
                                        }
                                        
                                        if let details = myIPDetails {
                                            ipDetailsView(details: details)
                                        }
                                    }
                                }
                                
                                // China IP (Taobao API)
                                if showDualIP && !chinaIPAddress.isEmpty {
                                    Divider()
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("IP:")
                                                .fontWeight(.medium)
                                            Text(chinaIPAddress)
                                                .font(.system(.body, design: .monospaced))
                                                .textSelection(.enabled)
                                            
                                            Button(action: {
                                                copyToClipboard(chinaIPAddress)
                                            }) {
                                                 Image(systemName: "doc.on.doc")
                                                .foregroundColor(.blue)
                                                .font(.caption)
                                            }
                                            .buttonStyle(.bordered)
                                            .help("Copy IP Address")
                                        }
                                        
                                        if let chinaDetails = chinaIPDetails {
                                            chinaIPDetailsView(details: chinaDetails.data)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppConstants.controlBackground)
                            .cornerRadius(10)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                // Query IP Section
                VStack(alignment: .leading, spacing: 15) {
                        Text("Query IP Location")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            TextField("Enter IP address (e.g., 8.8.8.8)", text: $queryIPInput)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    queryIPLocation()
                                }
                            
                            Button("Query") {
                                queryIPLocation()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(queryIPInput.isEmpty || isLoadingQuery)
                            
                            if isLoadingQuery {
                                ProgressView()
                                    .scaleEffect(0.5)
                                    .frame(width: 16, height: 16)
                            }
                        }
                        
                        // Sample IPs with history
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Sample IPs:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                if sampleIPs.count > 3 { // Only show if we have history beyond default IPs
                                    Button("Clear History") {
                                        clearIPHistory()
                                    }
                                    .font(.caption)
                                    .buttonStyle(.borderless)
                                }
                            }
                            
                            let rows = sampleIPs.chunked(into: 3)
                            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                                HStack {
                                    ForEach(row, id: \.self) { ip in
                                        Button(ip) { queryIPInput = ip }
                                    }
                                    Spacer()
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        
                        if !queryError.isEmpty {
                            Text(queryError)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        if let details = queryIPDetails {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("IP:")
                                        .fontWeight(.medium)
                                    Text(details.query)
                                        .font(.system(.body, design: .monospaced))
                                        .textSelection(.enabled)
                                    
                                    Button(action: {
                                        copyToClipboard(details.query)
                                    }) {
                                        Image(systemName: "doc.on.doc")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    }
                                    .buttonStyle(.bordered)
                                    .help("Copy IP Address")
                                }
                                
                                ipDetailsView(details: details)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppConstants.controlBackground)
                            .cornerRadius(10)
                        }
                        
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }.padding(.horizontal, 0)
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
    
    @ViewBuilder
    private func chinaIPDetailsView(details: BaiduIPData) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if !details.country.isEmpty {
                HStack {
                    Text("Country:")
                        .fontWeight(.medium)
                    Text("\(details.country) (\(details.countryCode))")
                        .textSelection(.enabled)
                }
            }
            
            if !details.region.isEmpty {
                HStack {
                    Text("Region:")
                        .fontWeight(.medium)
                    Text(details.region)
                        .textSelection(.enabled)
                }
            }
            
            if !details.city.isEmpty {
                HStack {
                    Text("City:")
                        .fontWeight(.medium)
                    Text(details.city)
                        .textSelection(.enabled)
                }
            }
            
            if !details.district.isEmpty {
                HStack {
                    Text("District:")
                        .fontWeight(.medium)
                    Text(details.district)
                        .textSelection(.enabled)
                }
            }
            
            if !details.timezone.isEmpty {
                HStack {
                    Text("Timezone:")
                        .fontWeight(.medium)
                    Text(details.timezone)
                        .textSelection(.enabled)
                }
            }
            
            if !details.isp.isEmpty {
                HStack {
                    Text("ISP:")
                        .fontWeight(.medium)
                    Text(details.isp)
                        .textSelection(.enabled)
                }
            }
        }
        .font(.system(.body, design: .default))
    }
    
    @ViewBuilder
    private func ipDetailsView(details: IPLocationInfo) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if !details.country.isEmpty {
                HStack {
                    Text("Country:")
                        .fontWeight(.medium)
                    Text("\(details.country) (\(details.countryCode))")
                        .textSelection(.enabled)
                }
            }
            
            if !details.region.isEmpty {
                HStack {
                    Text("Region:")
                        .fontWeight(.medium)
                    Text("\(details.region) (\(details.regionName))")
                        .textSelection(.enabled)
                }
            }
            
            if !details.city.isEmpty {
                HStack {
                    Text("City:")
                        .fontWeight(.medium)
                    Text(details.city)
                        .textSelection(.enabled)
                }
            }
            
            if !details.zip.isEmpty {
                HStack {
                    Text("Zip Code:")
                        .fontWeight(.medium)
                    Text(details.zip)
                        .textSelection(.enabled)
                }
            }
            
            if details.lat != 0 && details.lon != 0 {
                HStack {
                    Text("Coordinates:")
                        .fontWeight(.medium)
                    Text("\(details.lat, specifier: "%.4f"), \(details.lon, specifier: "%.4f")")
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
            
            if !details.timezone.isEmpty {
                HStack {
                    Text("Timezone:")
                        .fontWeight(.medium)
                    Text(details.timezone)
                        .textSelection(.enabled)
                }
            }
            
            if !details.isp.isEmpty {
                HStack {
                    Text("ISP:")
                        .fontWeight(.medium)
                    Text(details.isp)
                        .textSelection(.enabled)
                }
            }
            
            if !details.org.isEmpty && details.org != details.isp {
                HStack {
                    Text("Organization:")
                        .fontWeight(.medium)
                    Text(details.org)
                        .textSelection(.enabled)
                }
            }
        }
        .font(.system(.body, design: .default))
    }
    
    private func getMyIPAddress() {
        isLoadingMyIP = true
        myIPAddress = ""
        myIPDetails = nil
        chinaIPAddress = ""
        chinaIPDetails = nil
        showDualIP = false
        
        let group = DispatchGroup()
        
        // Call international IP service (ipinfo.io)
        group.enter()
        guard let internationalURL = URL(string: "https://ipinfo.io/json") else {
            group.leave()
            isLoadingMyIP = false
            return
        }
        
        var internationalRequest = URLRequest(url: internationalURL)
        internationalRequest.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        internationalRequest.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: internationalRequest) { data, response, error in
            defer { group.leave() }
            
            if let error = error {
                print("Error fetching international IP: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data received from international service")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let ipInfo = try decoder.decode(IPLocationInfo.self, from: data)
                
                DispatchQueue.main.async {
                    self.myIPAddress = ipInfo.ip
                    self.myIPDetails = ipInfo
                }
            } catch {
                print("Error decoding international IP info: \(error)")
            }
        }.resume()
        
        // Call China IP service (Baidu)
        group.enter()
        guard let chinaURL = URL(string: "https://qifu-api.baidubce.com/ip/local/geo/v1/district") else {
            group.leave()
            return
        }
        
        var chinaRequest = URLRequest(url: chinaURL)
        chinaRequest.setValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        chinaRequest.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: chinaRequest) { data, response, error in
            defer { group.leave() }
            
            if let error = error {
                print("Error fetching China IP: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data received from China service")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let chinaInfo = try decoder.decode(BaiduIPInfo.self, from: data)
                
                if chinaInfo.code == "Success" {
                    DispatchQueue.main.async {
                        self.chinaIPAddress = chinaInfo.ip
                        self.chinaIPDetails = chinaInfo
                    }
                }
            } catch {
                print("Error decoding China IP info: \(error)")
            }
        }.resume()
        
        // Wait for both requests to complete
        group.notify(queue: .main) {
            self.isLoadingMyIP = false
            
            // Check if IPs are different and show dual IP if needed
            if !self.myIPAddress.isEmpty && !self.chinaIPAddress.isEmpty && 
               self.myIPAddress != self.chinaIPAddress {
                self.showDualIP = true
            }
        }
    }
    
    private func queryIPLocation() {
        guard !queryIPInput.isEmpty else { return }
        
        isLoadingQuery = true
        queryIPDetails = nil
        queryError = ""
        
        // Validate IP format
        if !isValidIP(queryIPInput) {
            queryError = "Invalid IP address format"
            isLoadingQuery = false
            return
        }
        
        guard let url = URL(string: "https://ipinfo.io/\(queryIPInput)/json") else {
            queryError = "Invalid URL"
            isLoadingQuery = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoadingQuery = false
                
                if let error = error {
                    self.queryError = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.queryError = "No data received"
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let ipInfo = try decoder.decode(IPLocationInfo.self, from: data)
                    
                    self.queryIPDetails = ipInfo
                    self.queryError = ""
                    
                    // Add to sample IPs if not already present
                    if !self.sampleIPs.contains(ipInfo.ip) {
                        // Remove existing entry if present and add to beginning
                        self.sampleIPs.removeAll { $0 == ipInfo.ip }
                        self.sampleIPs.insert(ipInfo.ip, at: 0)
                        
                        // Keep only the most recent 9 IPs (3 rows of 3)
                        if self.sampleIPs.count > 9 {
                            self.sampleIPs = Array(self.sampleIPs.prefix(9))
                        }
                    }
                } catch {
                    self.queryError = "Error parsing response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    private func isValidIP(_ ip: String) -> Bool {
        let components = ip.split(separator: ".")
        guard components.count == 4 else { return false }
        
        for component in components {
            guard let number = Int(component), number >= 0, number <= 255 else {
                return false
            }
        }
        return true
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    private func clearIPHistory() {
        // Reset to default sample IPs
        sampleIPs = ["8.8.8.8", "1.1.1.1", "208.67.222.222"]
        
        // Clear from UserDefaults
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "IPQuery.sampleIPs")
    }
    
    private func saveState() {
        let defaults = UserDefaults.standard
        defaults.set(queryIPInput, forKey: "IPQuery.queryIPInput")
        defaults.set(sampleIPs, forKey: "IPQuery.sampleIPs")
    }
    
    private func loadState() {
        let defaults = UserDefaults.standard
        queryIPInput = defaults.string(forKey: "IPQuery.queryIPInput") ?? ""
        
        if let savedSampleIPs = defaults.array(forKey: "IPQuery.sampleIPs") as? [String] {
            sampleIPs = savedSampleIPs
        }
        
        // If we have query input, don't auto-query on load to avoid unnecessary network requests
        // User can manually click query if they want to
    }
    
}

struct BaiduIPInfo: Codable {
    let code: String
    let data: BaiduIPData
    let ip: String
}

struct BaiduIPData: Codable {
    let continent: String
    let country: String
    let zipcode: String?
    let owner: String
    let isp: String
    let adcode: String?
    let prov: String    // Province
    let city: String
    let district: String
    
    // Computed properties for compatibility
    var countryCode: String { 
        if country == "中国" { return "CN" }
        return country
    }
    var region: String { prov }
    var regionName: String { prov }
    var zip: String { zipcode ?? "" }
    var timezone: String { 
        if country == "中国" {
            return "Asia/Shanghai"
        }
        return ""
    }
    var org: String { isp }
    var loc: String { "" } // No coordinates from Baidu API
    var lat: Double { 0 }
    var lon: Double { 0 }
    var county: String { district }
}

struct IPLocationInfo: Codable {
    let ip: String
    let hostname: String?
    let city: String
    let region: String
    let country: String
    let loc: String  // "latitude,longitude" format
    let org: String
    let postal: String
    let timezone: String
    
    // Computed properties for compatibility
    var query: String { ip }
    var countryCode: String { country }
    var regionName: String { region }
    var zip: String { postal }
    var isp: String { org }
    
    var lat: Double {
        let components = loc.split(separator: ",")
        return Double(components.first ?? "0") ?? 0
    }
    
    var lon: Double {
        let components = loc.split(separator: ",")
        return Double(components.count > 1 ? components[1] : "0") ?? 0
    }
    
    init() {
        self.ip = ""
        self.hostname = nil
        self.city = ""
        self.region = ""
        self.country = ""
        self.loc = ""
        self.org = ""
        self.postal = ""
        self.timezone = ""
    }
}


// MARK: - Array Extension for Chunking

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

#Preview {
    IPQueryView()
}
