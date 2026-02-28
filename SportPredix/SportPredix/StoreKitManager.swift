import Foundation
import StoreKit

enum InAppPurchaseConfig {
    static let sportPassProductID = "SPS1"
}

enum SportPassPurchaseResult {
    case success
    case pending
    case cancelled
    case notConfigured
    case notAvailable
    case failed(message: String)
}

@MainActor
final class StoreKitManager: ObservableObject {
    @Published private(set) var sportPassProduct: Product?
    @Published private(set) var hasSportPassAccess = false
    @Published private(set) var isLoadingProduct = false
    @Published private(set) var isProcessingPurchase = false

    private var transactionUpdatesTask: Task<Void, Never>?
    private var hasStarted = false

    deinit {
        transactionUpdatesTask?.cancel()
    }

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        startTransactionUpdatesListener()
        await refreshStoreState()
    }

    func refreshStoreState() async {
        await loadProduct()
        await refreshEntitlements()
    }

    func purchaseSportPass() async -> SportPassPurchaseResult {
        guard isProductIDConfigured else {
            return .notConfigured
        }
        guard let product = sportPassProduct else {
            return .notAvailable
        }
        guard !isProcessingPurchase else {
            return .pending
        }

        isProcessingPurchase = true
        defer { isProcessingPurchase = false }

        do {
            let purchaseResult = try await product.purchase()
            switch purchaseResult {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    return .failed(message: "Transazione non verificata da Apple.")
                }

                await transaction.finish()
                await refreshEntitlements()
                return hasSportPassAccess ? .success : .failed(message: "Acquisto completato ma accesso non attivo.")

            case .pending:
                return .pending

            case .userCancelled:
                return .cancelled

            @unknown default:
                return .failed(message: "Esito acquisto non supportato.")
            }
        } catch {
            return .failed(message: error.localizedDescription)
        }
    }

    func restorePurchases() async -> SportPassPurchaseResult {
        guard isProductIDConfigured else {
            return .notConfigured
        }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            return hasSportPassAccess ? .success : .notAvailable
        } catch {
            return .failed(message: error.localizedDescription)
        }
    }

    private var isProductIDConfigured: Bool {
        let productID = InAppPurchaseConfig.sportPassProductID.trimmingCharacters(in: .whitespacesAndNewlines)
        return !productID.isEmpty && !productID.contains("REPLACE_WITH_YOUR")
    }

    private func loadProduct() async {
        guard isProductIDConfigured else {
            sportPassProduct = nil
            return
        }

        isLoadingProduct = true
        defer { isLoadingProduct = false }

        do {
            let products = try await Product.products(for: [InAppPurchaseConfig.sportPassProductID])
            sportPassProduct = products.first
        } catch {
            sportPassProduct = nil
        }
    }

    private func refreshEntitlements() async {
        guard isProductIDConfigured else {
            hasSportPassAccess = false
            return
        }

        var hasAccess = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.productID == InAppPurchaseConfig.sportPassProductID else { continue }
            guard transaction.revocationDate == nil else { continue }

            if let expirationDate = transaction.expirationDate, expirationDate <= Date() {
                continue
            }

            hasAccess = true
            break
        }

        hasSportPassAccess = hasAccess
    }

    private func startTransactionUpdatesListener() {
        transactionUpdatesTask?.cancel()

        transactionUpdatesTask = Task.detached(priority: .background) { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                await self.handleTransactionUpdate(update)
            }
        }
    }

    private func handleTransactionUpdate(_ update: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = update else { return }
        guard transaction.productID == InAppPurchaseConfig.sportPassProductID else { return }

        await transaction.finish()
        await refreshEntitlements()
    }
}
