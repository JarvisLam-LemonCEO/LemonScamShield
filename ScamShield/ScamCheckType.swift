import Foundation

enum ScamCheckType: String, CaseIterable, Identifiable {
    case message = "Message"
    case website = "Website"
    case phone = "Phone"

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .message:
            return "Check a suspicious message"

        case .website:
            return "Check a suspicious website"

        case .phone:
            return "Check a suspicious phone number"
        }
    }

    var description: String {
        switch self {
        case .message:
            return """
            Paste a suspicious text message, email, or voicemail transcript.
            """

        case .website:
            return """
            Paste the complete website address you want to check.
            """

        case .phone:
            return """
            Enter the phone number that called or messaged you.
            """
        }
    }

    var placeholder: String {
        switch self {
        case .message:
            return """
            Example: Your bank account has been suspended. Click this link immediately to verify your password...
            """

        case .website:
            return "Example: https://example.com/account-login"

        case .phone:
            return "Example: +1 (555) 123-4567"
        }
    }

    var inputLabel: String {
        switch self {
        case .message:
            return "Message"

        case .website:
            return "Website address"

        case .phone:
            return "Phone number"
        }
    }

    var buttonTitle: String {
        switch self {
        case .message:
            return "Analyze Message"

        case .website:
            return "Analyze Website"

        case .phone:
            return "Analyze Phone Number"
        }
    }

    var systemImage: String {
        switch self {
        case .message:
            return "text.bubble.fill"

        case .website:
            return "link"

        case .phone:
            return "phone.fill"
        }
    }
}
