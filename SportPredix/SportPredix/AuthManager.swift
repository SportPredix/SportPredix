import Foundation
import FirebaseAuth
import FirebaseFirestore
import UIKit

class AuthManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUserID: String?
    @Published var currentUserEmail: String?
    @Published var currentUserName: String?
    @Published var currentUserProfileImageData: Data?
    @Published var errorMessage: String?
    @Published var isLoading = false

    static let shared = AuthManager()
    private let maxProfileImageBytes = 180_000

    private init() {
        checkAuthStatus()
    }

    // MARK: - Check auth status
    func checkAuthStatus() {
        if let user = Auth.auth().currentUser {
            currentUserID = user.uid
            currentUserEmail = user.email
            currentUserName = user.displayName
            isLoggedIn = true
            loadUserProfile()
        } else {
            clearSessionData()
        }
    }

    // MARK: - Registration
    func register(email: String, password: String, name: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = trimmedName.isEmpty ? "Utente" : trimmedName

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                    self?.isLoading = false
                    completion(false)
                }
                return
            }

            guard let user = result?.user else {
                DispatchQueue.main.async {
                    self?.errorMessage = "Errore durante la registrazione"
                    self?.isLoading = false
                    completion(false)
                }
                return
            }

            let db = Firestore.firestore()
            let userData: [String: Any] = [
                "userID": user.uid,
                "name": resolvedName,
                "email": email,
                "balance": 1000.0,
                "createdAt": FieldValue.serverTimestamp(),
                "lastUpdated": FieldValue.serverTimestamp()
            ]

            db.collection("users").document(user.uid).setData(userData) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        self?.isLoading = false
                        completion(false)
                        return
                    }

                    self?.currentUserID = user.uid
                    self?.currentUserEmail = email
                    self?.currentUserName = resolvedName
                    self?.currentUserProfileImageData = nil
                    self?.isLoggedIn = true
                    self?.isLoading = false
                    completion(true)
                }
            }
        }
    }

    // MARK: - Login
    func login(email: String, password: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                    self?.isLoading = false
                    completion(false)
                }
                return
            }

            guard let user = result?.user else {
                DispatchQueue.main.async {
                    self?.errorMessage = "Errore durante il login"
                    self?.isLoading = false
                    completion(false)
                }
                return
            }

            DispatchQueue.main.async {
                self?.currentUserID = user.uid
                self?.currentUserEmail = user.email
                self?.currentUserName = user.displayName
                self?.currentUserProfileImageData = nil
                self?.isLoggedIn = true
                self?.loadUserProfile()
                self?.isLoading = false
                completion(true)
            }
        }
    }

    // MARK: - Load user profile
    func loadUserProfile() {
        guard let userID = currentUserID else { return }

        Firestore.firestore().collection("users").document(userID).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let document = document, document.exists else { return }
                let data = document.data() ?? [:]

                if let name = data["name"] as? String {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.currentUserName = trimmed.isEmpty ? "Utente" : trimmed
                } else if self.currentUserName?.isEmpty ?? true {
                    self.currentUserName = "Utente"
                }

                if let base64 = data["profileImageBase64"] as? String,
                   let imageData = Data(base64Encoded: base64) {
                    self.currentUserProfileImageData = imageData
                } else {
                    self.currentUserProfileImageData = nil
                }
            }
        }
    }

    // MARK: - Update user name
    func updateUserName(_ newName: String, completion: @escaping (Bool) -> Void) {
        guard let userID = currentUserID else {
            errorMessage = "Utente non autenticato"
            completion(false)
            return
        }

        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Inserisci un nome utente valido"
            completion(false)
            return
        }

        Firestore.firestore().collection("users").document(userID).setData([
            "name": trimmedName,
            "lastUpdated": FieldValue.serverTimestamp()
        ], merge: true) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }

                self?.currentUserName = trimmedName
                self?.errorMessage = nil
                completion(true)
            }
        }

        if let user = Auth.auth().currentUser {
            let request = user.createProfileChangeRequest()
            request.displayName = trimmedName
            request.commitChanges { _ in }
        }
    }

    // MARK: - Update profile photo
    func updateProfileImage(_ rawImageData: Data, completion: @escaping (Bool) -> Void) {
        guard let userID = currentUserID else {
            errorMessage = "Utente non autenticato"
            completion(false)
            return
        }

        guard let compressedData = prepareProfileImageData(from: rawImageData) else {
            errorMessage = "Immagine non valida"
            completion(false)
            return
        }

        guard compressedData.count <= maxProfileImageBytes else {
            errorMessage = "Immagine troppo grande, scegli una foto piu leggera"
            completion(false)
            return
        }

        Firestore.firestore().collection("users").document(userID).setData([
            "profileImageBase64": compressedData.base64EncodedString(),
            "lastUpdated": FieldValue.serverTimestamp()
        ], merge: true) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }

                self?.currentUserProfileImageData = compressedData
                self?.errorMessage = nil
                completion(true)
            }
        }
    }

    // MARK: - Remove profile photo
    func removeProfileImage(completion: @escaping (Bool) -> Void) {
        guard let userID = currentUserID else {
            errorMessage = "Utente non autenticato"
            completion(false)
            return
        }

        Firestore.firestore().collection("users").document(userID).updateData([
            "profileImageBase64": FieldValue.delete(),
            "lastUpdated": FieldValue.serverTimestamp()
        ]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }

                self?.currentUserProfileImageData = nil
                self?.errorMessage = nil
                completion(true)
            }
        }
    }

    // MARK: - Logout
    func logout() {
        do {
            try Auth.auth().signOut()
            clearSessionData()
        } catch let error {
            errorMessage = error.localizedDescription
        }
    }

    private func clearSessionData() {
        isLoggedIn = false
        currentUserID = nil
        currentUserEmail = nil
        currentUserName = nil
        currentUserProfileImageData = nil
        errorMessage = nil
    }

    private func prepareProfileImageData(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }

        let resizedImage = resizeImage(image, maxDimension: 512)
        let compressionSteps: [CGFloat] = [0.8, 0.65, 0.5, 0.35, 0.25, 0.18]

        for quality in compressionSteps {
            if let compressed = resizedImage.jpegData(compressionQuality: quality),
               compressed.count <= maxProfileImageBytes {
                return compressed
            }
        }

        return resizedImage.jpegData(compressionQuality: 0.15)
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let originalSize = image.size
        let maxSide = max(originalSize.width, originalSize.height)

        guard maxSide > maxDimension else { return image }

        let scale = maxDimension / maxSide
        let newSize = CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
