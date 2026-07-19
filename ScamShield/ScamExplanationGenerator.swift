import Foundation

struct ScamExplanationGenerator {
    func generate(
        for value: String,
        checkType: ScamCheckType
    ) -> ScamExplanation {
        let normalizedText = value.lowercased()

        let patternAnalysis = ScamPatternDetector().analyze(
            value,
            as: checkType
        )

        let primaryPattern = patternAnalysis.primaryMatch

        var observations: [String] = []
        var recommendations: [String] = []

        appendUrgencyObservation(
            from: normalizedText,
            to: &observations
        )

        appendCredentialObservation(
            from: normalizedText,
            to: &observations
        )

        appendPaymentObservation(
            from: normalizedText,
            to: &observations
        )

        appendThreatObservation(
            from: normalizedText,
            to: &observations
        )

        appendRewardObservation(
            from: normalizedText,
            to: &observations
        )

        appendSecrecyObservation(
            from: normalizedText,
            to: &observations
        )

        appendRemoteAccessObservation(
            from: normalizedText,
            to: &observations
        )

        appendLinkObservation(
            value: value,
            checkType: checkType,
            to: &observations
        )

        appendPatternRecommendations(
            primaryPattern?.type,
            to: &recommendations
        )

        appendGeneralRecommendations(
            text: normalizedText,
            checkType: checkType,
            to: &recommendations
        )

        let confidence = explanationConfidence(
            pattern: primaryPattern,
            observationCount: observations.count
        )

        let headline = makeHeadline(
            pattern: primaryPattern,
            confidence: confidence
        )

        let explanation = makeExplanation(
            pattern: primaryPattern,
            observations: observations,
            checkType: checkType
        )

        return ScamExplanation(
            headline: headline,
            explanation: explanation,
            recommendations: unique(recommendations),
            detectedPattern: primaryPattern,
            confidence: confidence
        )
    }

    private func makeHeadline(
        pattern: ScamPatternMatch?,
        confidence: Int
    ) -> String {
        if let pattern {
            switch confidence {
            case 75...:
                return "This strongly resembles \(pattern.type.title.lowercased())"

            case 50..<75:
                return "This may be \(pattern.type.title.lowercased())"

            default:
                return "Some signs resemble \(pattern.type.title.lowercased())"
            }
        }

        switch confidence {
        case 65...:
            return "Several scam warning signs were detected"

        case 35..<65:
            return "This content should be treated cautiously"

        default:
            return "No clear scam pattern was identified"
        }
    }

    private func makeExplanation(
        pattern: ScamPatternMatch?,
        observations: [String],
        checkType: ScamCheckType
    ) -> String {
        var sentences: [String] = []

        if let pattern {
            sentences.append(
                openingSentence(
                    for: pattern.type,
                    checkType: checkType
                )
            )
        } else {
            sentences.append(
                fallbackOpeningSentence(
                    for: checkType
                )
            )
        }

        if !observations.isEmpty {
            sentences.append(
                combineObservations(observations)
            )
        }

        if let pattern {
            sentences.append(
                closingSentence(
                    for: pattern.type
                )
            )
        } else if observations.isEmpty {
            sentences.append(
                "That does not guarantee the content is safe, so verify unexpected requests through an official source."
            )
        } else {
            sentences.append(
                "The combination of these signals is commonly used to pressure people into revealing information, sending money, or opening unsafe links."
            )
        }

        return sentences
            .map(normalizeSentence)
            .joined(separator: " ")
    }

