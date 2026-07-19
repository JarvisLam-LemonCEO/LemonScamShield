import Foundation

enum RiskScoreCategory:
    String,
    CaseIterable,
    Identifiable {

    case scamPattern
    case suspiciousURL
    case credentials
    case payment
    case urgency
    case threat
    case brandImpersonation
    case secrecy
    case remoteAccess
    case phoneRisk

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .scamPattern:
            return "Scam pattern"

        case .suspiciousURL:
            return "Suspicious website"

        case .credentials:
            return "Sensitive information"

        case .payment:
            return "Payment request"

        case .urgency:
            return "Urgency and pressure"

        case .threat:
            return "Threat or fear"

        case .brandImpersonation:
            return "Brand impersonation"

        case .secrecy:
            return "Secrecy request"

        case .remoteAccess:
            return "Remote device access"

        case .phoneRisk:
            return "Phone-number risk"
        }
    }

    var systemImage: String {
        switch self {
        case .scamPattern:
            return "point.3.connected.trianglepath.dotted"

        case .suspiciousURL:
            return "link.badge.plus"

        case .credentials:
            return "key.fill"

        case .payment:
            return "creditcard.fill"

        case .urgency:
            return "clock.badge.exclamationmark.fill"

        case .threat:
            return "exclamationmark.triangle.fill"

        case .brandImpersonation:
            return "building.2.crop.circle.fill"

        case .secrecy:
            return "eye.slash.fill"

        case .remoteAccess:
            return "desktopcomputer.trianglebadge.exclamationmark"

        case .phoneRisk:
            return "phone.badge.waveform.fill"
        }
    }
}

struct RiskScoreContribution:
    Identifiable,
    Hashable {

    let id: UUID
    let category: RiskScoreCategory
    let points: Int
    let maximumPoints: Int
    let explanation: String

    init(
        id: UUID = UUID(),
        category: RiskScoreCategory,
        points: Int,
        maximumPoints: Int,
        explanation: String
    ) {
        self.id = id
        self.category = category
        self.points = max(
            0,
            min(points, maximumPoints)
        )
        self.maximumPoints = maximumPoints
        self.explanation = explanation
    }

    var percentage: Double {
        guard maximumPoints > 0 else {
            return 0
        }

        return Double(points)
            / Double(maximumPoints)
    }
}

struct RiskScoreBreakdown {
    let totalScore: Int
    let rawScore: Int
    let contributions: [RiskScoreContribution]

    var activeContributions: [RiskScoreContribution] {
        contributions.filter {
            $0.points > 0
        }
    }

    var riskLabel: String {
        switch totalScore {
        case 0..<20:
            return "Low"

        case 20..<45:
            return "Caution"

        case 45..<70:
            return "Suspicious"

        default:
            return "High"
        }
    }
}
