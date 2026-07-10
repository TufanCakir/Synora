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

                    subscriptionDisclosure

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

            productRequiredInformation(for: definition)

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

    private func productRequiredInformation(
        for definition: StoreProductDefinition
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            requiredInfoRow(
                title: language == .german ? "Preis" : "Price",
                value: storeViewModel.priceText(for: definition)
            )

            requiredInfoRow(
                title: language == .german ? "Laufzeit" : "Duration",
                value: durationText(for: definition)
            )

            if definition.kind == .subscription {
                Text(includedDuringSubscriptionText(for: definition))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 2)
    }

    private func requiredInfoRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("\(title):")
                .font(.caption.weight(.semibold))
            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func durationText(for definition: StoreProductDefinition) -> String
    {
        switch definition.kind {
        case .free:
            return language == .german ? "Kostenlos" : "Free"
        case .subscription:
            if definition.id.contains("monthly") {
                return language == .german
                    ? "Monatlich, automatisch verlängerbar"
                    : "Monthly, auto-renewing"
            }
            return language == .german
                ? "Automatisch verlängerbar"
                : "Auto-renewing"
        case .nonConsumable:
            return language == .german ? "Einmaliger Kauf" : "One-time purchase"
        case .consumable:
            return language == .german
                ? "Einmaliges Coin-Paket" : "One-time coin pack"
        }
    }

    private func includedDuringSubscriptionText(
        for definition: StoreProductDefinition
    ) -> String {
        let benefits = definition.localizedBenefits(
            languageID: language.rawValue,
            fallbackLanguageID: AppLanguage.english.rawValue
        )
        .joined(separator: ", ")

        if language == .german {
            return "Enthalten während jedes Abo-Zeitraums: \(benefits)."
        }

        return "Included during each subscription period: \(benefits)."
    }

    private var subscriptionDisclosure: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(language == .german ? "Abo-Hinweise" : "Subscription details")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                disclosureRow(
                    language == .german
                        ? "Synora Pro und Synora Ultimate sind monatliche, automatisch verlängerbare Abos."
                        : "Synora Pro and Synora Ultimate are monthly auto-renewing subscriptions."
                )
                disclosureRow(
                    language == .german
                        ? "Während jedes bezahlten Monats gelten die oben angezeigten Limits und Leistungen."
                        : "During each paid month, the limits and benefits shown above are available."
                )
                disclosureRow(
                    language == .german
                        ? "Der Preis wird vor dem Kauf angezeigt. Abos verlängern sich automatisch, bis sie gekündigt werden."
                        : "The price is shown before purchase. Subscriptions renew automatically until canceled."
                )
                disclosureRow(
                    language == .german
                        ? "Abos können nach dem Kauf in den Kontoeinstellungen verwaltet und gekündigt werden."
                        : "Subscriptions can be managed and canceled in account settings after purchase."
                )
            }

            HStack(spacing: 16) {
                if let privacyPolicyURL = LegalLinks.privacyPolicyURL {
                    Link(
                        language == .german
                            ? "Datenschutzerklärung" : "Privacy Policy",
                        destination: privacyPolicyURL
                    )
                }

                if let termsURL = LegalLinks.termsURL {
                    Link(
                        language == .german
                            ? "Nutzungsbedingungen" : "Terms of Use",
                        destination: termsURL
                    )
                }
            }
            .font(.footnote)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(12)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 8)
        )
    }

    private func disclosureRow(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle")
            .fixedSize(horizontal: false, vertical: true)
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