    private func openingSentence(
        for pattern: ScamPatternType,
        checkType: ScamCheckType
    ) -> String {
        let subject = contentSubject(
            for: checkType
        )

        switch pattern {
        case .bankPhishing:
            return "\(subject) appears to imitate a bank or financial institution."

        case .deliveryScam:
            return "\(subject) appears to use a package or delivery problem as a reason to demand action."

        case .prizeScam:
            return "\(subject) promises an unexpected prize, reward, lottery payment, or inheritance."

        case .governmentImpersonation:
            return "\(subject) may be impersonating a government agency or law-enforcement organization."

        case .techSupportScam:
            return "\(subject) appears to use a fake device warning or technical-support claim."

        case .investmentScam:
            return "\(subject) promotes an investment or cryptocurrency opportunity that may not be legitimate."

        case .jobScam:
            return "\(subject) appears to contain an unexpected or suspicious employment offer."

        case .fakeInvoice:
            return "\(subject) appears to contain a suspicious invoice, charge, renewal, or refund notice."

        case .accountTakeover:
            return "\(subject) may be attempting to obtain credentials or security codes needed to access an account."

        case .giftCardScam:
            return "\(subject) appears to request payment using gift cards."

        case .romanceScam:
            return "\(subject) may be using emotional manipulation to build trust and request money or assistance."

        case .marketplaceScam:
            return "\(subject) may involve a fraudulent buyer, seller, payment, or delivery arrangement."

        case .unknown:
            return "\(subject) contains suspicious characteristics but does not match one clear scam category."
        }
    }

    private func fallbackOpeningSentence(
        for checkType: ScamCheckType
    ) -> String {
        switch checkType {
        case .message:
            return "This message was checked for common scam language and manipulation techniques."

        case .website:
            return "This website address was checked for common phishing and impersonation characteristics."

        case .phone:
            return "This phone-number submission was checked for scam-related context and warning signs."
        }
    }

    private func closingSentence(
        for pattern: ScamPatternType
    ) -> String {
        switch pattern {
        case .bankPhishing:
            return "Contact the bank through its official app, card, or published website instead of using the details in this message."

        case .deliveryScam:
            return "Check the shipment directly in the delivery company's official app or website."

        case .prizeScam:
            return "Legitimate prizes generally do not require gift cards, cryptocurrency, or advance fees before payment."

        case .governmentImpersonation:
            return "Government agencies do not normally demand immediate payment through gift cards, cryptocurrency, or threatening messages."

        case .techSupportScam:
            return "Do not install remote-access software or allow an unexpected caller to control the device."

        case .investmentScam:
            return "Guaranteed returns, urgent deposits, and risk-free investment claims are major warning signs."

        case .jobScam:
            return "Legitimate employers generally do not require applicants to pay fees or purchase equipment using money sent by an unknown recruiter."

        case .fakeInvoice:
            return "Verify the charge through the company's official website or a previously trusted contact method."

        case .accountTakeover:
            return "Never send passwords, one-time codes, or account recovery codes to another person."

        case .giftCardScam:
            return "Gift-card codes work like cash and should never be sent to an unexpected requester."

        case .romanceScam:
            return "Avoid sending money to someone whose identity and circumstances cannot be independently verified."

        case .marketplaceScam:
            return "Keep communication and payments inside the marketplace's official platform whenever possible."

        case .unknown:
            return "Verify the request independently before opening links, sending money, or sharing personal information."
        }
    }

    private func combineObservations(
        _ observations: [String]
    ) -> String {
        let limitedObservations = Array(
            observations.prefix(4)
        )

        guard let first = limitedObservations.first else {
            return ""
        }

        if limitedObservations.count == 1 {
            return first
        }

        if limitedObservations.count == 2 {
            return "\(first) \(limitedObservations[1])"
        }

        return limitedObservations.joined(
            separator: " "
        )
    }

    private func appendUrgencyObservation(
        from text: String,
        to observations: inout [String]
    ) {
        let phrases = [
            "urgent",
            "immediately",
            "act now",
            "right away",
            "final warning",
            "within 24 hours",
            "today only",
            "limited time"
        ]

        guard containsAny(
            phrases,
            in: text
        ) else {
            return
        }

        observations.append(
            "It creates urgency or time pressure to discourage careful verification."
        )
    }

    private func appendCredentialObservation(
        from text: String,
        to observations: inout [String]
    ) {
        let phrases = [
            "password",
            "passcode",
            "verification code",
            "security code",
            "one-time code",
            "one time code",
            "otp",
            "login details",
            "social security number",
            "bank account number"
        ]

        guard containsAny(
            phrases,
            in: text
        ) else {
            return
        }

        observations.append(
            "It refers to sensitive credentials, identity details, or verification codes that should not be shared."
        )
    }

