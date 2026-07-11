//
//  SubscriptionView.swift
//  Synora
//
//  Created by Tufan Cakir on 26.04.26.
//

import StoreKit
import SwiftUI

struct SubscriptionView: View {

    @EnvironmentObject private var storeViewModel: StoreViewModel

    let language: AppLanguage
    let theme: AppTheme
    let tabCount: Int
    let noteCount: Int
    let storageMegabytesUsed: Int

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    usageSummary

                    if !subscriptionProductIDs.isEmpty {
                        appleSubscriptionStore
                    }

                    if !nonSubscriptionProductIDs.isEmpty {
                        appleProductStore
                    }

                    if !storeViewModel.statusMessage.isEmpty {
                        Text(storeViewModel.statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(language == .german ? "Wiederherstellen" : "Restore")
                    {
                        Task {
                            await storeViewModel.restorePurchases()
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .preferredColorScheme(resolvedColorScheme)
        }
        .task {
            await storeViewModel.loadProducts()
        }
    }

    private var resolvedColorScheme: ColorScheme? {
        theme.colorScheme
    }

    private var subscriptionProductIDs: [String] {
        storeViewModel.configuration.products.compactMap { definition in
            definition.kind == .subscription ? definition.productID : nil
        }
    }

    private var nonSubscriptionProductIDs: [String] {
        storeViewModel.configuration.products.compactMap { definition in
            definition.kind != .subscription && definition.kind != .free
                ? definition.productID
                : nil
        }
    }

    private var usageSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                CoinStackSymbol()
                    .frame(width: 24, height: 24)

                Text("Coins")
                    .font(.headline)

                Spacer()

                Text("\(storeViewModel.coinBalance)")
                    .font(.title3.weight(.semibold))
            }

            Text(
                storeViewModel.statusText(
                    tabCount: tabCount,
                    noteCount: noteCount,
                    storageMegabytes: storageMegabytesUsed
                )
            )
            .font(.footnote)
            .foregroundStyle(.secondary)

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ],
                spacing: 12
            ) {
                usagePill(
                    title: language == .german ? "Tabs" : "Tabs",
                    value: storeViewModel.tabLimitText
                )
                usagePill(
                    title: language == .german ? "Notizen" : "Notes",
                    value: storeViewModel.noteLimitText
                )
                usagePill(
                    title: language == .german ? "Speicher" : "Storage",
                    value: storeViewModel.storageLimitText
                )
                usagePill(
                    title: "Inbox",
                    value: storeViewModel.inboxLimitText
                )
            }
        }
        .padding(12)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 8)
        )
    }

    private func usagePill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var appleSubscriptionStore: some View {
        if let privacyPolicyURL = LegalLinks.privacyPolicyURL,
            let termsURL = LegalLinks.termsURL
        {
            subscriptionStoreContent
                .subscriptionStorePolicyDestination(
                    url: privacyPolicyURL,
                    for: .privacyPolicy
                )
                .subscriptionStorePolicyDestination(
                    url: termsURL,
                    for: .termsOfService
                )
                .subscriptionStorePolicyForegroundStyle(.primary, .secondary)
        } else {
            subscriptionStoreContent
        }
    }

    private var subscriptionStoreContent: some View {
        SubscriptionStoreView(productIDs: subscriptionProductIDs)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 8)
            )
    }

    private var appleProductStore: some View {
        StoreView(ids: nonSubscriptionProductIDs)
            .storeButton(.visible, for: .restorePurchases)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 8)
            )
    }
}

#Preview {
    SubscriptionView(
        language: .german,
        theme: .system,
        tabCount: 2,
        noteCount: 4,
        storageMegabytesUsed: 1
    )
    .environmentObject(StoreViewModel(configuration: .fallback))
}
