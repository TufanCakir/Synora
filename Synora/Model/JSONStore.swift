//
//  JSONStore.swift
//  Synora
//
//  Created by Tufan Cakir on 16.05.26.
//

import Foundation

struct JSONStore<Value: Codable> {

    let fileName: String
    let defaultValue: Value

    private var fileURL: URL {
        let baseURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        let folderURL = baseURL.appendingPathComponent(
            "Synora",
            isDirectory: true
        )
        try? FileManager.default.createDirectory(
            at: folderURL,
            withIntermediateDirectories: true
        )
        return folderURL.appendingPathComponent(fileName)
    }

    func load() -> Value {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(Value.self, from: data)
        } catch {
            save(defaultValue)
            return defaultValue
        }
    }

    func save(_ value: Value) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(value)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            assertionFailure(
                "Could not save JSON file: \(error.localizedDescription)"
            )
        }
    }
}
