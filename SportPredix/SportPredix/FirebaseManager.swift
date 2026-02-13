import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

enum PromoRedemptionStorageError: Error {
    case limitReached
    case invalidConfiguration
    case generic(Error)
}

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    @Published var isAuthenticated = false
    @Published var currentUserID: String? = nil
    @Published var errorMessage: String? = nil
    
    private init() {}
    private let promoCodeErrorDomain = "PromoCodeRedemption"
    
    func configureFirebase() {
        FirebaseApp.configure()
    }
    
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
    func saveBetSlip(userID: String, betID: String, stake: Double, totalOdd: Double, potentialWin: Double, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        
        let slipData: [String: Any] = [
            "id": betID,
            "stake": stake,
            "totalOdd": totalOdd,
            "potentialWin": potentialWin,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(userID).collection("bets").document(betID).setData(slipData) { error in
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

    // MARK: - Registra utilizzo codice promo (con limite globale e uso singolo per utente)
    func registerPromoCodeUsage(
        userID: String,
        code: String,
        bonus: Double,
        maxUses: Int,
        completion: @escaping (Result<Double, PromoRedemptionStorageError>) -> Void
    ) {
        let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        guard !normalizedCode.isEmpty, maxUses > 0 else {
            completion(.failure(.invalidConfiguration))
            return
        }
        
        let db = Firestore.firestore()
        let promoCodeRef = db.collection("promoCodes").document(normalizedCode)
        let userRedemptionRef = db.collection("users").document(userID).collection("promoRedemptions").document(normalizedCode)
        let userRef = db.collection("users").document(userID)
        let limitReachedCode = 1001
        
        db.runTransaction({ transaction, errorPointer in
            do {
                let promoCodeSnapshot = try transaction.getDocument(promoCodeRef)
                let currentUsedCount = Self.intValue(from: promoCodeSnapshot.data()?["usedCount"]) ?? 0
                
                if currentUsedCount >= maxUses {
                    errorPointer?.pointee = NSError(
                        domain: self.promoCodeErrorDomain,
                        code: limitReachedCode,
                        userInfo: [NSLocalizedDescriptionKey: "limit_reached"]
                    )
                    return nil
                }
                
                var promoData: [String: Any] = [
                    "code": normalizedCode,
                    "usedCount": currentUsedCount + 1,
                    "maxUses": maxUses,
                    "lastBonus": bonus,
                    "lastUpdated": FieldValue.serverTimestamp()
                ]
                if !promoCodeSnapshot.exists {
                    promoData["createdAt"] = FieldValue.serverTimestamp()
                }
                
                let userSnapshot = try transaction.getDocument(userRef)
                let currentBalance = Self.doubleValue(from: userSnapshot.data()?["balance"]) ?? 1000
                let newBalance = currentBalance + bonus
                
                let userRedemptionSnapshot = try transaction.getDocument(userRedemptionRef)
                let previousUserRedemptions = Self.intValue(from: userRedemptionSnapshot.data()?["redemptionCount"]) ?? 0
                let newUserRedemptions = previousUserRedemptions + 1
                
                transaction.setData(promoData, forDocument: promoCodeRef, merge: true)
                transaction.setData([
                    "code": normalizedCode,
                    "lastBonus": bonus,
                    "maxUsesAtRedemption": maxUses,
                    "redemptionCount": newUserRedemptions,
                    "totalRedeemedBonus": FieldValue.increment(bonus),
                    "lastRedeemedAt": FieldValue.serverTimestamp()
                ], forDocument: userRedemptionRef, merge: true)
                if !userRedemptionSnapshot.exists {
                    transaction.setData([
                        "firstRedeemedAt": FieldValue.serverTimestamp()
                    ], forDocument: userRedemptionRef, merge: true)
                }
                transaction.setData([
                    "balance": newBalance,
                    "lastUpdated": FieldValue.serverTimestamp()
                ], forDocument: userRef, merge: true)
                
                return newBalance
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
        }, completion: { value, error in
            if let error = error as NSError? {
                if error.domain == self.promoCodeErrorDomain, error.code == limitReachedCode {
                    completion(.failure(.limitReached))
                    return
                }
                
                completion(.failure(.generic(error)))
                return
            }
            
            guard let updatedBalance = Self.doubleValue(from: value) else {
                let error = NSError(
                    domain: self.promoCodeErrorDomain,
                    code: 1003,
                    userInfo: [NSLocalizedDescriptionKey: "invalid_balance_after_transaction"]
                )
                completion(.failure(.generic(error)))
                return
            }
            
            completion(.success(updatedBalance))
        })
    }

    private static func intValue(from raw: Any?) -> Int? {
        switch raw {
        case let value as Int:
            return value
        case let value as NSNumber:
            return value.intValue
        case let value as Double:
            return Int(value)
        case let value as String:
            return Int(value)
        default:
            return nil
        }
    }

    private static func doubleValue(from raw: Any?) -> Double? {
        switch raw {
        case let value as Double:
            return value
        case let value as Float:
            return Double(value)
        case let value as Int:
            return Double(value)
        case let value as NSNumber:
            return value.doubleValue
        case let value as String:
            return Double(value)
        default:
            return nil
        }
    }
}
