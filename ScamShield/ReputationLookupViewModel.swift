import Foundation
import Combine

@MainActor
final class ReputationLookupViewModel:
    ObservableObject {

    @Published private(set)
    var isLoading = false

    @Published private(set)
    var results:
        [URLReputationResult] = []

    @Published private(set)
    var didFinish = false

    @Published private(set)
    var errorMessage: String?

    private let service = ReputationService()

    func load(
        analyzedValue: String,
        checkType: ScamCheckType,
        forceRefresh: Bool = false
    ) async {
        isLoading = true
        didFinish = false
        errorMessage = nil
        results = []

        let urls = urlsToCheck(
            from: analyzedValue,
            checkType: checkType
        )

        guard !urls.isEmpty else {
            isLoading = false
            didFinish = true
            return
        }

        do {
            var loadedResults:
                [URLReputationResult] = []

            for url in urls.prefix(5) {
                try Task
                    .checkCancellation()

                let result =
                    try await service.check(
                        url,
                        ignoreCache:
                            forceRefresh
                    )

                loadedResults.append(result)
            }

            results = loadedResults
            isLoading = false
            didFinish = true
        } catch is CancellationError {
            isLoading = false
        } catch {
            errorMessage =
                error.localizedDescription

            isLoading = false
            didFinish = true
        }
    }

    private func urlsToCheck(
        from value: String,
        checkType: ScamCheckType
    ) -> [URL] {
        let analyzer =
            URLRiskAnalyzer()

        let urls: [URL]

        switch checkType {
        case .website:
            if let normalizedURL =
                analyzer
                    .analyze(value)
                    .normalizedURL {
                urls = [normalizedURL]
            } else {
                urls = []
            }

        case .message:
            urls = analyzer.extractURLs(
                from: value
            )

        case .phone:
            urls = []
        }

        var seenURLs =
            Set<String>()

        return urls.filter { url in
            let key = url.absoluteString
                .lowercased()

            return seenURLs
                .insert(key)
                .inserted
        }
    }
}
