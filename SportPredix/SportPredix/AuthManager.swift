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

enum FriendRequestError: LocalizedError {
    case userNotAuthenticated
    case invalidAccountCode
    case userNotFound
    case cannotRequestYourself
    case alreadyFriend
    case requestAlreadySent
    case requestAlreadyReceived
    case requestNotFound
    case generic(String)

    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "Devi essere autenticato per gestire amici."
        case .invalidAccountCode:
            return "Codice amico non valido."
        case .userNotFound:
            return "Nessun utente trovato con questo codice amico."
        case .cannotRequestYourself:
            return "Non puoi invitare te stesso."
        case .alreadyFriend:
            return "Questo utente e gia tra i tuoi amici."
        case .requestAlreadySent:
            return "Hai gia inviato una richiesta a questo utente."
        case .requestAlreadyReceived:
            return "Hai gia ricevuto una richiesta da questo utente."
        case .requestNotFound:
            return "Richiesta non trovata."
        case .generic(let message):
            return message
        }
    }
}

struct FriendUserSummary: Identifiable {
    let id: String
    let name: String
    let accountCode: String
}

struct FriendCenterSnapshot {
    let friends: [FriendUserSummary]
    let received: [FriendUserSummary]
    let sent: [FriendUserSummary]
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
        let codeLength = accountCodeLength

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
                "accountCode": String(user.uid.prefix(codeLength)).uppercased(),
                "friends": [],
                "friendRequestsReceived": [],
                "friendRequestsSent": [],
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

