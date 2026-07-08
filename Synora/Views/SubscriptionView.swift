//
//  SubscriptionView.swift
//  Synora
//
//  Created by Tufan Cakir on 26.04.26.
//

import SwiftUI

struct SubscriptionView: View {

    @EnvironmentObject private var storeViewModel: StoreViewModel

    @Environment(\.colorScheme) private var systemColorScheme

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

                    ForEach(storeViewModel.configuration.products) {
                        definition in
                        productCard(for: definition)
                    }

                    if !storeViewModel.statusMessage.isEmpty {
                        Text(storeViewModel.statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Synora Pro")
            .navigationBarTitleDisplayMode(.inline)
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

    private var isCurrentlyDark: Bool {
        if let explicit = resolvedColorScheme {
            return explicit == .dark
        }
        return systemColorScheme == .dark
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

    private func productCard(for definition: StoreProductDefinition)
        -> some View
    {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        definition.displayName(
                            languageID: language.rawValue,
                            fallbackLanguageID: AppLanguage.english.rawValue
                        )
                    )
                    .font(.headline)

                    Text(
                        definition.subtitle(
                            languageID: language.rawValue,
                            fallbackLanguageID: AppLanguage.english.rawValue
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Text(storeViewModel.priceText(for: definition))
                    .font(.subheadline.weight(.semibold))
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(
                    definition.localizedBenefits(
                        languageID: language.rawValue,
                        fallbackLanguageID: AppLanguage.english.rawValue
                    ),
                    id: \.self
                ) { benefit in
                    Label(benefit, systemImage: "checkmark.circle")
                        .font(.caption)
                }
            }

            if definition.kind != .free {
                Button {
                    Task {
                        await storeViewModel.purchase(definition)
                    }
                } label: {
                    Label {
                        Text(
                            definition.kind == .consumable
                                ? (language == .german
                                    ? "Coins kaufen" : "Buy Coins")
                                : (language == .german
                                    ? "Freischalten" : "Unlock")
                        )
                        .foregroundStyle(isCurrentlyDark ? .black : .white)
                    } icon: {
                        if definition.kind == .consumable {
                            CoinStackSymbol()
                                .frame(width: 18, height: 18)
                        } else {
                            Image(systemName: "lock.open")
                                .foregroundStyle(
                                    isCurrentlyDark ? .black : .white
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.primary)
            }
        }
        .padding(12)
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
