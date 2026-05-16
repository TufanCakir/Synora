//
//  BundleJSONLoader.swift
//  Synora
//
//  Created by Tufan Cakir on 16.05.26.
//

import Foundation

enum BundleJSONLoader {
    static func load<T: Decodable>(_ type: T.Type, resource: String) -> T? {
        guard
            let url = Bundle.main.url(
                forResource: resource,
                withExtension: "json"
            )
        else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            assertionFailure(
                "Could not decode bundled JSON resource \(resource).json: \(error.localizedDescription)"
            )
            return nil
        }
    }
}
