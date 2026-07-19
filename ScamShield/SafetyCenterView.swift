import SwiftUI

struct SafetyCenterView: View {
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(
                    alignment: .leading,
                    spacing: 20
                ) {
                    emergencyNotice
                    introductionSection
                    safetyChecklist
                    articlesSection
                    disclaimerSection
                }
                .padding()
            }
            .navigationTitle("Safety Center")
            .searchable(
                text: $searchText,
                prompt: "Search safety advice"
            )
        }
    }

    private var emergencyNotice: some View {
        HStack(
            alignment: .top,
            spacing: 12
        ) {
            Image(
                systemName: "exclamationmark.octagon.fill"
            )
            .font(.title2)
            .foregroundStyle(.red)

            VStack(
                alignment: .leading,
                spacing: 6
            ) {
                Text("Money or account at risk?")
                    .font(.headline)

                Text(
                    "Contact your bank, card provider, payment service, or account provider immediately using an official phone number or application."
                )
                .font(.subheadline)
            }

            Spacer()
        }
        .padding()
        .background(
            Color.red.opacity(0.1)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
    }

    private var introductionSection: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 38))
                .foregroundStyle(.blue)

            Text("Protect yourself from scams")
                .font(.title2)
                .fontWeight(.bold)

            Text(
                "Use these guides when you receive an unexpected message, email, call, website link, invoice, or payment request."
            )
            .foregroundStyle(.secondary)
        }
    }

    private var safetyChecklist: some View {
        VStack(
            alignment: .leading,
            spacing: 14
        ) {
            Label(
                "Remember these four rules",
                systemImage: "checklist"
            )
            .font(.headline)

            checklistRow(
                number: 1,
                title: "Stop",
                text: "Do not act while someone is pressuring or frightening you."
            )

            checklistRow(
                number: 2,
                title: "Check",
                text: "Verify the sender using an independent official source."
            )

            checklistRow(
                number: 3,
                title: "Protect",
                text: "Do not share passwords, security codes, money, or remote access."
            )

            checklistRow(
                number: 4,
                title: "Report",
                text: "Preserve evidence and report the account, number, message, or transaction."
            )
        }
        .padding()
        .background(
            Color.blue.opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
    }

    private func checklistRow(
        number: Int,
        title: String,
        text: String
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: 12
        ) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(
                    width: 32,
                    height: 32
                )
                .background(Color.blue)
                .clipShape(Circle())

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(title)
                    .font(.headline)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var articlesSection: some View {
        VStack(
            alignment: .leading,
            spacing: 14
        ) {
            Text("Safety guides")
                .font(.title3)
                .fontWeight(.bold)

            if filteredArticles.isEmpty {
                ContentUnavailableView.search(
                    text: searchText
                )
            } else {
                ForEach(filteredArticles) { article in
                    NavigationLink {
                        SafetyArticleDetailView(
                            article: article
                        )
                    } label: {
                        SafetyArticleRow(
                            article: article
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var disclaimerSection: some View {
        HStack(
            alignment: .top,
            spacing: 10
        ) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)

            Text(
                "ScamShield provides general safety information. It does not replace advice from your bank, account provider, law enforcement, attorney, or another qualified professional."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical)
    }

    private var filteredArticles: [SafetyArticle] {
        let cleanedSearch = searchText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()

        guard !cleanedSearch.isEmpty else {
            return SafetyArticle.allArticles
        }

        return SafetyArticle.allArticles.filter {
            article in

            article.title
                .lowercased()
                .contains(cleanedSearch)
            || article.summary
                .lowercased()
                .contains(cleanedSearch)
            || article.steps.contains {
                step in

                step.lowercased()
                    .contains(cleanedSearch)
            }
        }
    }
}

private struct SafetyArticleRow: View {
    let article: SafetyArticle

    var body: some View {
        HStack(spacing: 14) {
            Image(
                systemName: article.systemImage
            )
            .font(.title2)
            .foregroundStyle(.blue)
            .frame(
                width: 46,
                height: 46
            )
            .background(
                Color.blue.opacity(0.1)
            )
            .clipShape(Circle())

            VStack(
                alignment: .leading,
                spacing: 5
            ) {
                Text(article.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(article.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Spacer()

            Image(
                systemName: "chevron.right"
            )
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            Color.secondary.opacity(0.07)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 15)
        )
    }
}

private struct SafetyArticleDetailView: View {
    let article: SafetyArticle

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 24
            ) {
                articleHeader
                stepsSection

                if let warning = article.warning {
                    warningSection(warning)
                }

                rememberSection
            }
            .padding()
        }
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var articleHeader: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Image(
                systemName: article.systemImage
            )
            .font(.system(size: 48))
            .foregroundStyle(.blue)

            Text(article.title)
                .font(.title2)
                .fontWeight(.bold)

            Text(article.summary)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var stepsSection: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            Text("What you should do")
                .font(.headline)

            ForEach(
                Array(article.steps.enumerated()),
                id: \.offset
            ) { index, step in
                HStack(
                    alignment: .top,
                    spacing: 12
                ) {
                    Text("\(index + 1)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(
                            width: 28,
                            height: 28
                        )
                        .background(Color.blue)
                        .clipShape(Circle())

                    Text(step)
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                }
            }
        }
    }

    private func warningSection(
        _ warning: String
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: 12
        ) {
            Image(
                systemName: "exclamationmark.triangle.fill"
            )
            .foregroundStyle(.orange)

            VStack(
                alignment: .leading,
                spacing: 5
            ) {
                Text("Important")
                    .font(.headline)

                Text(warning)
                    .font(.subheadline)
            }

            Spacer()
        }
        .padding()
        .background(
            Color.orange.opacity(0.1)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 14)
        )
    }

    private var rememberSection: some View {
        HStack(
            alignment: .top,
            spacing: 12
        ) {
            Image(
                systemName: "shield.checkered"
            )
            .foregroundStyle(.green)

            Text(
                "Pause, verify independently, and never allow urgency to prevent you from checking whether a request is genuine."
            )
            .font(.subheadline)
        }
        .padding()
        .background(
            Color.green.opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 14)
        )
    }
}

#Preview {
    SafetyCenterView()
}
