import Foundation

enum ScamPatternType:
    String,
    CaseIterable,
    Identifiable {

    case bankPhishing
    case deliveryScam
    case prizeScam
    case governmentImpersonation
    case techSupportScam
    case investmentScam
    case jobScam
    case fakeInvoice
    case accountTakeover
    case giftCardScam
    case romanceScam
    case marketplaceScam
    case unknown

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .bankPhishing:
            return "Bank Phishing"

        case .deliveryScam:
            return "Delivery Scam"

        case .prizeScam:
            return "Prize or Lottery Scam"

        case .governmentImpersonation:
            return "Government Impersonation"

        case .techSupportScam:
            return "Tech Support Scam"

        case .investmentScam:
            return "Investment or Crypto Scam"

        case .jobScam:
            return "Job Scam"

        case .fakeInvoice:
            return "Fake Invoice"

        case .accountTakeover:
            return "Account Takeover Attempt"

        case .giftCardScam:
            return "Gift Card Scam"

        case .romanceScam:
            return "Romance Scam"

        case .marketplaceScam:
            return "Marketplace Scam"

        case .unknown:
            return "Unclassified Pattern"
        }
    }

    var summary: String {
        switch self {
        case .bankPhishing:
            return """
            The content may be impersonating a bank or financial institution to steal login or payment information.
            """

        case .deliveryScam:
            return """
            The content may be using a fake package, delivery, customs, or shipping problem to collect money or information.
            """

        case .prizeScam:
            return """
            The content may be promising an unexpected prize, lottery payment, reward, or inheritance.
            """

        case .governmentImpersonation:
            return """
            The sender may be impersonating a government agency or law-enforcement organization.
            """

        case .techSupportScam:
            return """
            The sender may be pretending to provide technical support and attempting to gain account or device access.
            """

        case .investmentScam:
            return """
            The content may be promoting an unrealistic investment or cryptocurrency opportunity.
            """

        case .jobScam:
            return """
            The content may be advertising a fake job or requesting money or sensitive information during recruitment.
            """

        case .fakeInvoice:
            return """
            The content may contain a fraudulent invoice, billing request, renewal notice, or payment demand.
            """

        case .accountTakeover:
            return """
            The sender may be attempting to obtain credentials or security codes to take control of an account.
            """

        case .giftCardScam:
            return """
            The sender may be requesting gift cards because these payments are difficult to reverse.
            """

        case .romanceScam:
            return """
            The content may involve emotional manipulation followed by requests for secrecy, money, or financial assistance.
            """

        case .marketplaceScam:
            return """
            The content may involve a fraudulent buyer, seller, payment confirmation, refund, or shipping arrangement.
            """

        case .unknown:
            return """
            The content contains warning signs, but it does not strongly match a supported scam category.
            """
        }
    }

    var systemImage: String {
        switch self {
        case .bankPhishing:
            return "building.columns.fill"

        case .deliveryScam:
            return "shippingbox.fill"

        case .prizeScam:
            return "gift.fill"

        case .governmentImpersonation:
            return "checkmark.seal.fill"

        case .techSupportScam:
            return "desktopcomputer.trianglebadge.exclamationmark"

        case .investmentScam:
            return "chart.line.uptrend.xyaxis"

        case .jobScam:
            return "briefcase.fill"

        case .fakeInvoice:
            return "doc.text.fill"

        case .accountTakeover:
            return "person.crop.circle.badge.exclamationmark"

        case .giftCardScam:
            return "giftcard.fill"

        case .romanceScam:
            return "heart.circle.fill"

        case .marketplaceScam:
            return "cart.fill"

        case .unknown:
            return "questionmark.shield.fill"
        }
    }
}

struct ScamPatternEvidence:
    Identifiable,
    Hashable {

    let id: UUID
    let title: String
    let weight: Int

    init(
        id: UUID = UUID(),
        title: String,
        weight: Int
    ) {
        self.id = id
        self.title = title
        self.weight = weight
    }
}

struct ScamPatternMatch:
    Identifiable {

    let id: UUID
    let type: ScamPatternType
    let confidence: Int
    let evidence: [ScamPatternEvidence]

    init(
        id: UUID = UUID(),
        type: ScamPatternType,
        confidence: Int,
        evidence: [ScamPatternEvidence]
    ) {
        self.id = id
        self.type = type
        self.confidence = min(
            max(confidence, 0),
            100
        )
        self.evidence = evidence
    }
}

struct ScamPatternAnalysis {
    let primaryMatch: ScamPatternMatch?
    let additionalMatches: [ScamPatternMatch]

    var hasPattern: Bool {
        primaryMatch != nil
    }
}
