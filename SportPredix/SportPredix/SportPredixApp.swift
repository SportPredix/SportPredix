//
//  SportPredixApp.swift
//  SportPredix
//
//  Created by Francesco on 12/01/26.
//

import SwiftUI
import FirebaseCore
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        .portrait
    }
}

@main
struct SportPredixApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var storeKitManager = StoreKitManager()
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isLoggedIn {
                    ContentView()
                } else {
                    AuthView()
                }
            }
            .environmentObject(authManager)
            .environmentObject(storeKitManager)
            .task {
                await storeKitManager.start()
            }
        }
    }
}
