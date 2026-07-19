import Foundation

struct BrandProfile: Identifiable {
    let name: String
    let aliases: [String]
    let officialDomains: [String]

    var id: String {
        name
    }
}

enum BrandDomainStatus {
    case noBrandDetected
    case noLinkFound
    case official
    case mismatch
    case mixed

    var title: String {
        switch self {
        case .noBrandDetected:
            return "No brand detected"

        case .noLinkFound:
            return "No destination available"

        case .official:
            return "Official domain match"

        case .mismatch:
            return "Domain mismatch"

        case .mixed:
            return "Mixed destinations"
        }
    }

    var systemImage: String {
        switch self {
        case .noBrandDetected:
            return "questionmark.circle"

        case .noLinkFound:
            return "link.badge.plus"

        case .official:
            return "checkmark.seal.fill"

        case .mismatch:
            return "exclamationmark.triangle.fill"

        case .mixed:
            return "exclamationmark.shield.fill"
        }
    }
}

struct BrandDetectionResult {
    let brand: BrandProfile?
    let detectedHosts: [String]
    let matchingOfficialHosts: [String]
    let nonMatchingHosts: [String]
    let status: BrandDomainStatus

    var shouldDisplay: Bool {
        brand != nil
    }
}

struct BrandDetector {
    private let urlAnalyzer = URLRiskAnalyzer()

    private let brands: [BrandProfile] = [
        BrandProfile(
            name: "Apple",
            aliases: [
                "apple",
                "apple id",
                "icloud",
                "apple support",
                "app1e",
                "appl3"
            ],
            officialDomains: [
                "apple.com",
                "icloud.com"
            ]
        ),

        BrandProfile(
            name: "Amazon",
            aliases: [
                "amazon",
                "amazon prime",
                "amazon support",
                "amaz0n"
            ],
            officialDomains: [
                "amazon.com",
                "amazon.co.uk",
                "amazon.ca",
                "amazon.de",
                "amazon.fr",
                "amazon.es",
                "amazon.it",
                "amazon.co.jp"
            ]
        ),

        BrandProfile(
            name: "PayPal",
            aliases: [
                "paypal",
                "paypal support",
                "paypa1",
                "pay-pal"
            ],
            officialDomains: [
                "paypal.com"
            ]
        ),

        BrandProfile(
            name: "Microsoft",
            aliases: [
                "microsoft",
                "microsoft support",
                "office 365",
                "outlook",
                "micros0ft",
                "micro-soft"
            ],
            officialDomains: [
                "microsoft.com",
                "microsoftonline.com",
                "office.com",
                "outlook.com",
                "live.com"
            ]
        ),

        BrandProfile(
            name: "Google",
            aliases: [
                "google",
                "gmail",
                "google support",
                "g00gle"
            ],
            officialDomains: [
                "google.com",
                "gmail.com"
            ]
        ),

        BrandProfile(
            name: "Meta",
            aliases: [
                "facebook",
                "facebook support",
                "instagram",
                "meta",
                "faceb00k",
                "1nstagram"
            ],
            officialDomains: [
                "facebook.com",
                "instagram.com",
                "meta.com"
            ]
        ),

        BrandProfile(
            name: "Netflix",
            aliases: [
                "netflix",
                "netflix support",
                "netf1ix"
            ],
            officialDomains: [
                "netflix.com"
            ]
        ),

        BrandProfile(
            name: "WhatsApp",
            aliases: [
                "whatsapp",
                "whatsapp support",
                "whatsaap"
            ],
            officialDomains: [
                "whatsapp.com"
            ]
        ),

        BrandProfile(
            name: "Chase",
            aliases: [
                "chase",
                "chase bank",
                "chase fraud department"
            ],
            officialDomains: [
                "chase.com"
            ]
        ),

        BrandProfile(
            name: "Bank of America",
            aliases: [
                "bank of america",
                "bankofamerica",
                "bankofarnerica"
            ],
            officialDomains: [
                "bankofamerica.com"
            ]
        ),

        BrandProfile(
            name: "Wells Fargo",
            aliases: [
                "wells fargo",
                "wellsfargo"
            ],
            officialDomains: [
                "wellsfargo.com"
            ]
        ),

        BrandProfile(
            name: "Citibank",
            aliases: [
                "citibank",
                "citi bank",
                "citi"
            ],
            officialDomains: [
                "citi.com"
            ]
        ),

        BrandProfile(
            name: "UPS",
            aliases: [
                "ups",
                "ups delivery",
                "ups package"
            ],
            officialDomains: [
                "ups.com"
            ]
        ),

        BrandProfile(
            name: "FedEx",
            aliases: [
                "fedex",
                "fedex delivery",
                "fedex package"
            ],
            officialDomains: [
                "fedex.com"
            ]
        ),

        BrandProfile(
            name: "DHL",
            aliases: [
                "dhl",
                "dhl delivery",
                "dhl package"
            ],
            officialDomains: [
                "dhl.com"
            ]
        ),

        BrandProfile(
            name: "USPS",
            aliases: [
                "usps",
                "postal service",
                "united states postal service"
            ],
            officialDomains: [
                "usps.com"
            ]
        )
    ]

