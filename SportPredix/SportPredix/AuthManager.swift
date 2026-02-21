import Foundation
import FirebaseAuth
import FirebaseFirestore
import UIKit

enum AddFriendError: LocalizedError {
    case userNotAuthenticated
    case invalidAccountCode
    case userNotFound
    case cannotAddYourself
    case alreadyFriend
    case generic(String)

    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "Devi essere autenticato per aggiungere amici."
        case .invalidAccountCode:
            return "Codice account non valido."
        case .userNotFound:
            return "Nessun utente trovato con questo codice account."
        case .cannotAddYourself:
            return "Non puoi aggiungere te stesso."
        case .alreadyFriend:
            return "Questo utente e gia tra i tuoi amici."
        case .generic(let message):
            return message
        }
    }
}

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
    private let accountCodeLength = 8

    private init() {
        checkAuthStatus()
    }

    var currentUserAccountCode: String {
        guard let currentUserID else { return "N/A" }
        return String(currentUserID.prefix(accountCodeLength)).uppercased()
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
                "accountCode": String(user.uid.prefix(accountCodeLength)).uppercased(),
                "friends": [],
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

                let resolvedCode = self.resolvedAccountCode(from: userID, storedCode: data["accountCode"] as? String)
                if data["accountCode"] == nil {
                    Firestore.firestore().collection("users").document(userID).setData([
                        "accountCode": resolvedCode,
                        "lastUpdated": FieldValue.serverTimestamp()
                    ], merge: true)
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

    // MARK: - Add friend by account code
    func addFriend(byAccountCode rawCode: String, completion: @escaping (Result<String, AddFriendError>) -> Void) {
        guard let currentUserID = currentUserID else {
            errorMessage = AddFriendError.userNotAuthenticated.localizedDescription
            completion(.failure(.userNotAuthenticated))
            return
        }

        let normalizedCode = rawCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        guard normalizedCode.count == accountCodeLength else {
            errorMessage = AddFriendError.invalidAccountCode.localizedDescription
            completion(.failure(.invalidAccountCode))
            return
        }

        findUserByAccountCode(normalizedCode) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                case .success(let match):
                    let friendID = match.id
                    let friendName = match.name

                    if friendID == currentUserID {
                        self.errorMessage = AddFriendError.cannotAddYourself.localizedDescription
                        completion(.failure(.cannotAddYourself))
                        return
                    }

                    let db = Firestore.firestore()
                    let currentUserRef = db.collection("users").document(currentUserID)
                    let friendUserRef = db.collection("users").document(friendID)

                    currentUserRef.getDocument { snapshot, error in
                        DispatchQueue.main.async {
                            if let error = error {
                                let resolved = AddFriendError.generic(error.localizedDescription)
                                self.errorMessage = resolved.localizedDescription
                                completion(.failure(resolved))
                                return
                            }

                            let currentFriends = (snapshot?.data()?["friends"] as? [String]) ?? []
                            if currentFriends.contains(friendID) {
                                self.errorMessage = AddFriendError.alreadyFriend.localizedDescription
                                completion(.failure(.alreadyFriend))
                                return
                            }

                            let batch = db.batch()
                            batch.setData([
                                "friends": FieldValue.arrayUnion([friendID]),
                                "lastUpdated": FieldValue.serverTimestamp()
                            ], forDocument: currentUserRef, merge: true)
                            batch.setData([
                                "friends": FieldValue.arrayUnion([currentUserID]),
                                "lastUpdated": FieldValue.serverTimestamp()
                            ], forDocument: friendUserRef, merge: true)

                            batch.commit { error in
                                DispatchQueue.main.async {
                                    if let error = error {
                                        let resolved = AddFriendError.generic(error.localizedDescription)
                                        self.errorMessage = resolved.localizedDescription
                                        completion(.failure(resolved))
                                        return
                                    }

                                    self.errorMessage = nil
                                    completion(.success(friendName))
                                }
                            }
                        }
                    }
                }
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

    private func findUserByAccountCode(_ code: String, completion: @escaping (Result<(id: String, name: String), AddFriendError>) -> Void) {
        let usersRef = Firestore.firestore().collection("users")

        usersRef
            .whereField("accountCode", isEqualTo: code)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(.generic(error.localizedDescription)))
                    return
                }

                if let firstDoc = snapshot?.documents.first {
                    let name = self.resolvedName(from: firstDoc.data())
                    completion(.success((id: firstDoc.documentID, name: name)))
                    return
                }

                usersRef
                    .limit(to: 500)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            completion(.failure(.generic(error.localizedDescription)))
                            return
                        }

                        guard let match = (snapshot?.documents ?? []).first(where: { doc in
                            String(doc.documentID.prefix(self.accountCodeLength)).uppercased() == code
                        }) else {
                            completion(.failure(.userNotFound))
                            return
                        }

                        let name = self.resolvedName(from: match.data())
                        usersRef.document(match.documentID).setData([
                            "accountCode": code,
                            "lastUpdated": FieldValue.serverTimestamp()
                        ], merge: true)

                        completion(.success((id: match.documentID, name: name)))
                    }
            }
    }

    private func resolvedName(from data: [String: Any]) -> String {
        let trimmedName = (data["name"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmedName?.isEmpty == false) ? (trimmedName ?? "Utente") : "Utente"
    }

    private func resolvedAccountCode(from userID: String, storedCode: String?) -> String {
        if let storedCode {
            let trimmed = storedCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            if trimmed.count == accountCodeLength {
                return trimmed
            }
        }
        return String(userID.prefix(accountCodeLength)).uppercased()
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
