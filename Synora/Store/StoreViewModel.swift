//
//  StoreViewModel.swift
//  Synora
//
//  Created by Tufan Cakir on 26.04.26.
//

import Combine
import Foundation
import StoreKit

@MainActor
final class StoreViewModel: ObservableObject {

    @Published private(set) var configuration: StoreConfiguration
    @Published private(set) var productsByID: [String: Product] = [:]
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var coinBalance: Int
    @Published private(set) var bonusLimits: UsageLimits
    @Published private(set) var statusMessage = ""
    @Published private(set) var isLoading = false

    private let defaults: UserDefaults
    private var updatesTask: Task<Void, Never>? = nil

    private enum StorageKey {
        static let coinBalance = "store.coinBalance"
        static let bonusTabs = "store.bonusTabs"
        static let bonusNotes = "store.bonusNotes"
        static let bonusStorageMegabytes = "store.bonusStorageMegabytes"
        static let bonusInboxItems = "store.bonusInboxItems"
    }

    init(
        configuration: StoreConfiguration? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.configuration = configuration ?? StoreConfiguration.load()
        self.defaults = defaults
        coinBalance = defaults.integer(forKey: StorageKey.coinBalance)
        bonusLimits = UsageLimits(
            tabs: defaults.integer(forKey: StorageKey.bonusTabs),
            notes: defaults.integer(forKey: StorageKey.bonusNotes),
            storageMegabytes: defaults.integer(
                forKey: StorageKey.bonusStorageMegabytes
            ),
            inboxItems: defaults.integer(forKey: StorageKey.bonusInboxItems)
        )

        updatesTask = Task { [weak self] in
            await self?.listenForTransactionUpdates()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    var hasLifetimeAccess: Bool {
        purchasedProductIDs.contains { productID in
            definition(for: productID)?.kind == .nonConsumable
        }
    }

    var effectiveLimits: UsageLimits {
        if hasLifetimeAccess {
            return .unlimited
        }

        let planLimits = purchasedProductIDs.reduce(
            configuration.freeLimits
        ) { limits, productID in
            guard
                let definition = definition(for: productID),
                definition.kind == .subscription,
                let productLimits = definition.limits
            else {
                return limits
            }

            return limits.adding(productLimits)
        }

        return planLimits.adding(bonusLimits)
    }

    var tabLimitText: String {
        limitText(effectiveLimits.tabs)
    }

    var noteLimitText: String {
        limitText(effectiveLimits.notes)
    }

    var storageLimitText: String {
        effectiveLimits.storageMegabytes == Int.max
            ? "Unlimited" : "\(effectiveLimits.storageMegabytes) MB"
    }

    var inboxLimitText: String {
        limitText(effectiveLimits.inboxItems)
    }

    func loadProducts() async {
        let productIDs = configuration.products.compactMap(\.productID)
        guard !productIDs.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let products = try await Product.products(for: productIDs)
            productsByID = Dictionary(
                uniqueKeysWithValues: products.map { ($0.id, $0) }
            )
            await refreshPurchasedProducts()
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func priceText(for definition: StoreProductDefinition) -> String {
        guard let productID = definition.productID else {
            return "Free"
        }

        return productsByID[productID]?.displayPrice ?? "App Store"
    }

    func canCreateTab(currentTabs: Int) -> Bool {
        currentTabs < effectiveLimits.tabs
    }

    func canCreateNote(currentNotes: Int, currentStorageMegabytes: Int) -> Bool
    {
        currentNotes < effectiveLimits.notes
            && currentStorageMegabytes <= effectiveLimits.storageMegabytes
    }

    func canStore(storageMegabytes: Int) -> Bool {
        storageMegabytes <= effectiveLimits.storageMegabytes
    }

    func statusText(
        tabCount: Int,
        noteCount: Int,
        storageMegabytes: Int
    ) -> String {
        let storageText =
            effectiveLimits.storageMegabytes == Int.max
            ? "\(storageMegabytes) MB"
            : "\(storageMegabytes)/\(effectiveLimits.storageMegabytes) MB"
        return
            "\(tabCount)/\(tabLimitText) Tabs · \(noteCount)/\(noteLimitText) Notes · \(storageText)"
    }

    func limitTitle(language: AppLanguage) -> String {
        switch language {
        case .german: return "Limit erreicht"
        case .english: return "Limit reached"
        }
    }

    func limitMessage(
        for resource: SynoraLimitResource,
        language: AppLanguage
    ) -> String {
        switch language {
        case .german:
            return
                "\(resource.germanTitle)-Limit erreicht. Kaufe Coins oder wechsle auf Pro, Ultimate oder Lifetime."
        case .english:
            return
                "\(resource.englishTitle) limit reached. Buy coins or upgrade to Pro, Ultimate, or Lifetime."
        }
    }

    func purchase(_ definition: StoreProductDefinition) async {
        guard let productID = definition.productID else { return }
        guard let product = productsByID[productID] else {
            statusMessage = "Product not available."
            return
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await applyPurchase(definition, transaction: transaction)
                await transaction.finish()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshPurchasedProducts()
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func listenForTransactionUpdates() async {
        for await result in Transaction.updates {
            do {
                let transaction = try checkVerified(result)

                if let definition = definition(for: transaction.productID) {
                    await applyPurchase(definition, transaction: transaction)
                }

                await transaction.finish()
                await refreshPurchasedProducts()
            } catch {
                print("Transaction update verification failed: \(error)")
            }
        }
    }

    private func refreshPurchasedProducts() async {
        var purchasedIDs: Set<String> = []

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else {
                continue
            }

            purchasedIDs.insert(transaction.productID)
        }

        purchasedProductIDs = purchasedIDs
    }

    private func applyPurchase(
        _ definition: StoreProductDefinition,
        transaction: StoreKit.Transaction
    ) async {
        switch definition.kind {
        case .free:
            break
        case .subscription, .nonConsumable:
            purchasedProductIDs.insert(transaction.productID)
        case .consumable:
            coinBalance += definition.coinAmount ?? 0
            defaults.set(coinBalance, forKey: StorageKey.coinBalance)
            applyBonusLimits(for: definition.coinAmount ?? 0)
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let signedType):
            return signedType
        }
    }

    private func definition(for productID: String) -> StoreProductDefinition? {
        configuration.products.first { $0.productID == productID }
    }

    private func applyBonusLimits(for coins: Int) {
        guard coins > 0 else { return }

        let addedLimits = UsageLimits(
            tabs: coins / max(configuration.coinCosts.tab, 1),
            notes: coins / max(configuration.coinCosts.note, 1),
            storageMegabytes: coins
                / max(
                    configuration.coinCosts.storageMegabyte,
                    1
                ),
            inboxItems: coins / max(configuration.coinCosts.inboxItem, 1)
        )

        bonusLimits = bonusLimits.adding(addedLimits)
        defaults.set(bonusLimits.tabs, forKey: StorageKey.bonusTabs)
        defaults.set(bonusLimits.notes, forKey: StorageKey.bonusNotes)
        defaults.set(
            bonusLimits.storageMegabytes,
            forKey: StorageKey.bonusStorageMegabytes
        )
        defaults.set(bonusLimits.inboxItems, forKey: StorageKey.bonusInboxItems)
    }

    private func limitText(_ limit: Int) -> String {
        limit == Int.max ? "Unlimited" : "\(limit)"
    }
}

enum SynoraLimitResource {
    case tabs
    case notes
    case storage
    case inbox

    var germanTitle: String {
        switch self {
        case .tabs: return "Tab"
        case .notes: return "Notiz"
        case .storage: return "Speicher"
        case .inbox: return "Inbox"
        }
    }

    var englishTitle: String {
        switch self {
        case .tabs: return "Tab"
        case .notes: return "Note"
        case .storage: return "Storage"
        case .inbox: return "Inbox"
        }
    }
}

enum StoreError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "The App Store transaction could not be verified."
        }
    }
}
