import Foundation

struct ScamAnalyzer {
    private let urlRiskAnalyzer =
        URLRiskAnalyzer()

    func analyze(
        _ value: String,
        as checkType: ScamCheckType
    ) -> ScamAnalysisResult {
        switch checkType {
        case .message:
            return analyzeMessage(value)

        case .website:
            return analyzeWebsite(value)

        case .phone:
            return analyzePhoneNumber(value)
        }
    }

    private func analyzeMessage(
        _ message: String
    ) -> ScamAnalysisResult {
        let normalizedMessage =
            message.lowercased()

        var score = 0
        var warningSigns: [String] = []

        checkUrgency(
            in: normalizedMessage,
            score: &score,
            warningSigns: &warningSigns
        )

        checkSensitiveInformationRequests(
            in: normalizedMessage,
            score: &score,
            warningSigns: &warningSigns
        )

        checkPaymentRequests(
            in: normalizedMessage,
            score: &score,
            warningSigns: &warningSigns
        )

        checkThreats(
            in: normalizedMessage,
            score: &score,
            warningSigns: &warningSigns
        )

        checkPrizeClaims(
            in: normalizedMessage,
            score: &score,
            warningSigns: &warningSigns
        )

        checkImpersonation(
            in: normalizedMessage,
            score: &score,
            warningSigns: &warningSigns
        )

        checkUnusualContactRequests(
            in: normalizedMessage,
            score: &score,
            warningSigns: &warningSigns
        )

        checkGrammarAndGreetingPatterns(
            in: normalizedMessage,
            score: &score,
            warningSigns: &warningSigns
        )

        analyzeLinksInsideMessage(
            message,
            score: &score,
            warningSigns: &warningSigns
        )

        return createResult(
            checkType: .message,
            analyzedValue: message,
            score: score,
            warningSigns:
                removeDuplicateWarnings(
                    warningSigns
                )
        )
    }

    private func analyzeWebsite(
        _ website: String
    ) -> ScamAnalysisResult {
        let urlResult =
            urlRiskAnalyzer.analyze(
                website
            )

        return createResult(
            checkType: .website,
            analyzedValue: website,
            score: urlResult.score,
            warningSigns:
                urlResult.warningSigns
        )
    }

    private func analyzePhoneNumber(
        _ phoneNumber: String
    ) -> ScamAnalysisResult {
        let cleanedNumber =
            phoneNumber.filter {
                $0.isNumber || $0 == "+"
            }

        let digits =
            phoneNumber.filter(\.isNumber)

        var score = 0
        var warningSigns: [String] = []

        if digits.count < 7 {
            score += 20

            warningSigns.append(
                "The phone number appears incomplete or unusually short."
            )
        }

        if digits.count > 15 {
            score += 20

            warningSigns.append(
                "The phone number is longer than a standard international phone number."
            )
        }

        if cleanedNumber.hasPrefix("+") {
            score += 5

            warningSigns.append(
                "This appears to be an international number. Confirm that you recognize the country code."
            )
        }

        if hasRepeatedDigits(digits) {
            score += 10

            warningSigns.append(
                "The number contains a long sequence of repeated digits."
            )
        }

        if isPremiumRatePattern(digits) {
            score += 25

            warningSigns.append(
                "The number may match a premium-rate or high-cost calling pattern."
            )
        }

        if hasSuspiciousCallerIDPattern(
            digits
        ) {
            score += 15

            warningSigns.append(
                "The number uses a pattern sometimes associated with spoofed or invalid caller identification."
            )
        }

        if warningSigns.isEmpty {
            warningSigns.append(
                "No obvious warning signs were found from the number format alone."
            )
        }

        return createResult(
            checkType: .phone,
            analyzedValue: phoneNumber,
            score: score,
            warningSigns: warningSigns
        )
    }

    private func analyzeLinksInsideMessage(
        _ message: String,
        score: inout Int,
        warningSigns: inout [String]
    ) {
        let extractedURLs =
            urlRiskAnalyzer.extractURLs(
                from: message
            )

        guard !extractedURLs.isEmpty else {
            if containsAny(
                [
                    "click here",
                    "tap here",
                    "open the link",
                    "follow the link"
                ],
                in: message.lowercased()
            ) {
                score += 10

                warningSigns.append(
                    "The message asks you to open a link, but the destination may not be clearly visible."
                )
            }

            return
        }

        score += min(
            extractedURLs.count * 5,
            15
        )

        let linkCountDescription =
            extractedURLs.count == 1
            ? "1 website link"
            : "\(extractedURLs.count) website links"

        warningSigns.append(
            "The message contains \(linkCountDescription). Verify every destination before opening it."
        )

        for extractedURL in
            extractedURLs.prefix(5) {
            let result =
                urlRiskAnalyzer.analyze(
                    extractedURL.absoluteString
                )

            let linkScoreContribution =
                min(result.score, 40)

            score += linkScoreContribution

            let destination =
                result.host
                ?? extractedURL.absoluteString

            for warning in
                result.warningSigns {
                warningSigns.append(
                    "\(destination): \(warning)"
                )
            }
        }

        if extractedURLs.count > 5 {
            score += 10

            warningSigns.append(
                "The message contains an unusually large number of links."
            )
        }
    }

