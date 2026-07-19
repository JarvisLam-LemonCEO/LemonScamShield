import Foundation
import CoreGraphics

enum ScreenshotHighlightCategory:
    String,
    Identifiable,
    CaseIterable {

    case urgency
    case credentials
    case payment
    case threat
    case link
    case prize
    case impersonation

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .urgency:
            return "Urgency"

        case .credentials:
            return "Sensitive information"

        case .payment:
            return "Payment request"

        case .threat:
            return "Threat or pressure"

        case .link:
            return "Suspicious link"

        case .prize:
            return "Prize claim"

        case .impersonation:
            return "Possible impersonation"
        }
    }
}

struct RecognizedTextRegion {
    let text: String
    let boundingBox: CGRect
}

struct ScreenshotHighlight {
    let text: String
    let category: ScreenshotHighlightCategory
    let boundingBox: CGRect
}