    private func appendPaymentObservation(
        from text: String,
        to observations: inout [String]
    ) {
        let phrases = [
            "gift card",
            "wire transfer",
            "western union",
            "bitcoin",
            "cryptocurrency",
            "crypto wallet",
            "processing fee",
            "release fee",
            "customs fee",
            "send money"
        ]

        guard containsAny(
            phrases,
            in: text
        ) else {
            return
        }

        observations.append(
            "It requests money through a payment method that may be difficult to recover or dispute."
        )
    }

    private func appendThreatObservation(
        from text: String,
        to observations: inout [String]
    ) {
        let phrases = [
            "account suspended",
            "account locked",
            "legal action",
            "arrest",
            "arrest warrant",
            "deportation",
            "penalty",
            "service terminated",
            "final notice"
        ]

        guard containsAny(
            phrases,
            in: text
        ) else {
            return
        }

        observations.append(
            "It uses fear, account restrictions, or legal threats to pressure the recipient."
        )
    }

    private func appendRewardObservation(
        from text: String,
        to observations: inout [String]
    ) {
        let phrases = [
            "you won",
            "winner",
            "cash prize",
            "lottery",
            "inheritance",
            "guaranteed profit",
            "guaranteed return",
            "double your money"
        ]

        guard containsAny(
            phrases,
            in: text
        ) else {
            return
        }

        observations.append(
            "It uses an unexpected reward or unrealistic financial promise to gain attention."
        )
    }

    private func appendSecrecyObservation(
        from text: String,
        to observations: inout [String]
    ) {
        let phrases = [
            "keep this secret",
            "do not tell anyone",
            "don't tell anyone",
            "private between us",
            "confidential request"
        ]

        guard containsAny(
            phrases,
            in: text
        ) else {
            return
        }

        observations.append(
            "It requests secrecy, which can prevent the recipient from checking the story with someone they trust."
        )
    }

    private func appendRemoteAccessObservation(
        from text: String,
        to observations: inout [String]
    ) {
        let phrases = [
            "remote access",
            "anydesk",
            "teamviewer",
            "screen sharing",
            "install software",
            "remote desktop"
        ]

        guard containsAny(
            phrases,
            in: text
        ) else {
            return
        }

        observations.append(
            "It requests remote access or software installation that could give another person control of the device."
        )
    }

    private func appendLinkObservation(
        value: String,
        checkType: ScamCheckType,
        to observations: inout [String]
    ) {
        let normalizedText = value.lowercased()

        let containsLink =
            normalizedText.contains("http://")
            || normalizedText.contains("https://")
            || normalizedText.contains("www.")

        guard containsLink || checkType == .website else {
            return
        }

        let urlRisk = URLRiskAnalyzer().analyze(
            value
        )

        if urlRisk.score >= 45 {
            observations.append(
                "The included web address has several characteristics commonly associated with deceptive or impersonated websites."
            )
        } else if urlRisk.score >= 20 {
            observations.append(
                "The included web address has characteristics that should be verified before it is opened."
            )
        } else {
            observations.append(
                "It directs the recipient to a web address, so the destination should be verified independently."
            )
        }
    }