    private func checkUrgency(
        in message: String,
        score: inout Int,
        warningSigns: inout [String]
    ) {
        let phrases = [
            "act now",
            "immediately",
            "urgent",
            "within 24 hours",
            "within 48 hours",
            "limited time",
            "right away",
            "final warning",
            "today only",
            "expires today",
            "do not delay"
        ]

        if containsAny(
            phrases,
            in: message
        ) {
            score += 15

            warningSigns.append(
                "The message creates urgency or pressures you to act quickly."
            )
        }
    }

    private func checkSensitiveInformationRequests(
        in message: String,
        score: inout Int,
        warningSigns: inout [String]
    ) {
        let phrases = [
            "password",
            "verification code",
            "security code",
            "one-time code",
            "one time code",
            "otp",
            "social security",
            "ssn",
            "bank account",
            "routing number",
            "credit card number",
            "debit card number",
            "login details",
            "confirm your identity",
            "date of birth",
            "mother's maiden name"
        ]

        if containsAny(
            phrases,
            in: message
        ) {
            score += 25

            warningSigns.append(
                "The sender may be requesting sensitive personal, login, or financial information."
            )
        }
    }

    private func checkPaymentRequests(
        in message: String,
        score: inout Int,
        warningSigns: inout [String]
    ) {
        let highRiskPaymentPhrases = [
            "gift card",
            "bitcoin",
            "cryptocurrency",
            "crypto wallet",
            "wire transfer",
            "western union",
            "moneygram",
            "cash app",
            "zelle",
            "apple cash",
            "steam card",
            "google play card"
        ]

        if containsAny(
            highRiskPaymentPhrases,
            in: message
        ) {
            score += 30

            warningSigns.append(
                "The message requests a payment method commonly used in scams."
            )
        }

        let generalPaymentPhrases = [
            "send money",
            "payment required",
            "pay a fee",
            "processing fee",
            "release fee",
            "unpaid invoice",
            "refund fee"
        ]

        if containsAny(
            generalPaymentPhrases,
            in: message
        ) {
            score += 15

            warningSigns.append(
                "The message requests money or a fee."
            )
        }
    }

    private func checkThreats(
        in message: String,
        score: inout Int,
        warningSigns: inout [String]
    ) {
        let phrases = [
            "account suspended",
            "account closed",
            "account locked",
            "legal action",
            "arrest warrant",
            "police",
            "you will be arrested",
            "service disconnected",
            "service will be disconnected",
            "access will be blocked",
            "tax penalty",
            "deportation",
            "lawsuit",
            "collections department"
        ]

        if containsAny(
            phrases,
            in: message
        ) {
            score += 20

            warningSigns.append(
                "The message uses threats, fear, or account restrictions to influence your decision."
            )
        }
    }

    private func checkPrizeClaims(
        in message: String,
        score: inout Int,
        warningSigns: inout [String]
    ) {
        let phrases = [
            "you won",
            "winner",
            "claim your prize",
            "lottery",
            "free reward",
            "cash prize",
            "selected to receive",
            "sweepstakes",
            "inheritance",
            "unclaimed funds"
        ]

        if containsAny(
            phrases,
            in: message
        ) {
            score += 20

            warningSigns.append(
                "The message claims that you unexpectedly won or are entitled to money, a prize, or a reward."
            )
        }
    }

    private func checkImpersonation(
        in message: String,
        score: inout Int,
        warningSigns: inout [String]
    ) {
        let phrases = [
            "irs",
            "social security administration",
            "technical support",
            "microsoft support",
            "apple support",
            "your bank",
            "fraud department",
            "government agency",
            "customs department",
            "police department",
            "federal agent",
            "amazon support",
            "paypal support"
        ]

        if containsAny(
            phrases,
            in: message
        ) {
            score += 10

            warningSigns.append(
                "The sender may be claiming to represent a trusted company or government organization."
            )
        }
    }

    private func checkUnusualContactRequests(
        in message: String,
        score: inout Int,
        warningSigns: inout [String]
    ) {
        let phrases = [
            "contact me on whatsapp",
            "contact us on whatsapp",
            "message me on telegram",
            "contact us on telegram",
            "move this conversation",
            "do not call the official number",
            "keep this confidential",
            "do not tell anyone",
            "secret shopper",
            "remote job offer"
        ]

        if containsAny(
            phrases,
            in: message
        ) {
            score += 15

            warningSigns.append(
                "The sender requests secrecy or asks you to move the conversation to an unusual communication channel."
            )
        }
    }

    private func checkGrammarAndGreetingPatterns(
        in message: String,
        score: inout Int,
        warningSigns: inout [String]
    ) {
        let genericGreetings = [
            "dear customer",
            "dear account holder",
            "dear beneficiary",
            "dear user",
            "valued customer"
        ]

        if containsAny(
            genericGreetings,
            in: message
        ) {
            score += 5

            warningSigns.append(
                "The message uses a generic greeting instead of identifying you personally."
            )
        }
    }

