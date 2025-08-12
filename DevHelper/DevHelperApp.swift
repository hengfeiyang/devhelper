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
import FirebaseCore
import FirebaseAnalytics

@main
struct DevHelperApp: App {
    init() {
        // Configure Firebase with custom options to avoid WebKit
        let options = FirebaseOptions(
            googleAppID: "1:508874436485:ios:7cdddb663471f4497e9eec",
            gcmSenderID: "508874436485"
        )
        options.apiKey = "AIzaSyBBRVbbWnmenyhD4z4nA2lLIU9vtXqVc2k"
        options.projectID = "devhelper-29663"
        options.storageBucket = "devhelper-29663.firebasestorage.app"
        
        FirebaseApp.configure(options: options)
        
        // Configure Analytics to avoid WebKit features
        Analytics.setAnalyticsCollectionEnabled(true)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1000, height: 800)
    }
}
