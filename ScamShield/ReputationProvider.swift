import Foundation

protocol URLReputationProviding:
    Sendable {

    func checkReputation(
        for url: URL
    ) async throws -> URLReputationResult
}

enum ReputationLookupError:
    LocalizedError {

    case invalidURL
    case unavailable
    case invalidResponse
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return """
            The website address could not be prepared for a reputation check.
            """

        case .unavailable:
            return """
            The reputation service is temporarily unavailable.
            """

        case .invalidResponse:
            return """
            The reputation service returned an invalid response.
            """

        case .requestFailed(let message):
            return """
            The reputation lookup failed: \(message)
            """
        }
    }
}
