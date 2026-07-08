//
//  StoreConfiguration.swift
//  Synora
//
//  Created by Tufan Cakir on 26.04.26.
//

import Foundation

struct StoreConfiguration: Decodable {

    let freeLimits: UsageLimits
    let coinCosts: CoinCosts
    let products: [StoreProductDefinition]

    static let fallback = StoreConfiguration(
        freeLimits: UsageLimits(
            tabs: 5,
            notes: 5,
            storageMegabytes: 5,
            inboxItems: 5
        ),
        coinCosts: CoinCosts(tab: 5, note: 1, storageMegabyte: 2, inboxItem: 1),
        products: []
    )

    static func load() -> StoreConfiguration {
        guard
            let url = Bundle.main.url(
                forResource: "StoreConfiguration",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let configuration = try? JSONDecoder().decode(
                StoreConfiguration.self,
                from: data
            )
        else {
            return fallback
        }

        return configuration
    }
}

struct UsageLimits: Decodable, Hashable {
    let tabs: Int
    let notes: Int
    let storageMegabytes: Int
    let inboxItems: Int

    static let unlimited = UsageLimits(
        tabs: Int.max,
        notes: Int.max,
        storageMegabytes: Int.max,
        inboxItems: Int.max
    )

    func adding(_ other: UsageLimits) -> UsageLimits {
        UsageLimits(
            tabs: cappedSum(tabs, other.tabs),
            notes: cappedSum(notes, other.notes),
            storageMegabytes: cappedSum(
                storageMegabytes,
                other.storageMegabytes
            ),
            inboxItems: cappedSum(inboxItems, other.inboxItems)
        )
    }

    private func cappedSum(_ lhs: Int, _ rhs: Int) -> Int {
        if lhs == Int.max || rhs == Int.max {
            return Int.max
        }

        return lhs.addingReportingOverflow(rhs).overflow ? Int.max : lhs + rhs
    }
}

struct CoinCosts: Decodable, Hashable {
    let tab: Int
    let note: Int
    let storageMegabyte: Int
    let inboxItem: Int
}

struct StoreProductDefinition: Decodable, Identifiable, Hashable {
    let id: String
    let kind: StoreProductKind
    let productID: String?
    let coinAmount: Int?
    let limits: UsageLimits?
    let displayNames: [String: String]
    let subtitles: [String: String]
    let benefits: [String: [String]]

    func displayName(languageID: String, fallbackLanguageID: String) -> String {
        displayNames[languageID] ?? displayNames[fallbackLanguageID] ?? id
    }

    func subtitle(languageID: String, fallbackLanguageID: String) -> String {
        subtitles[languageID] ?? subtitles[fallbackLanguageID] ?? ""
    }

    func localizedBenefits(languageID: String, fallbackLanguageID: String)
        -> [String]
    {
        benefits[languageID] ?? benefits[fallbackLanguageID] ?? []
    }
}

enum StoreProductKind: String, Decodable {
    case free
    case subscription
    case nonConsumable
    case consumable
}
