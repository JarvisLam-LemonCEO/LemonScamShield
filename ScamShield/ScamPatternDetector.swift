import Foundation

struct ScamPatternDetector {
    func analyze(
        _ value: String,
        as checkType: ScamCheckType
    ) -> ScamPatternAnalysis {
        let normalizedText = value.lowercased()

        var matches: [ScamPatternMatch] = []

        addMatch(
            type: .bankPhishing,
            evidence: bankPhishingEvidence(
                in: normalizedText
            ),
            to: &matches
        )

        addMatch(
            type: .deliveryScam,
            evidence: deliveryEvidence(
                in: normalizedText
            ),
            to: &matches
        )

        addMatch(
            type: .prizeScam,
            evidence: prizeEvidence(
                in: normalizedText
            ),
            to: &matches
        )

        addMatch(
            type: .governmentImpersonation,
            evidence: governmentEvidence(
                in: normalizedText
            ),
            to: &matches
        )

        addMatch(
            type: .techSupportScam,
            evidence: techSupportEvidence(
                in: normalizedText
            ),
            to: &matches
        )

        addMatch(
            type: .investmentScam,
            evidence: investmentEvidence(
                in: normalizedText
            ),
            to: &matches
        )

        addMatch(
            type: .jobScam,
            evidence: jobEvidence(
                in: normalizedText
            ),
            to: &matches
        )

        addMatch(
            type: .fakeInvoice,
            evidence: invoiceEvidence(
                in: normalizedText
            ),
            to: &matches
        )

        addMatch(
            type: .accountTakeover,
            evidence: accountTakeoverEvidence(
                in: normalizedText
            ),
            to: &matches
        )

        addMatch(
            type: .giftCardScam,
            evidence: giftCardEvidence(
                in: normalizedText
            ),
            to: &matches
        )

        addMatch(
            type: .romanceScam,
            evidence: romanceEvidence(
                in: normalizedText
            ),
            to: &matches
        )

        addMatch(
            type: .marketplaceScam,
            evidence: marketplaceEvidence(
                in: normalizedText
            ),
            to: &matches
        )

        if checkType == .website {
            appendWebsiteContext(
                value,
                to: &matches
            )
        }

        let sortedMatches = matches.sorted {
            if $0.confidence == $1.confidence {
                return evidenceWeight(
                    $0.evidence
                ) > evidenceWeight(
                    $1.evidence
                )
            }

            return $0.confidence
                > $1.confidence
        }

        guard let primaryMatch =
            sortedMatches.first,
            primaryMatch.confidence >= 35
        else {
            return ScamPatternAnalysis(
                primaryMatch: nil,
                additionalMatches: []
            )
        }

        let additionalMatches = Array(
            sortedMatches
                .dropFirst()
                .filter {
                    $0.confidence >= 45
                }
                .prefix(2)
        )

        return ScamPatternAnalysis(
            primaryMatch: primaryMatch,
            additionalMatches:
                additionalMatches
        )
    }