    func analyze(
        _ value: String,
        as checkType: ScamCheckType
    ) -> BrandDetectionResult {
        let normalizedValue = value.lowercased()

        let detectedHosts = extractHosts(
            from: value,
            checkType: checkType
        )

        guard let detectedBrand = findBrand(
            in: normalizedValue,
            hosts: detectedHosts
        ) else {
            return BrandDetectionResult(
                brand: nil,
                detectedHosts: detectedHosts,
                matchingOfficialHosts: [],
                nonMatchingHosts: detectedHosts,
                status: .noBrandDetected
            )
        }

        guard !detectedHosts.isEmpty else {
            return BrandDetectionResult(
                brand: detectedBrand,
                detectedHosts: [],
                matchingOfficialHosts: [],
                nonMatchingHosts: [],
                status: .noLinkFound
            )
        }

        let matchingHosts = detectedHosts.filter {
            host in

            isOfficialHost(
                host,
                for: detectedBrand
            )
        }

        let nonMatchingHosts = detectedHosts.filter {
            host in

            !isOfficialHost(
                host,
                for: detectedBrand
            )
        }

        let status: BrandDomainStatus

        if !matchingHosts.isEmpty
            && !nonMatchingHosts.isEmpty {
            status = .mixed
        } else if !matchingHosts.isEmpty {
            status = .official
        } else {
            status = .mismatch
        }

        return BrandDetectionResult(
            brand: detectedBrand,
            detectedHosts: detectedHosts,
            matchingOfficialHosts: matchingHosts,
            nonMatchingHosts: nonMatchingHosts,
            status: status
        )
    }

    private func findBrand(
        in normalizedValue: String,
        hosts: [String]
    ) -> BrandProfile? {
        let combinedHosts = hosts
            .joined(separator: " ")
            .lowercased()

        return brands.first { brand in
            brand.aliases.contains { alias in
                normalizedValue.contains(
                    alias.lowercased()
                )
                || combinedHosts.contains(
                    alias.lowercased()
                )
            }
        }
    }

    private func extractHosts(
        from value: String,
        checkType: ScamCheckType
    ) -> [String] {
        var hosts: [String] = []

        if checkType == .website {
            let result = urlAnalyzer.analyze(value)

            if let host = result.host {
                hosts.append(host)
            }
        } else {
            let urls = urlAnalyzer.extractURLs(
                from: value
            )

            for url in urls {
                let result = urlAnalyzer.analyze(
                    url.absoluteString
                )

                if let host = result.host {
                    hosts.append(host)
                }
            }
        }

        var seenHosts = Set<String>()

        return hosts.filter { host in
            seenHosts.insert(
                host.lowercased()
            ).inserted
        }
    }

    private func isOfficialHost(
        _ host: String,
        for brand: BrandProfile
    ) -> Bool {
        let normalizedHost = host
            .lowercased()
            .trimmingCharacters(
                in: CharacterSet(
                    charactersIn: "."
                )
            )

        return brand.officialDomains.contains {
            officialDomain in

            let normalizedOfficialDomain =
                officialDomain.lowercased()

            return normalizedHost
                == normalizedOfficialDomain
                || normalizedHost.hasSuffix(
                    ".\(normalizedOfficialDomain)"
                )
        }
    }
}
