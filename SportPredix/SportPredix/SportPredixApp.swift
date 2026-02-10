//
//  SportPredixApp.swift
//  SportPredix
//
//  Created by Francesco on 12/01/26.
//

import SwiftUI
import FirebaseCore

@main
struct SportPredixApp: App {
    init() {
        FirebaseManager.shared.configureFirebase()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
