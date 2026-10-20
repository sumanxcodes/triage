import Foundation
import StoreKit

/// Product identifiers for Triage subscriptions
public enum TriageProductID {
    public static let monthlyPro = "com.sumanxcodes.triage.pro.monthly"
    public static let annualPro = "com.sumanxcodes.triage.pro.annual"

    public static let all: [String] = [monthlyPro, annualPro]
}

/// StoreKit 2 subscription management and receipt verification engine
@MainActor
public final class SubscriptionManager: ObservableObject {
    public static let shared = SubscriptionManager()

    @Published public private(set) var products: [Product] = []
    @Published public private(set) var purchasedProductIDs: Set<String> = []
    @Published public private(set) var isProUser: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var isPurchasing: Bool = false
    @Published public var errorMessage: String?

    private var updateListenerTask: Task<Void, Never>?

    private init() {
        // Start listening for out-of-band transaction updates (renewals, revocations, family sharing)
        updateListenerTask = listenForTransactions()

        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Transaction Listener

    /// Listens for background transaction updates from StoreKit 2
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("[StoreKit] Transaction verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Product Catalog

    /// Loads available in-app subscription products from StoreKit
    public func requestProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let loadedProducts = try await Product.products(for: TriageProductID.all)
            // Sort by annual first (best value) then monthly
            self.products = loadedProducts.sorted { $0.id == TriageProductID.annualPro && $1.id != TriageProductID.annualPro }
            isLoading = false
        } catch {
            self.errorMessage = "Failed to load subscription options: \(error.localizedDescription)"
            self.isLoading = false
        }
    }

    // MARK: - Purchase Flow

    /// Purchases the specified StoreKit 2 product with cryptographic receipt verification
    @discardableResult
    public func purchase(_ product: Product) async throws -> Transaction? {
        isPurchasing = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateCustomerProductStatus()
                await transaction.finish()
                isPurchasing = false
                return transaction

            case .userCancelled:
                isPurchasing = false
                return nil

            case .pending:
                isPurchasing = false
                return nil

            @unknown default:
                isPurchasing = false
                return nil
            }
        } catch {
            isPurchasing = false
            self.errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Restore Purchases

    /// Syncs with App Store to restore previously purchased active subscriptions
    public func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await updateCustomerProductStatus()
            isLoading = false
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Entitlement Verification

    /// Updates the active entitlements by iterating through verified current transactions
    public func updateCustomerProductStatus() async {
        var activeIDs = Set<String>()

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if transaction.revocationDate == nil {
                    activeIDs.insert(transaction.productID)
                }
            } catch {
                print("[StoreKit] Entitlement verification failed: \(error)")
            }
        }

        self.purchasedProductIDs = activeIDs
        self.isProUser = !activeIDs.isEmpty
    }

    /// Verifies the cryptographic signature of a StoreKit transaction
    public func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