    private func appendPatternRecommendations(
        _ pattern: ScamPatternType?,
        to recommendations: inout [String]
    ) {
        guard let pattern else {
            return
        }

        switch pattern {
        case .bankPhishing:
            recommendations.append(
                "Open the bank's official app or manually enter its known website address."
            )
            recommendations.append(
                "Call the number printed on the back of the bank card when account assistance is needed."
            )

        case .deliveryScam:
            recommendations.append(
                "Enter the tracking number directly in the carrier's official website or app."
            )
            recommendations.append(
                "Do not pay a redelivery or customs fee through an unexpected message."
            )

        case .prizeScam:
            recommendations.append(
                "Do not pay a fee to release a prize, lottery payment, or inheritance."
            )
            recommendations.append(
                "Do not send gift cards, cryptocurrency, or banking information."
            )

        case .governmentImpersonation:
            recommendations.append(
                "Contact the agency using a number published on its official government website."
            )
            recommendations.append(
                "Do not make payments in response to threats received by message or phone."
            )

        case .techSupportScam:
            recommendations.append(
                "Do not install remote-access software requested by an unexpected caller or pop-up."
            )
            recommendations.append(
                "Close the page or call and contact the device manufacturer through its official support channel."
            )

        case .investmentScam:
            recommendations.append(
                "Do not transfer money based on guaranteed-return or risk-free claims."
            )
            recommendations.append(
                "Verify the company and financial professional through an official regulator."
            )

        case .jobScam:
            recommendations.append(
                "Do not pay recruitment, equipment, training, or background-check fees."
            )
            recommendations.append(
                "Confirm the vacancy through the employer's official careers page."
            )

        case .fakeInvoice:
            recommendations.append(
                "Check purchases and subscriptions directly through the official account."
            )
            recommendations.append(
                "Do not call a cancellation number included only in the suspicious notice."
            )

        case .accountTakeover:
            recommendations.append(
                "Do not share passwords, authentication codes, or password-reset links."
            )
            recommendations.append(
                "Change the account password through the official app if information may have been exposed."
            )

        case .giftCardScam:
            recommendations.append(
                "Do not purchase or send gift-card numbers for an unexpected request."
            )
            recommendations.append(
                "Contact the person through a previously trusted method to confirm their identity."
            )

        case .romanceScam:
            recommendations.append(
                "Do not send money until the person's identity and story have been independently verified."
            )
            recommendations.append(
                "Discuss the request with someone you trust before taking action."
            )

        case .marketplaceScam:
            recommendations.append(
                "Keep payment and communication inside the official marketplace."
            )
            recommendations.append(
                "Do not refund an overpayment or pay a courier, insurance, or account-upgrade fee."
            )

        case .unknown:
            break
        }
    }

    private func appendGeneralRecommendations(
        text: String,
        checkType: ScamCheckType,
        to recommendations: inout [String]
    ) {
        if text.contains("http://")
            || text.contains("https://")
            || checkType == .website {
            recommendations.append(
                "Do not open the link until the domain has been independently verified."
            )
        }

        if containsAny(
            [
                "password",
                "verification code",
                "security code",
                "otp",
                "social security"
            ],
            in: text
        ) {
            recommendations.append(
                "Do not provide credentials, identity information, or security codes."
            )
        }

        if containsAny(
            [
                "send money",
                "gift card",
                "wire transfer",
                "bitcoin",
                "cryptocurrency"
            ],
            in: text
        ) {
            recommendations.append(
                "Do not send money or payment information."
            )
        }

        recommendations.append(
            "Verify the request using contact details obtained from an official source."
        )
    }

    private func explanationConfidence(
        pattern: ScamPatternMatch?,
        observationCount: Int
    ) -> Int {
        let patternConfidence =
            pattern?.confidence ?? 0

        let observationContribution =
            min(observationCount * 8, 32)

        if pattern != nil {
            return min(
                max(
                    patternConfidence,
                    40
                ) + observationContribution / 3,
                99
            )
        }

        return min(
            observationContribution + 10,
            75
        )
    }

    private func contentSubject(
        for checkType: ScamCheckType
    ) -> String {
        switch checkType {
        case .message:
            return "This message"

        case .website:
            return "This website"

        case .phone:
            return "This submission"
        }
    }

    private func containsAny(
        _ phrases: [String],
        in text: String
    ) -> Bool {
        phrases.contains {
            text.contains($0)
        }
    }

    private func unique(
        _ values: [String]
    ) -> [String] {
        var seen: Set<String> = []

        return values.filter {
            seen.insert($0).inserted
        }
    }

    private func normalizeSentence(
        _ value: String
    ) -> String {
        let trimmed = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmed.isEmpty else {
            return ""
        }

        if trimmed.hasSuffix(".")
            || trimmed.hasSuffix("!")
            || trimmed.hasSuffix("?") {
            return trimmed
        }

        return trimmed + "."
    }
}
