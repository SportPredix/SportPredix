import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class AuthManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUserID: String?
    @Published var currentUserEmail: String?
    @Published var currentUserName: String?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    static let shared = AuthManager()
    
    private init() {
        ensureFirebaseConfigured()
        checkAuthStatus()
    }

    private func ensureFirebaseConfigured() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    // MARK: - Controlla se l'utente è già loggato
    func checkAuthStatus() {
        if let user = Auth.auth().currentUser {
            self.currentUserID = user.uid
            self.currentUserEmail = user.email
            self.isLoggedIn = true
            loadUserProfile()
        } else {
            self.isLoggedIn = false
        }
    }
    
    // MARK: - Registrazione
    func register(email: String, password: String, name: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                self?.isLoading = false
                completion(false)
                return
            }
            
            guard let user = result?.user else {
                self?.errorMessage = "Errore durante la registrazione"
                self?.isLoading = false
                completion(false)
                return
            }
            
            // Salva il profilo su Firestore
            let db = Firestore.firestore()
            let userData: [String: Any] = [
                "userID": user.uid,
                "name": name,
                "email": email,
                "balance": 1000.0,
                "createdAt": FieldValue.serverTimestamp(),
                "lastUpdated": FieldValue.serverTimestamp()
            ]
            
            db.collection("users").document(user.uid).setData(userData) { error in
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.isLoading = false
                    completion(false)
                    return
                }
                
                self?.currentUserID = user.uid
                self?.currentUserEmail = email
                self?.currentUserName = name
                self?.isLoggedIn = true
                self?.isLoading = false
                completion(true)
            }
        }
    }
    
    // MARK: - Login
    func login(email: String, password: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                self?.isLoading = false
                completion(false)
                return
            }
            
            guard let user = result?.user else {
                self?.errorMessage = "Errore durante il login"
                self?.isLoading = false
                completion(false)
                return
            }
            
            self?.currentUserID = user.uid
            self?.currentUserEmail = user.email
            self?.isLoggedIn = true
            self?.loadUserProfile()
            self?.isLoading = false
            completion(true)
        }
    }
    
    // MARK: - Carica profilo utente
    func loadUserProfile() {
        guard let userID = currentUserID else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userID).getDocument { [weak self] document, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()
                self?.currentUserName = data?["name"] as? String
            }
        }
    }
    
    // MARK: - Logout
    func logout() {
        do {
            try Auth.auth().signOut()
            self.isLoggedIn = false
            self.currentUserID = nil
            self.currentUserEmail = nil
            self.currentUserName = nil
            self.errorMessage = nil
        } catch let error {
            self.errorMessage = error.localizedDescription
        }
    }
}
