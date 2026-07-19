import Foundation

struct URLRiskResult {
    let originalValue: String
    let normalizedURL: URL?
    let host: String?
    let score: Int
    let warningSigns: [String]
}

struct URLRiskAnalyzer {
    func extractURLs(
        from text: String
    ) -> [URL] {
        var detectedURLs: [URL] = []

        if let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType
                .link.rawValue
        ) {
            let range = NSRange(
                text.startIndex..<text.endIndex,
                in: text
            )

            detector.enumerateMatches(
                in: text,
                options: [],
                range: range
            ) { result, _, _ in
                guard let url = result?.url else {
                    return
                }

                detectedURLs.append(url)
            }
        }

        detectedURLs.append(
            contentsOf: extractBareDomains(
                from: text
            )
        )

        return removeDuplicateURLs(
            detectedURLs
        )
    }

    func analyze(
        _ value: String
    ) -> URLRiskResult {
        let cleanedValue = cleanURLString(
            value
        )

        let normalizedURL = makeURL(
            from: cleanedValue
        )

        let components: URLComponents?

        if let normalizedURL {
            components = URLComponents(
                url: normalizedURL,
                resolvingAgainstBaseURL: false
            )
        } else {
            components = nil
        }

        let host = components?
            .host?
            .lowercased()
            .trimmingCharacters(
                in: CharacterSet(
                    charactersIn: "."
                )
            )

        var score = 0
        var warningSigns: [String] = []

        checkInvalidURL(
            normalizedURL,
            score: &score,
            warningSigns: &warningSigns
        )

        checkScheme(
            components?.scheme,
            score: &score,
            warningSigns: &warningSigns
        )

        checkUserInformation(
            components,
            score: &score,
            warningSigns: &warningSigns
        )

        checkHost(
            host,
            score: &score,
            warningSigns: &warningSigns
        )

        checkPort(
            components?.port,
            score: &score,
            warningSigns: &warningSigns
        )

        checkPathAndQuery(
            components,
            score: &score,
            warningSigns: &warningSigns
        )

        return URLRiskResult(
            originalValue: value,
            normalizedURL: normalizedURL,
            host: host,
            score: min(score, 100),
            warningSigns: warningSigns
        )
    }

    private func cleanURLString(
        _ value: String
    ) -> String {
        value
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .trimmingCharacters(
                in: CharacterSet(
                    charactersIn:
                        ".,;:!?)]}>\"'"
                )
            )
    }

    private func makeURL(
        from value: String
    ) -> URL? {
        guard !value.isEmpty else {
            return nil
        }

        if let url = URL(string: value),
           url.scheme != nil {
            return url
        }

        return URL(
            string: "https://\(value)"
        )
    }

    private func extractBareDomains(
        from text: String
    ) -> [URL] {
        let pattern = #"""
        (?ix)
        \b
        (?:
            [a-z0-9]
            (?:[a-z0-9-]{0,61}[a-z0-9])?
            \.
        )+
        [a-z]{2,24}
        (?:
            /[^\s<>"']*
        )?
        """#

        guard let expression = try? NSRegularExpression(
            pattern: pattern
        ) else {
            return []
        }

        let range = NSRange(
            text.startIndex..<text.endIndex,
            in: text
        )

        return expression
            .matches(
                in: text,
                range: range
            )
            .compactMap { match in
                guard let matchRange = Range(
                    match.range,
                    in: text
                ) else {
                    return nil
                }

                let matchedValue = String(
                    text[matchRange]
                )

                return makeURL(
                    from: cleanURLString(
                        matchedValue
                    )
                )
            }
    }

    private func removeDuplicateURLs(
        _ urls: [URL]
    ) -> [URL] {
        var seenValues = Set<String>()
        var uniqueURLs: [URL] = []

        for url in urls {
            let normalizedValue = url
                .absoluteString
                .lowercased()
                .trimmingCharacters(
                    in: CharacterSet(
                        charactersIn: "/"
                    )
                )

            if seenValues.insert(
                normalizedValue
            ).inserted {
                uniqueURLs.append(url)
            }
        }

        return uniqueURLs
    }

    private func checkInvalidURL(
        _ url: URL?,
        score: inout Int,
        warningSigns: inout [String]
    ) {
        guard url == nil else {
            return
        }

        score += 30

        warningSigns.append(
            "The website address could not be parsed as a normal URL."
        )
    }

    private func checkScheme(
        _ scheme: String?,
        score: inout Int,
        warningSigns: inout [String]
    ) {
        guard let scheme = scheme?.lowercased() else {
            return
        }

        if scheme == "http" {
            score += 15

            warningSigns.append(
                "The link uses HTTP instead of an encrypted HTTPS connection."
            )
        }

        let unusualSchemes = [
            "file",
            "javascript",
            "data",
            "ftp"
        ]

        if unusualSchemes.contains(scheme) {
            score += 35

            warningSigns.append(
                "The link uses an unusual or potentially unsafe URL scheme: \(scheme)."
            )
        }
    }

    private func checkUserInformation(
        _ components: URLComponents?,
        score: inout Int,
        warningSigns: inout [String]
    ) {
        guard let components else {
            return
        }

        if components.user != nil
            || components.password != nil {
            score += 30

            warningSigns.append(
                "The link contains user information before the hostname, which can disguise its real destination."
            )
        }
    }

    private func checkHost(
        _ host: String?,
        score: inout Int,
        warningSigns: inout [String]
    ) {
        guard let host, !host.isEmpty else {
            score += 25

            warningSigns.append(
                "The link does not contain a recognizable website hostname."
            )

            return
        }

        if isIPAddress(host) {
            score += 30

            warningSigns.append(
                "The link uses a numeric IP address instead of a normal domain name."
            )
        }

        if isURLShortener(host) {
            score += 25

            warningSigns.append(
                "The link uses the shortening service \(host), which hides the final destination."
            )
        }

        if host.contains("xn--") {
            score += 25

            warningSigns.append(
                "The domain uses encoded international characters that may visually imitate another website."
            )
        }

        if hasSuspiciousTopLevelDomain(
            host
        ) {
            score += 15

            warningSigns.append(
                "The domain ending is frequently used by disposable or abusive websites."
            )
        }

        if hasExcessiveSubdomains(
            host
        ) {
            score += 15

            warningSigns.append(
                "The link contains an unusual number of subdomains that may hide its real registered domain."
            )
        }

        if hasManyHyphens(host) {
            score += 10

            warningSigns.append(
                "The hostname contains an unusual number of hyphens."
            )
        }

        if let impersonatedBrand =
            impersonatedBrand(in: host) {
            score += 35

            warningSigns.append(
                "The domain may be imitating \(impersonatedBrand) with look-alike letters or numbers."
            )
        }

        if hasBrandInUntrustedPosition(
            host
        ) {
            score += 20

            warningSigns.append(
                "A company name appears inside a longer unrelated hostname. Check the actual domain carefully."
            )
        }
    }

    private func checkPort(
        _ port: Int?,
        score: inout Int,
        warningSigns: inout [String]
    ) {
        guard let port else {
            return
        }

        let commonPorts = [
            80,
            443
        ]

        if !commonPorts.contains(port) {
            score += 15

            warningSigns.append(
                "The link uses the unusual network port \(port)."
            )
        }
    }

    private func checkPathAndQuery(
        _ components: URLComponents?,
        score: inout Int,
        warningSigns: inout [String]
    ) {
        guard let components else {
            return
        }

        let combinedValue = [
            components.path,
            components.query ?? "",
            components.fragment ?? ""
        ]
        .joined(separator: " ")
        .lowercased()

        let credentialWords = [
            "login",
            "signin",
            "sign-in",
            "password",
            "credential",
            "verify",
            "verification",
            "confirm",
            "account",
            "security",
            "unlock"
        ]

        if containsAny(
            credentialWords,
            in: combinedValue
        ) {
            score += 10

            warningSigns.append(
                "The link path requests login, account, or verification activity."
            )
        }

        let paymentWords = [
            "payment",
            "billing",
            "invoice",
            "refund",
            "wallet",
            "gift-card",
            "crypto"
        ]

        if containsAny(
            paymentWords,
            in: combinedValue
        ) {
            score += 10

            warningSigns.append(
                "The link path refers to payment, billing, refunds, or financial activity."
            )
        }

        if combinedValue.count > 180 {
            score += 10

            warningSigns.append(
                "The link contains an unusually long path or query string."
            )
        }

        if combinedValue.contains("%40")
            || combinedValue.contains("%2f%2f") {
            score += 15

            warningSigns.append(
                "The link contains encoded characters that may obscure its destination."
            )
        }
    }

    private func isIPAddress(
        _ host: String
    ) -> Bool {
        let ipv4Pattern =
            #"^(?:\d{1,3}\.){3}\d{1,3}$"#

        if host.range(
            of: ipv4Pattern,
            options: .regularExpression
        ) != nil {
            return true
        }

        return host.contains(":")
            && host.range(
                of: #"^[0-9a-f:]+$"#,
                options: [
                    .regularExpression,
                    .caseInsensitive
                ]
            ) != nil
    }

    private func isURLShortener(
        _ host: String
    ) -> Bool {
        let shortenerDomains = [
            "bit.ly",
            "tinyurl.com",
            "t.co",
            "goo.gl",
            "ow.ly",
            "is.gd",
            "buff.ly",
            "rebrand.ly",
            "cutt.ly",
            "shorturl.at",
            "tiny.cc"
        ]

        return shortenerDomains.contains {
            domain in

            host == domain
                || host.hasSuffix(
                    ".\(domain)"
                )
        }
    }

    private func hasSuspiciousTopLevelDomain(
        _ host: String
    ) -> Bool {
        let suspiciousEndings = [
            ".zip",
            ".click",
            ".top",
            ".work",
            ".country",
            ".gq",
            ".tk",
            ".rest",
            ".fit",
            ".buzz",
            ".cam",
            ".support"
        ]

        return suspiciousEndings.contains {
            ending in

            host.hasSuffix(ending)
        }
    }

    private func hasExcessiveSubdomains(
        _ host: String
    ) -> Bool {
        let parts = host
            .split(separator: ".")

        return parts.count >= 5
    }

    private func hasManyHyphens(
        _ host: String
    ) -> Bool {
        host.filter { $0 == "-" }.count >= 3
    }

    private func impersonatedBrand(
        in host: String
    ) -> String? {
        let lookAlikePatterns: [
            String: String
        ] = [
            "paypa1": "PayPal",
            "pay-pal": "PayPal",
            "app1e": "Apple",
            "appl3": "Apple",
            "amaz0n": "Amazon",
            "micros0ft": "Microsoft",
            "micro-soft": "Microsoft",
            "g00gle": "Google",
            "faceb00k": "Facebook",
            "netf1ix": "Netflix",
            "1nstagram": "Instagram",
            "whatsaap": "WhatsApp",
            "chase-bank": "Chase",
            "bankofarnerica": "Bank of America"
        ]

        for (
            suspiciousText,
            brandName
        ) in lookAlikePatterns {
            if host.contains(
                suspiciousText
            ) {
                return brandName
            }
        }

        return nil
    }

    private func hasBrandInUntrustedPosition(
        _ host: String
    ) -> Bool {
        let trustedBrandDomains = [
            "apple.com",
            "amazon.com",
            "google.com",
            "microsoft.com",
            "paypal.com",
            "netflix.com",
            "facebook.com",
            "instagram.com",
            "chase.com",
            "bankofamerica.com"
        ]

        let brandNames = [
            "apple",
            "amazon",
            "google",
            "microsoft",
            "paypal",
            "netflix",
            "facebook",
            "instagram",
            "chase",
            "bankofamerica"
        ]

        let isTrustedDomain =
            trustedBrandDomains.contains {
                trustedDomain in

                host == trustedDomain
                    || host.hasSuffix(
                        ".\(trustedDomain)"
                    )
            }

        if isTrustedDomain {
            return false
        }

        return brandNames.contains {
            brandName in

            host.contains(brandName)
        }
    }

    private func containsAny(
        _ values: [String],
        in text: String
    ) -> Bool {
        values.contains { value in
            text.contains(value)
        }
    }
}
