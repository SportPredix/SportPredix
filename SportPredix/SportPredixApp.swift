import SwiftUI
import FirebaseCore

@main
struct SportPredixApp: App {
    @StateObject private var authManager = AuthManager.shared
    
    init() {
        configureFirebaseIfAvailable()
        AuthManager.shared.bootstrapAuthStateIfNeeded()
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

    private func configureFirebaseIfAvailable() {
        guard FirebaseApp.app() == nil else { return }
        guard let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else {
            print("GoogleService-Info.plist non trovato nel bundle")
            return
        }
        guard let options = FirebaseOptions(contentsOfFile: plistPath) else {
            print("GoogleService-Info.plist non valido")
            return
        }

        FirebaseApp.configure(options: options)
    }
}
