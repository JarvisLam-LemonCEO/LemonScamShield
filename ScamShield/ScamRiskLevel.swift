import SwiftUI

enum ScamRiskLevel: String, Equatable {
    case low
    case suspicious
    case high

    init(storageValue: String) {
        self = ScamRiskLevel(
            rawValue: storageValue
        ) ?? .low
    }

    var storageValue: String {
        rawValue
    }

    var title: String {
        switch self {
        case .low:
            return "Low Risk"

        case .suspicious:
            return "Suspicious"

        case .high:
            return "High Scam Risk"
        }
    }

    var shortTitle: String {
        switch self {
        case .low:
            return "Low"

        case .suspicious:
            return "Suspicious"

        case .high:
            return "High"
        }
    }

    var iconName: String {
        switch self {
        case .low:
            return "checkmark.shield.fill"

        case .suspicious:
            return "exclamationmark.shield.fill"

        case .high:
            return "xmark.shield.fill"
        }
    }

    var color: Color {
        switch self {
        case .low:
            return .green

        case .suspicious:
            return .orange

        case .high:
            return .red
        }
    }
}
