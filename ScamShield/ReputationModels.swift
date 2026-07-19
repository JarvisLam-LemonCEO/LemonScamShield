import Foundation

enum URLReputationVerdict:
    String,
    Codable,
    Sendable {

    case safe
    case unknown
    case suspicious
    case malicious

    var title: String {
        switch self {
        case .safe:
            return "No Known Threats"

        case .unknown:
            return "No Reputation Data"

        case .suspicious:
            return "Suspicious Reputation"

        case .malicious:
            return "Known Malicious"
        }
    }

    var riskScoreAdjustment: Int {
        switch self {
        case .safe:
            return 0

        case .unknown:
            return 0

        case .suspicious:
            return 25

        case .malicious:
            return 60
        }
    }
}

struct URLReputationFinding:
    Identifiable,
    Codable,
    Hashable,
    Sendable {

    let id: UUID
    let title: String
    let detail: String

    init(
        id: UUID = UUID(),
        title: String,
        detail: String
    ) {
        self.id = id
        self.title = title
        self.detail = detail
    }
}

struct URLReputationResult:
    Identifiable,
    Codable,
    Hashable,
    Sendable {

    let id: UUID
    let urlString: String
    let host: String
    let verdict: URLReputationVerdict
    let confidence: Int
    let providerName: String
    let findings: [URLReputationFinding]
    let reportCount: Int?
    let lastReportedAt: Date?
    let checkedAt: Date

    init(
        id: UUID = UUID(),
        urlString: String,
        host: String,
        verdict: URLReputationVerdict,
        confidence: Int,
        providerName: String,
        findings: [URLReputationFinding],
        reportCount: Int? = nil,
        lastReportedAt: Date? = nil,
        checkedAt: Date = Date()
    ) {
        self.id = id
        self.urlString = urlString
        self.host = host
        self.verdict = verdict
        self.confidence = min(
            max(confidence, 0),
            100
        )
        self.providerName = providerName
        self.findings = findings
        self.reportCount = reportCount
        self.lastReportedAt = lastReportedAt
        self.checkedAt = checkedAt
    }
}
