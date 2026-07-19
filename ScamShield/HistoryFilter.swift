import Foundation

enum HistoryTypeFilter: String, CaseIterable, Identifiable {
    case all = "All Types"
    case message = "Message"
    case website = "Website"
    case phone = "Phone"

    var id: String {
        rawValue
    }

    var systemImage: String {
        switch self {
        case .all:
            return "square.grid.2x2"

        case .message:
            return "text.bubble.fill"

        case .website:
            return "link"

        case .phone:
            return "phone.fill"
        }
    }

    func matches(
        _ item: ScanHistoryItem
    ) -> Bool {
        switch self {
        case .all:
            return true

        case .message:
            return item.checkType == .message

        case .website:
            return item.checkType == .website

        case .phone:
            return item.checkType == .phone
        }
    }
}

enum HistoryRiskFilter: String, CaseIterable, Identifiable {
    case all = "All Risks"
    case low = "Low"
    case suspicious = "Suspicious"
    case high = "High"

    var id: String {
        rawValue
    }

    var systemImage: String {
        switch self {
        case .all:
            return "shield"

        case .low:
            return "checkmark.shield.fill"

        case .suspicious:
            return "exclamationmark.shield.fill"

        case .high:
            return "xmark.shield.fill"
        }
    }

    func matches(
        _ item: ScanHistoryItem
    ) -> Bool {
        switch self {
        case .all:
            return true

        case .low:
            return item.riskLevel == .low

        case .suspicious:
            return item.riskLevel == .suspicious

        case .high:
            return item.riskLevel == .high
        }
    }
}

enum HistorySortOrder: String, CaseIterable, Identifiable {
    case newest = "Newest First"
    case oldest = "Oldest First"
    case highestRisk = "Highest Risk"
    case lowestRisk = "Lowest Risk"

    var id: String {
        rawValue
    }

    var systemImage: String {
        switch self {
        case .newest:
            return "arrow.down"

        case .oldest:
            return "arrow.up"

        case .highestRisk:
            return "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90"

        case .lowestRisk:
            return "checkmark.arrow.trianglehead.counterclockwise"
        }
    }
}
