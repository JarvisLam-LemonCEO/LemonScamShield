import Foundation

actor ReputationCache {
    private struct CacheEntry {
        let result: URLReputationResult
        let expiresAt: Date
    }

    private var entries:
        [String: CacheEntry] = [:]

    private let lifetime:
        TimeInterval

    init(
        lifetime: TimeInterval = 15 * 60
    ) {
        self.lifetime = lifetime
    }

    func result(
        for url: URL
    ) -> URLReputationResult? {
        removeExpiredEntries()

        let key = cacheKey(for: url)

        guard let entry = entries[key] else {
            return nil
        }

        return entry.result
    }

    func store(
        _ result: URLReputationResult,
        for url: URL
    ) {
        let key = cacheKey(for: url)

        entries[key] = CacheEntry(
            result: result,
            expiresAt:
                Date().addingTimeInterval(
                    lifetime
                )
        )
    }

    func removeAll() {
        entries.removeAll()
    }

    private func removeExpiredEntries() {
        let now = Date()

        entries = entries.filter {
            _, entry in

            entry.expiresAt > now
        }
    }

    private func cacheKey(
        for url: URL
    ) -> String {
        url.absoluteString
            .lowercased()
            .trimmingCharacters(
                in: CharacterSet(
                    charactersIn: "/"
                )
            )
    }
}