    // MARK: - Friend requests
    func sendFriendRequest(byAccountCode rawCode: String, completion: @escaping (Result<String, FriendRequestError>) -> Void) {
        guard let currentUserID else {
            errorMessage = FriendRequestError.userNotAuthenticated.localizedDescription
            completion(.failure(.userNotAuthenticated))
            return
        }

        let normalizedCode = rawCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        guard normalizedCode.count == accountCodeLength else {
            errorMessage = FriendRequestError.invalidAccountCode.localizedDescription
            completion(.failure(.invalidAccountCode))
            return
        }

        findUserByAccountCode(normalizedCode) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {
                case .failure(let error):
                    let resolved = self.mapFriendRequestError(from: error)
                    self.errorMessage = resolved.localizedDescription
                    completion(.failure(resolved))
                case .success(let match):
                    let targetUserID = match.id
                    let targetName = match.name

                    if targetUserID == currentUserID {
                        self.errorMessage = FriendRequestError.cannotRequestYourself.localizedDescription
                        completion(.failure(.cannotRequestYourself))
                        return
                    }

                    let db = Firestore.firestore()
                    let currentUserRef = db.collection("users").document(currentUserID)
                    let targetUserRef = db.collection("users").document(targetUserID)

                    currentUserRef.getDocument { currentSnapshot, currentError in
                        DispatchQueue.main.async {
                            if let currentError {
                                let resolved = FriendRequestError.generic(currentError.localizedDescription)
                                self.errorMessage = resolved.localizedDescription
                                completion(.failure(resolved))
                                return
                            }

                            targetUserRef.getDocument { targetSnapshot, targetError in
                                DispatchQueue.main.async {
                                    if let targetError {
                                        let resolved = FriendRequestError.generic(targetError.localizedDescription)
                                        self.errorMessage = resolved.localizedDescription
                                        completion(.failure(resolved))
                                        return
                                    }

                                    let currentData = currentSnapshot?.data() ?? [:]
                                    let targetData = targetSnapshot?.data() ?? [:]

                                    let currentFriends = self.friendIDList(from: currentData, key: "friends")
                                    let currentReceived = self.friendIDList(from: currentData, key: "friendRequestsReceived")
                                    let currentSent = self.friendIDList(from: currentData, key: "friendRequestsSent")
                                    let targetFriends = self.friendIDList(from: targetData, key: "friends")

                                    if currentFriends.contains(targetUserID) || targetFriends.contains(currentUserID) {
                                        self.errorMessage = FriendRequestError.alreadyFriend.localizedDescription
                                        completion(.failure(.alreadyFriend))
                                        return
                                    }

                                    if currentSent.contains(targetUserID) {
                                        self.errorMessage = FriendRequestError.requestAlreadySent.localizedDescription
                                        completion(.failure(.requestAlreadySent))
                                        return
                                    }

                                    if currentReceived.contains(targetUserID) {
                                        self.errorMessage = FriendRequestError.requestAlreadyReceived.localizedDescription
                                        completion(.failure(.requestAlreadyReceived))
                                        return
                                    }

                                    let batch = db.batch()
                                    batch.setData([
                                        "friendRequestsSent": FieldValue.arrayUnion([targetUserID]),
                                        "lastUpdated": FieldValue.serverTimestamp()
                                    ], forDocument: currentUserRef, merge: true)
                                    batch.setData([
                                        "friendRequestsReceived": FieldValue.arrayUnion([currentUserID]),
                                        "lastUpdated": FieldValue.serverTimestamp()
                                    ], forDocument: targetUserRef, merge: true)

                                    batch.commit { commitError in
                                        DispatchQueue.main.async {
                                            if let commitError {
                                                let resolved = FriendRequestError.generic(commitError.localizedDescription)
                                                self.errorMessage = resolved.localizedDescription
                                                completion(.failure(resolved))
                                                return
                                            }

                                            self.errorMessage = nil
                                            completion(.success(targetName))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func loadFriendCenterSnapshot(completion: @escaping (Result<FriendCenterSnapshot, FriendRequestError>) -> Void) {
        guard let currentUserID else {
            completion(.failure(.userNotAuthenticated))
            return
        }

        let currentUserRef = Firestore.firestore().collection("users").document(currentUserID)
        currentUserRef.getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error {
                    completion(.failure(.generic(error.localizedDescription)))
                    return
                }

                let data = snapshot?.data() ?? [:]
                let friendIDs = self.uniquePreservingOrder(self.friendIDList(from: data, key: "friends"))
                let receivedIDs = self.uniquePreservingOrder(self.friendIDList(from: data, key: "friendRequestsReceived"))
                let sentIDs = self.uniquePreservingOrder(self.friendIDList(from: data, key: "friendRequestsSent"))
                let allIDs = self.uniquePreservingOrder(friendIDs + receivedIDs + sentIDs)

                guard !allIDs.isEmpty else {
                    completion(.success(FriendCenterSnapshot(friends: [], received: [], sent: [])))
                    return
                }

                self.fetchUsers(withIDs: allIDs) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .failure(let error):
                            completion(.failure(error))
                        case .success(let usersByID):
                            let friends = friendIDs.map { usersByID[$0] ?? self.fallbackFriendSummary(for: $0) }
                            let received = receivedIDs.map { usersByID[$0] ?? self.fallbackFriendSummary(for: $0) }
                            let sent = sentIDs.map { usersByID[$0] ?? self.fallbackFriendSummary(for: $0) }
                            completion(.success(FriendCenterSnapshot(friends: friends, received: received, sent: sent)))
                        }
                    }
                }
            }
        }
    }

    func acceptFriendRequest(from requesterUserID: String, completion: @escaping (Result<String, FriendRequestError>) -> Void) {
        guard let currentUserID else {
            completion(.failure(.userNotAuthenticated))
            return
        }

        let db = Firestore.firestore()
        let currentUserRef = db.collection("users").document(currentUserID)
        let requesterRef = db.collection("users").document(requesterUserID)

        currentUserRef.getDocument { [weak self] currentSnapshot, currentError in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let currentError {
                    completion(.failure(.generic(currentError.localizedDescription)))
                    return
                }

                requesterRef.getDocument { requesterSnapshot, requesterError in
                    DispatchQueue.main.async {
                        if let requesterError {
                            completion(.failure(.generic(requesterError.localizedDescription)))
                            return
                        }

                        guard requesterSnapshot?.exists == true else {
                            completion(.failure(.userNotFound))
                            return
                        }

                        let currentData = currentSnapshot?.data() ?? [:]
                        let requesterData = requesterSnapshot?.data() ?? [:]
                        let currentReceived = self.friendIDList(from: currentData, key: "friendRequestsReceived")
                        let requesterSent = self.friendIDList(from: requesterData, key: "friendRequestsSent")
                        let requestExists = currentReceived.contains(requesterUserID) || requesterSent.contains(currentUserID)

                        guard requestExists else {
                            completion(.failure(.requestNotFound))
                            return
                        }

                        let batch = db.batch()
                        batch.setData([
                            "friends": FieldValue.arrayUnion([requesterUserID]),
                            "friendRequestsReceived": FieldValue.arrayRemove([requesterUserID]),
                            "friendRequestsSent": FieldValue.arrayRemove([requesterUserID]),
                            "lastUpdated": FieldValue.serverTimestamp()
                        ], forDocument: currentUserRef, merge: true)
                        batch.setData([
                            "friends": FieldValue.arrayUnion([currentUserID]),
                            "friendRequestsSent": FieldValue.arrayRemove([currentUserID]),
                            "friendRequestsReceived": FieldValue.arrayRemove([currentUserID]),
                            "lastUpdated": FieldValue.serverTimestamp()
                        ], forDocument: requesterRef, merge: true)

                        batch.commit { commitError in
                            DispatchQueue.main.async {
                                if let commitError {
                                    completion(.failure(.generic(commitError.localizedDescription)))
                                    return
                                }

                                completion(.success(self.resolvedName(from: requesterData)))
                            }
                        }
                    }
                }
            }
        }
    }

    func declineFriendRequest(from requesterUserID: String, completion: @escaping (Result<Void, FriendRequestError>) -> Void) {
        guard let currentUserID else {
            completion(.failure(.userNotAuthenticated))
            return
        }

        let db = Firestore.firestore()
        let currentUserRef = db.collection("users").document(currentUserID)
        let requesterRef = db.collection("users").document(requesterUserID)
        let batch = db.batch()

        batch.setData([
            "friendRequestsReceived": FieldValue.arrayRemove([requesterUserID]),
            "lastUpdated": FieldValue.serverTimestamp()
        ], forDocument: currentUserRef, merge: true)
        batch.setData([
            "friendRequestsSent": FieldValue.arrayRemove([currentUserID]),
            "lastUpdated": FieldValue.serverTimestamp()
        ], forDocument: requesterRef, merge: true)

        batch.commit { error in
            DispatchQueue.main.async {
                if let error {
                    completion(.failure(.generic(error.localizedDescription)))
                    return
                }
                completion(.success(()))
            }
        }
    }

    func cancelSentFriendRequest(to targetUserID: String, completion: @escaping (Result<Void, FriendRequestError>) -> Void) {
        guard let currentUserID else {
            completion(.failure(.userNotAuthenticated))
            return
        }

        let db = Firestore.firestore()
        let currentUserRef = db.collection("users").document(currentUserID)
        let targetRef = db.collection("users").document(targetUserID)
        let batch = db.batch()

        batch.setData([
            "friendRequestsSent": FieldValue.arrayRemove([targetUserID]),
            "lastUpdated": FieldValue.serverTimestamp()
        ], forDocument: currentUserRef, merge: true)
        batch.setData([
            "friendRequestsReceived": FieldValue.arrayRemove([currentUserID]),
            "lastUpdated": FieldValue.serverTimestamp()
        ], forDocument: targetRef, merge: true)

        batch.commit { error in
            DispatchQueue.main.async {
                if let error {
                    completion(.failure(.generic(error.localizedDescription)))
                    return
                }
                completion(.success(()))
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

    private func mapFriendRequestError(from addFriendError: AddFriendError) -> FriendRequestError {
        switch addFriendError {
        case .userNotAuthenticated:
            return .userNotAuthenticated
        case .invalidAccountCode:
            return .invalidAccountCode
        case .userNotFound:
            return .userNotFound
        case .cannotAddYourself:
            return .cannotRequestYourself
        case .alreadyFriend:
            return .alreadyFriend
        case .generic(let message):
            return .generic(message)
        }
    }

    private func friendIDList(from data: [String: Any], key: String) -> [String] {
        (data[key] as? [String]) ?? []
    }

    private func uniquePreservingOrder(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }

    private func fallbackFriendSummary(for userID: String) -> FriendUserSummary {
        FriendUserSummary(
            id: userID,
            name: "Utente",
            accountCode: String(userID.prefix(accountCodeLength)).uppercased()
        )
    }

    private func fetchUsers(withIDs ids: [String], completion: @escaping (Result<[String: FriendUserSummary], FriendRequestError>) -> Void) {
        guard !ids.isEmpty else {
            completion(.success([:]))
            return
        }

        let db = Firestore.firestore()
        let group = DispatchGroup()
        let lock = NSLock()

        var usersByID: [String: FriendUserSummary] = [:]
        var firstError: FriendRequestError?

        for userID in ids {
            group.enter()
            db.collection("users").document(userID).getDocument { [weak self] snapshot, error in
                defer { group.leave() }
                guard let self = self else { return }

                if let error {
                    lock.lock()
                    if firstError == nil {
                        firstError = .generic(error.localizedDescription)
                    }
                    lock.unlock()
                    return
                }

                let data = snapshot?.data() ?? [:]
                let name = self.resolvedName(from: data)
                let accountCode = self.resolvedAccountCode(from: userID, storedCode: data["accountCode"] as? String)
                let summary = FriendUserSummary(id: userID, name: name, accountCode: accountCode)

                lock.lock()
                usersByID[userID] = summary
                lock.unlock()
            }
        }

        group.notify(queue: .main) {
            if let firstError {
                completion(.failure(firstError))
                return
            }
            completion(.success(usersByID))
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
