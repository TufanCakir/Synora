//
//  InfoContent.swift
//  Synora
//
//  Created by Tufan Cakir on 18.12.25.
//

import Foundation

struct InfoContent: Decodable {
    let title: String
    let subtitle: String
    let sections: [InfoSection]
}

struct InfoSection: Decodable, Identifiable {
    let title: String
    let text: String

    var id: String {
        title
    }
}

extension Bundle {
    func loadInfo(language: String) -> InfoContent {
        if let cached = InfoContentCache.values[language] {
            return cached
        }

        let files = ["info_\(language)", "info_en"]

        for file in files {
            if let url = url(forResource: file, withExtension: "json"),
                let data = try? Data(contentsOf: url),
                let decoded = try? JSONDecoder().decode(
                    InfoContent.self,
                    from: data
                )
            {
                InfoContentCache.values[language] = decoded
                return decoded
            }
        }

        fatalError("❌ Missing info JSON files")
    }
}

private enum InfoContentCache {
    static var values: [String: InfoContent] = [:]
}
