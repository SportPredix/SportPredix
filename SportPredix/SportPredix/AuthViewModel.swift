//
//  AuthViewModel.swift
//  SportPredix
//
//  Firebase Email/Password auth
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class AuthViewModel: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var userId: String?
    @Published var userEmail: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var authHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isSignedIn = user != nil
                self.userId = user?.uid
                self.userEmail = user?.email
            }
        }
    }
    
    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func signIn(email: String, password: String) {
        errorMessage = nil
        isLoading = true
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signUp(email: String, password: String, displayName: String) {
        errorMessage = nil
        isLoading = true
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self else { return }
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
                return
            }
            
            guard let user = result?.user else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Creazione utente fallita."
                }
                return
            }
            
            let payload: [String: Any] = [
                "userName": displayName,
                "email": email,
                "balance": 1000.0,
                "notificationsEnabled": true,
                "privacyEnabled": false,
                "selectedSport": "Calcio",
                "createdAt": Timestamp(date: Date())
            ]
            
            self.db.collection("users").document(user.uid).setData(payload, merge: true) { dbError in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let dbError = dbError {
                        self.errorMessage = dbError.localizedDescription
                    }
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