    private func bankPhishingEvidence(
        in text: String
    ) -> [ScamPatternEvidence] {
        var evidence: [ScamPatternEvidence] = []

        addEvidence(
            phrases: [
                "bank",
                "bank account",
                "fraud department",
                "debit card",
                "credit card",
                "routing number",
                "financial institution"
            ],
            title:
                "References a bank or financial account",
            weight: 24,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "account suspended",
                "account locked",
                "unusual transaction",
                "unauthorized transaction",
                "fraud alert"
            ],
            title:
                "Uses a bank-account threat or fraud alert",
            weight: 25,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "password",
                "login",
                "verify your identity",
                "verification code",
                "security code"
            ],
            title:
                "Requests login or verification information",
            weight: 24,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "http://",
                "https://",
                "click here",
                "tap here"
            ],
            title:
                "Includes a login or verification link",
            weight: 15,
            text: text,
            evidence: &evidence
        )

        addUrgencyEvidence(
            text,
            evidence: &evidence
        )

        return evidence
    }

    private func deliveryEvidence(
        in text: String
    ) -> [ScamPatternEvidence] {
        var evidence: [ScamPatternEvidence] = []

        addEvidence(
            phrases: [
                "package",
                "parcel",
                "delivery",
                "shipment",
                "shipping",
                "usps",
                "ups",
                "fedex",
                "dhl"
            ],
            title:
                "References a package or delivery service",
            weight: 30,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "delivery failed",
                "unable to deliver",
                "incorrect address",
                "package held",
                "customs",
                "redelivery"
            ],
            title:
                "Claims a delivery problem",
            weight: 25,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "shipping fee",
                "customs fee",
                "small fee",
                "delivery fee",
                "redelivery fee"
            ],
            title:
                "Requests a delivery or customs payment",
            weight: 25,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "tracking link",
                "track your package",
                "update address",
                "confirm address"
            ],
            title:
                "Requests address or tracking action",
            weight: 16,
            text: text,
            evidence: &evidence
        )

        return evidence
    }

    private func prizeEvidence(
        in text: String
    ) -> [ScamPatternEvidence] {
        var evidence: [ScamPatternEvidence] = []

        addEvidence(
            phrases: [
                "you won",
                "winner",
                "lottery",
                "sweepstakes",
                "cash prize",
                "claim your prize",
                "selected to receive",
                "inheritance"
            ],
            title:
                "Promises an unexpected prize or payment",
            weight: 45,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "processing fee",
                "release fee",
                "tax fee",
                "claim fee",
                "pay a fee"
            ],
            title:
                "Requests a fee before releasing the reward",
            weight: 35,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "gift card",
                "wire transfer",
                "western union",
                "cryptocurrency"
            ],
            title:
                "Requests a difficult-to-reverse payment",
            weight: 25,
            text: text,
            evidence: &evidence
        )

        return evidence
    }

    private func governmentEvidence(
        in text: String
    ) -> [ScamPatternEvidence] {
        var evidence: [ScamPatternEvidence] = []

        addEvidence(
            phrases: [
                "irs",
                "social security administration",
                "government agency",
                "federal agent",
                "police department",
                "customs department",
                "tax department"
            ],
            title:
                "Claims to represent a government agency",
            weight: 35,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "arrest",
                "arrest warrant",
                "legal action",
                "deportation",
                "lawsuit",
                "tax penalty"
            ],
            title:
                "Threatens legal or government action",
            weight: 35,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "gift card",
                "bitcoin",
                "wire transfer",
                "immediate payment"
            ],
            title:
                "Requests an unusual government payment method",
            weight: 30,
            text: text,
            evidence: &evidence
        )

        return evidence
    }

    private func techSupportEvidence(
        in text: String
    ) -> [ScamPatternEvidence] {
        var evidence: [ScamPatternEvidence] = []

        addEvidence(
            phrases: [
                "technical support",
                "tech support",
                "microsoft support",
                "apple support",
                "computer support"
            ],
            title:
                "Claims to provide technical support",
            weight: 35,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "virus detected",
                "malware detected",
                "computer infected",
                "security warning",
                "device compromised"
            ],
            title:
                "Claims the device is infected or compromised",
            weight: 35,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "remote access",
                "anydesk",
                "teamviewer",
                "screen sharing",
                "install software"
            ],
            title:
                "Requests remote device access",
            weight: 40,
            text: text,
            evidence: &evidence
        )

        return evidence
    }

    private func investmentEvidence(
        in text: String
    ) -> [ScamPatternEvidence] {
        var evidence: [ScamPatternEvidence] = []

        addEvidence(
            phrases: [
                "investment",
                "invest now",
                "trading platform",
                "forex",
                "cryptocurrency",
                "bitcoin",
                "crypto wallet"
            ],
            title:
                "Promotes an investment or cryptocurrency opportunity",
            weight: 30,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "guaranteed profit",
                "guaranteed return",
                "risk free",
                "double your money",
                "daily profit",
                "high returns"
            ],
            title:
                "Promises unrealistic or guaranteed returns",
            weight: 40,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "deposit now",
                "minimum deposit",
                "send bitcoin",
                "transfer funds"
            ],
            title:
                "Requests an immediate investment deposit",
            weight: 25,
            text: text,
            evidence: &evidence
        )

        return evidence
    }

    private func jobEvidence(
        in text: String
    ) -> [ScamPatternEvidence] {
        var evidence: [ScamPatternEvidence] = []

        addEvidence(
            phrases: [
                "job offer",
                "remote job",
                "work from home",
                "hiring",
                "recruiter",
                "employment opportunity"
            ],
            title:
                "Contains an unexpected employment offer",
            weight: 30,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "equipment fee",
                "training fee",
                "background check fee",
                "send money",
                "purchase equipment"
            ],
            title:
                "Requests money during recruitment",
            weight: 38,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "telegram interview",
                "whatsapp interview",
                "text interview",
                "no experience required",
                "immediate start"
            ],
            title:
                "Uses an unusual or rushed hiring process",
            weight: 25,
            text: text,
            evidence: &evidence
        )

        return evidence
    }

    private func invoiceEvidence(
        in text: String
    ) -> [ScamPatternEvidence] {
        var evidence: [ScamPatternEvidence] = []

        addEvidence(
            phrases: [
                "invoice",
                "billing",
                "renewal",
                "subscription",
                "receipt",
                "purchase confirmation"
            ],
            title:
                "Contains an invoice or billing notice",
            weight: 28,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "payment overdue",
                "unpaid invoice",
                "automatic renewal",
                "charged today",
                "payment required"
            ],
            title:
                "Claims that payment is due or already charged",
            weight: 30,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "call to cancel",
                "call for refund",
                "refund department",
                "contact support immediately"
            ],
            title:
                "Directs the recipient to a refund or cancellation number",
            weight: 30,
            text: text,
            evidence: &evidence
        )

        return evidence
    }

    private func accountTakeoverEvidence(
        in text: String
    ) -> [ScamPatternEvidence] {
        var evidence: [ScamPatternEvidence] = []

        addEvidence(
            phrases: [
                "password",
                "verification code",
                "security code",
                "one-time code",
                "one time code",
                "otp",
                "login details"
            ],
            title:
                "Requests credentials or a security code",
            weight: 38,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "confirm your identity",
                "verify your account",
                "unlock your account",
                "reset your password"
            ],
            title:
                "Requests account verification or recovery",
            weight: 30,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "account locked",
                "account suspended",
                "unusual login",
                "new login",
                "security alert"
            ],
            title:
                "Uses an account-security warning",
            weight: 24,
            text: text,
            evidence: &evidence
        )

        addUrgencyEvidence(
            text,
            evidence: &evidence
        )

        return evidence
    }

    private func giftCardEvidence(
        in text: String
    ) -> [ScamPatternEvidence] {
        var evidence: [ScamPatternEvidence] = []

        addEvidence(
            phrases: [
                "gift card",
                "google play card",
                "apple gift card",
                "steam card",
                "amazon gift card"
            ],
            title:
                "Requests payment using gift cards",
            weight: 60,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "scratch the card",
                "send the code",
                "card number",
                "security code",
                "photo of the card"
            ],
            title:
                "Requests the gift-card number or code",
            weight: 40,
            text: text,
            evidence: &evidence
        )

        return evidence
    }

    private func romanceEvidence(
        in text: String
    ) -> [ScamPatternEvidence] {
        var evidence: [ScamPatternEvidence] = []

        addEvidence(
            phrases: [
                "love you",
                "my dear",
                "my love",
                "future together",
                "relationship"
            ],
            title:
                "Uses romantic or emotional language",
            weight: 18,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "emergency",
                "medical bill",
                "travel money",
                "stuck overseas",
                "need your help"
            ],
            title:
                "Claims a personal emergency requiring assistance",
            weight: 32,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "send money",
                "gift card",
                "wire transfer",
                "cryptocurrency"
            ],
            title:
                "Requests financial assistance",
            weight: 38,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "keep this secret",
                "do not tell anyone",
                "private between us"
            ],
            title:
                "Requests secrecy",
            weight: 22,
            text: text,
            evidence: &evidence
        )

        return evidence
    }

    private func marketplaceEvidence(
        in text: String
    ) -> [ScamPatternEvidence] {
        var evidence: [ScamPatternEvidence] = []

        addEvidence(
            phrases: [
                "marketplace",
                "buyer",
                "seller",
                "item for sale",
                "listing",
                "shipping agent"
            ],
            title:
                "References an online sale or marketplace",
            weight: 24,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "overpayment",
                "send the difference",
                "payment confirmation",
                "payment pending",
                "upgrade your account"
            ],
            title:
                "Uses a false payment or overpayment story",
            weight: 38,
            text: text,
            evidence: &evidence
        )

        addEvidence(
            phrases: [
                "courier will collect",
                "shipping company",
                "pay insurance fee",
                "release payment"
            ],
            title:
                "Uses an unusual collection or shipping arrangement",
            weight: 30,
            text: text,
            evidence: &evidence
        )

        return evidence
    }

    private func addUrgencyEvidence(
        _ text: String,
        evidence: inout [ScamPatternEvidence]
    ) {
        addEvidence(
            phrases: [
                "urgent",
                "immediately",
                "act now",
                "within 24 hours",
                "final warning",
                "right away"
            ],
            title:
                "Creates urgency or immediate pressure",
            weight: 15,
            text: text,
            evidence: &evidence
        )
    }

    private func appendWebsiteContext(
        _ value: String,
        to matches: inout [ScamPatternMatch]
    ) {
        let result =
            URLRiskAnalyzer().analyze(value)

        guard result.score >= 25 else {
            return
        }

        let websiteEvidence =
            ScamPatternEvidence(
                title:
                    "The website address contains phishing-style characteristics",
                weight: min(
                    result.score / 2,
                    30
                )
            )

        for index in matches.indices {
            let current = matches[index]

            guard current.type
                != .unknown
            else {
                continue
            }

            let updatedEvidence =
                current.evidence
                + [websiteEvidence]

            matches[index] =
                ScamPatternMatch(
                    type: current.type,
                    confidence:
                        confidence(
                            from:
                                updatedEvidence
                        ),
                    evidence:
                        updatedEvidence
                )
        }
    }

    private func addMatch(
        type: ScamPatternType,
        evidence: [ScamPatternEvidence],
        to matches: inout [ScamPatternMatch]
    ) {
        guard !evidence.isEmpty else {
            return
        }

        let confidence =
            confidence(from: evidence)

        matches.append(
            ScamPatternMatch(
                type: type,
                confidence: confidence,
                evidence: evidence
            )
        )
    }

    private func addEvidence(
        phrases: [String],
        title: String,
        weight: Int,
        text: String,
        evidence:
            inout [ScamPatternEvidence]
    ) {
        guard phrases.contains(
            where: {
                text.contains($0)
            }
        ) else {
            return
        }

        guard !evidence.contains(
            where: {
                $0.title == title
            }
        ) else {
            return
        }

        evidence.append(
            ScamPatternEvidence(
                title: title,
                weight: weight
            )
        )
    }

    private func confidence(
        from evidence:
            [ScamPatternEvidence]
    ) -> Int {
        let total =
            evidenceWeight(evidence)

        /*
         Evidence has diminishing returns.
         A few strong signals can create high
         confidence without exceeding 100.
         */
        switch total {
        case 0..<20:
            return total

        case 20..<40:
            return 30 + (total - 20)

        case 40..<70:
            return 50 + (total - 40)

        case 70..<100:
            return 80 + ((total - 70) / 2)

        default:
            return 96
        }
    }

    private func evidenceWeight(
        _ evidence:
            [ScamPatternEvidence]
    ) -> Int {
        evidence.reduce(0) {
            partialResult,
            item in

            partialResult + item.weight
        }
    }
}
