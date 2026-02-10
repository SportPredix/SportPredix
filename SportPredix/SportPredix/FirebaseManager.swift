import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    @Published var isAuthenticated = false
    @Published var currentUserID: String? = nil
    @Published var errorMessage: String? = nil
    
    private init() {}
    
    // MARK: - Salva profilo utente su Firestore
    func saveUserProfile(userID: String, name: String, email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        
        let userData: [String: Any] = [
            "userID": userID,
            "name": name,
            "email": email,
            "balance": 1000.0,
            "createdAt": FieldValue.serverTimestamp(),
            "lastUpdated": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(userID).setData(userData, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Carica profilo utente
    func loadUserProfile(userID: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("users").document(userID).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let document = document, document.exists {
                completion(.success(document.data() ?? [:]))
            } else {
                completion(.failure(NSError(domain: "User not found", code: 404)))
            }
        }
    }
    
    // MARK: - Salva scommesse su Firestore
    func saveBetSlip(userID: String, slip: BetSlip, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        
        let slipData: [String: Any] = [
            "id": slip.id.uuidString,
            "stake": slip.stake,
            "totalOdd": slip.totalOdd,
            "potentialWin": slip.potentialWin,
            "isWon": slip.isWon as Any,
            "isEvaluated": slip.isEvaluated,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(userID).collection("bets").document(slip.id.uuidString).setData(slipData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Aggiorna saldo
    func updateBalance(userID: String, newBalance: Double, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("users").document(userID).updateData([
            "balance": newBalance,
            "lastUpdated": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}