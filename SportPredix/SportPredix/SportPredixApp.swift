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
    @StateObject private var auth = AuthViewModel()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
        }
    }
}
