import Foundation

struct SafetyArticle: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let systemImage: String
    let steps: [String]
    let warning: String?
}

extension SafetyArticle {
    static let immediateActions = SafetyArticle(
        title: "What to do immediately",
        summary: "Stop contact and protect your accounts before taking any other action.",
        systemImage: "hand.raised.fill",
        steps: [
            "Do not reply to the sender or caller.",
            "Do not open links or download attachments.",
            "Do not send money, gift cards, cryptocurrency, or verification codes.",
            "Take screenshots and preserve the original message.",
            "Block the sender or phone number after saving evidence.",
            "Contact the claimed company using its official app, website, card, or statement."
        ],
        warning: """
        Do not use a phone number or website address supplied inside the suspicious message.
        """
    )

    static let verifySender = SafetyArticle(
        title: "Verify the sender safely",
        summary: "Use an independent contact method instead of information supplied by the sender.",
        systemImage: "person.crop.circle.badge.questionmark",
        steps: [
            "Open the organization’s official app directly.",
            "Enter the official website address yourself.",
            "Use the phone number printed on the back of your bank or credit card.",
            "Use a phone number from a trusted statement or official government website.",
            "Ask the organization whether the message, invoice, or call was genuine.",
            "For requests from friends or relatives, contact them using a number you already know."
        ],
        warning: """
        Caller ID, email display names, and text-message sender names can be spoofed.
        """
    )

    static let sensitiveInformation = SafetyArticle(
        title: "Never share these details",
        summary: "Legitimate organizations should not unexpectedly request highly sensitive credentials.",
        systemImage: "lock.shield.fill",
        steps: [
            "Passwords or password-reset links.",
            "One-time verification or security codes.",
            "Credit card or debit card PINs.",
            "Complete Social Security or national identification numbers.",
            "Online banking usernames or passwords.",
            "Cryptocurrency wallet recovery phrases.",
            "Remote access to your phone or computer.",
            "Photos of identity documents unless you initiated a verified process."
        ],
        warning: """
        A verification code can allow a criminal to take control of an account even when they do not know your password.
        """
    )

    static let paymentScams = SafetyArticle(
        title: "Suspicious payment methods",
        summary: "Scammers often prefer payments that are difficult or impossible to reverse.",
        systemImage: "creditcard.trianglebadge.exclamationmark",
        steps: [
            "Gift cards.",
            "Cryptocurrency.",
            "Wire transfers.",
            "Money-transfer services.",
            "Peer-to-peer payment applications.",
            "Cash sent by courier.",
            "Depositing a check and returning part of the money.",
            "Paying a fee before receiving a prize, job, refund, or inheritance."
        ],
        warning: """
        Never send money to resolve an unexpected threat, arrest warning, account suspension, or prize claim.
        """
    )

    static let accountCompromise = SafetyArticle(
        title: "If you shared information",
        summary: "Act quickly to reduce damage and regain control of your accounts.",
        systemImage: "person.crop.circle.badge.exclamationmark",
        steps: [
            "Change the affected password immediately.",
            "Use a different password from every other account.",
            "Enable two-factor authentication where available.",
            "Sign out of other devices and active sessions.",
            "Contact your bank or card provider if financial information was shared.",
            "Freeze or replace affected cards when advised.",
            "Review recent account activity and report unauthorized transactions.",
            "Contact your mobile carrier if your phone number or account may be compromised."
        ],
        warning: """
        Start with your email account because access to email can be used to reset many other accounts.
        """
    )

    static let reportScam = SafetyArticle(
        title: "Report the scam",
        summary: "Reporting helps providers, carriers, and authorities identify repeating campaigns.",
        systemImage: "megaphone.fill",
        steps: [
            "Use the report-spam or report-junk option in the messaging or email application.",
            "Report the sender to your mobile carrier when appropriate.",
            "Report fraudulent charges directly to your bank or payment provider.",
            "Notify the company being impersonated through its official support channel.",
            "Preserve screenshots, email headers, phone numbers, receipts, and transaction records.",
            "Submit a report to the relevant consumer-protection or law-enforcement agency in your country."
        ],
        warning: """
        Reporting a scam does not guarantee that money will be recovered, so contact financial providers immediately.
        """
    )

    static let phoneCalls = SafetyArticle(
        title: "Suspicious phone calls",
        summary: "Unexpected callers may use urgency, authority, or fear to pressure you.",
        systemImage: "phone.badge.waveform.fill",
        steps: [
            "Hang up instead of arguing with the caller.",
            "Do not press numbers to speak with an operator unless you initiated the call.",
            "Do not provide personal information to verify your identity.",
            "Do not install remote-control software.",
            "Call the organization back using an official number you find independently.",
            "Block the number after preserving any useful evidence."
        ],
        warning: """
        A local-looking number does not prove the caller is nearby or legitimate.
        """
    )

    static let websiteSafety = SafetyArticle(
        title: "Suspicious websites",
        summary: "A secure connection does not automatically mean a website is trustworthy.",
        systemImage: "globe.badge.chevron.backward",
        steps: [
            "Check the complete hostname carefully.",
            "Look for misspellings, extra words, or substituted letters and numbers.",
            "Avoid links received through unexpected messages.",
            "Open the company’s official app instead.",
            "Do not enter credentials after following an unexpected login link.",
            "Close the page if it requests unusual permissions, downloads, or payments."
        ],
        warning: """
        HTTPS protects the connection but does not prove that the website belongs to the company it claims to represent.
        """
    )

    static let allArticles: [SafetyArticle] = [
        immediateActions,
        verifySender,
        sensitiveInformation,
        paymentScams,
        accountCompromise,
        reportScam,
        phoneCalls,
        websiteSafety
    ]
}