    private func createResult(
        checkType: ScamCheckType,
        analyzedValue: String,
        score: Int,
        warningSigns: [String]
    ) -> ScamAnalysisResult {
        let finalScore = min(
            max(score, 0),
            100
        )

        let level = riskLevel(
            for: finalScore
        )

        return ScamAnalysisResult(
            checkType: checkType,
            analyzedValue: analyzedValue,
            score: finalScore,
            riskLevel: level,
            summary: summary(
                for: level,
                checkType: checkType
            ),
            warningSigns:
                warningSigns,
            recommendation:
                recommendation(
                    for: level,
                    checkType: checkType
                )
        )
    }

    private func containsAny(
        _ phrases: [String],
        in value: String
    ) -> Bool {
        phrases.contains { phrase in
            value.contains(phrase)
        }
    }

    private func hasRepeatedDigits(
        _ digits: String
    ) -> Bool {
        let pattern = #"(\d)\1{5,}"#

        return digits.range(
            of: pattern,
            options: .regularExpression
        ) != nil
    }

    private func isPremiumRatePattern(
        _ digits: String
    ) -> Bool {
        let premiumPrefixes = [
            "1900",
            "1976",
            "1882",
            "900"
        ]

        return premiumPrefixes.contains {
            prefix in

            digits.hasPrefix(prefix)
                || (
                    digits.count > prefix.count
                    && digits.dropFirst()
                        .hasPrefix(prefix)
                )
        }
    }

    private func hasSuspiciousCallerIDPattern(
        _ digits: String
    ) -> Bool {
        let invalidPatterns = [
            "0000000",
            "1111111",
            "1234567",
            "9999999"
        ]

        return invalidPatterns.contains {
            pattern in

            digits.contains(pattern)
        }
    }

    private func removeDuplicateWarnings(
        _ warnings: [String]
    ) -> [String] {
        var seenWarnings = Set<String>()

        return warnings.filter { warning in
            seenWarnings.insert(
                warning
            ).inserted
        }
    }

    private func riskLevel(
        for score: Int
    ) -> ScamRiskLevel {
        switch score {
        case 0..<25:
            return .low

        case 25..<60:
            return .suspicious

        default:
            return .high
        }
    }

    private func summary(
        for riskLevel: ScamRiskLevel,
        checkType: ScamCheckType
    ) -> String {
        switch riskLevel {
        case .low:
            return lowRiskSummary(
                for: checkType
            )

        case .suspicious:
            return """
            This \(checkType.rawValue.lowercased()) contains warning signs and should be treated carefully.
            """

        case .high:
            return """
            This \(checkType.rawValue.lowercased()) contains several warning signs commonly associated with scams.
            """
        }
    }

    private func lowRiskSummary(
        for checkType: ScamCheckType
    ) -> String {
        switch checkType {
        case .message:
            return """
            No strong scam indicators were found in this message.
            """

        case .website:
            return """
            No strong warning signs were found in the website address.
            """

        case .phone:
            return """
            No strong warning signs were found from the phone number format.
            """
        }
    }

    private func recommendation(
        for riskLevel: ScamRiskLevel,
        checkType: ScamCheckType
    ) -> String {
        switch checkType {
        case .message:
            return messageRecommendation(
                for: riskLevel
            )

        case .website:
            return websiteRecommendation(
                for: riskLevel
            )

        case .phone:
            return phoneRecommendation(
                for: riskLevel
            )
        }
    }

    private func messageRecommendation(
        for riskLevel: ScamRiskLevel
    ) -> String {
        switch riskLevel {
        case .low:
            return """
            Remain cautious. Verify the sender before sharing personal information, sending money, or opening unfamiliar links.
            """

        case .suspicious:
            return """
            Do not open links or provide personal information yet. Contact the organization using a trusted phone number, official app, or website you find independently.
            """

        case .high:
            return """
            Do not reply, open links, download attachments, or send money. Block the sender and contact the claimed organization through an official channel.
            """
        }
    }

    private func websiteRecommendation(
        for riskLevel: ScamRiskLevel
    ) -> String {
        switch riskLevel {
        case .low:
            return """
            The address does not show obvious warning signs, but this does not prove the website is safe. Confirm the domain before entering information.
            """

        case .suspicious:
            return """
            Avoid signing in, entering payment information, or downloading files. Find the company website independently instead of using this link.
            """

        case .high:
            return """
            Do not open the website or enter any information. Close the page and visit the organization through its official app or a trusted address you enter yourself.
            """
        }
    }

    private func phoneRecommendation(
        for riskLevel: ScamRiskLevel
    ) -> String {
        switch riskLevel {
        case .low:
            return """
            The number format does not show obvious warning signs. Do not share sensitive information unless you can verify the caller independently.
            """

        case .suspicious:
            return """
            Do not return the call immediately. Find the organization's official phone number independently and contact it directly.
            """

        case .high:
            return """
            Do not call back, provide personal information, or send money. Block the number and report it through your phone carrier if appropriate.
            """
        }
    }
}
