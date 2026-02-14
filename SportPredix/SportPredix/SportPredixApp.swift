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
    @StateObject private var authManager = AuthManager.shared
    
    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.isLoggedIn {
                ContentView()
                    .environmentObject(authManager)
            } else {
                AuthView()
                    .environmentObject(authManager)
            }
        }
    }
}
