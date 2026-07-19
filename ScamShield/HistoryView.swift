import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext)
    private var modelContext

    @Query(
        sort: \ScanHistoryItem.createdAt,
        order: .reverse
    )
    private var historyItems: [ScanHistoryItem]

    @State private var searchText = ""

    @State private var selectedTypeFilter:
        HistoryTypeFilter = .all

    @State private var selectedRiskFilter:
        HistoryRiskFilter = .all

    @State private var selectedSortOrder:
        HistorySortOrder = .newest

    @State private var isShowingFilters = false
    @State private var isShowingDeleteAllConfirmation = false

    @State private var deletionErrorMessage: String?
    @State private var isShowingDeletionError = false

    var body: some View {
        NavigationStack {
            Group {
                if historyItems.isEmpty {
                    emptyHistoryView
                } else if filteredHistoryItems.isEmpty {
                    noMatchingResultsView
                } else {
                    historyList
                }
            }
            .navigationTitle("Scan History")
            .searchable(
                text: $searchText,
                prompt: "Search scans"
            )
            .toolbar {
                ToolbarItemGroup(
                    placement: .topBarTrailing
                ) {
                    if !historyItems.isEmpty {
                        Button {
                            isShowingFilters = true
                        } label: {
                            Image(
                                systemName:
                                    filtersAreActive
                                    ? "line.3.horizontal.decrease.circle.fill"
                                    : "line.3.horizontal.decrease.circle"
                            )
                        }
                        .accessibilityLabel(
                            "Filter scan history"
                        )

                        Menu {
                            Button(
                                "Delete All History",
                                role: .destructive
                            ) {
                                isShowingDeleteAllConfirmation = true
                            }
                        } label: {
                            Image(
                                systemName: "ellipsis.circle"
                            )
                        }
                        .accessibilityLabel(
                            "History options"
                        )
                    }
                }
            }
            .sheet(
                isPresented: $isShowingFilters
            ) {
                HistoryFilterSheet(
                    selectedType:
                        $selectedTypeFilter,
                    selectedRisk:
                        $selectedRiskFilter,
                    selectedSortOrder:
                        $selectedSortOrder,
                    onReset: resetFilters
                )
                .presentationDetents([
                    .medium,
                    .large
                ])
            }
            .confirmationDialog(
                "Delete all scan history?",
                isPresented:
                    $isShowingDeleteAllConfirmation,
                titleVisibility: .visible
            ) {
                Button(
                    "Delete All History",
                    role: .destructive
                ) {
                    deleteAllHistory()
                }

                Button(
                    "Cancel",
                    role: .cancel
                ) {}
            } message: {
                Text(
                    "This action cannot be undone."
                )
            }
            .alert(
                "History Could Not Be Deleted",
                isPresented:
                    $isShowingDeletionError
            ) {
                Button(
                    "OK",
                    role: .cancel
                ) {}
            } message: {
                Text(
                    deletionErrorMessage
                    ?? "An unknown storage error occurred."
                )
            }
        }
    }

    private var emptyHistoryView: some View {
        ContentUnavailableView {
            Label(
                "No Scan History",
                systemImage:
                    "clock.arrow.circlepath"
            )
        } description: {
            Text(
                "Messages, websites, and phone numbers you analyze will appear here."
            )
        } actions: {
            Text(
                "Use the Check tab to perform your first scan."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var noMatchingResultsView: some View {
        ContentUnavailableView {
            Label(
                "No Matching Scans",
                systemImage: "magnifyingglass"
            )
        } description: {
            Text(
                "Try changing your search or filters."
            )
        } actions: {
            Button("Clear Search and Filters") {
                searchText = ""
                resetFilters()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var historyList: some View {
        List {
            if filtersAreActive {
                activeFiltersSection
            }

            Section {
                ForEach(
                    filteredHistoryItems
                ) { item in
                    NavigationLink {
                        HistoryDetailView(
                            item: item
                        )
                    } label: {
                        HistoryRowView(
                            item: item
                        )
                    }
                }
                .onDelete(
                    perform:
                        deleteFilteredHistoryItems
                )
            } header: {
                Text(resultCountText)
            }
        }
        .listStyle(.insetGrouped)
    }

    private var activeFiltersSection: some View {
        Section {
            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {
                HStack(spacing: 8) {
                    if selectedTypeFilter != .all {
                        filterChip(
                            title:
                                selectedTypeFilter.rawValue,
                            systemImage:
                                selectedTypeFilter.systemImage
                        ) {
                            selectedTypeFilter = .all
                        }
                    }

                    if selectedRiskFilter != .all {
                        filterChip(
                            title:
                                selectedRiskFilter.rawValue,
                            systemImage:
                                selectedRiskFilter.systemImage
                        ) {
                            selectedRiskFilter = .all
                        }
                    }

                    if selectedSortOrder != .newest {
                        filterChip(
                            title:
                                selectedSortOrder.rawValue,
                            systemImage:
                                selectedSortOrder.systemImage
                        ) {
                            selectedSortOrder = .newest
                        }
                    }

                    Button("Clear All") {
                        searchText = ""
                        resetFilters()
                    }
                    .font(.caption)
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func filterChip(
        title: String,
        systemImage: String,
        onRemove: @escaping () -> Void
    ) -> some View {
        Button {
            onRemove()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: systemImage)

                Text(title)

                Image(systemName: "xmark.circle.fill")
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Color.blue.opacity(0.12)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var filteredHistoryItems:
        [ScanHistoryItem] {

        let filteredItems =
            historyItems.filter { item in
                matchesSearch(item)
                    && selectedTypeFilter
                        .matches(item)
                    && selectedRiskFilter
                        .matches(item)
            }

        return sortItems(filteredItems)
    }

    private func matchesSearch(
        _ item: ScanHistoryItem
    ) -> Bool {
        let cleanedSearch = searchText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()

        guard !cleanedSearch.isEmpty else {
            return true
        }

        let searchableValues = [
            item.analyzedValue,
            item.summary,
            item.recommendation,
            item.checkType.rawValue,
            item.riskLevel.title
        ]
        + item.warningSigns

        return searchableValues.contains {
            value in

            value.lowercased()
                .contains(cleanedSearch)
        }
    }

    private func sortItems(
        _ items: [ScanHistoryItem]
    ) -> [ScanHistoryItem] {
        switch selectedSortOrder {
        case .newest:
            return items.sorted {
                $0.createdAt > $1.createdAt
            }

        case .oldest:
            return items.sorted {
                $0.createdAt < $1.createdAt
            }

        case .highestRisk:
            return items.sorted {
                if $0.score == $1.score {
                    return $0.createdAt > $1.createdAt
                }

                return $0.score > $1.score
            }

        case .lowestRisk:
            return items.sorted {
                if $0.score == $1.score {
                    return $0.createdAt > $1.createdAt
                }

                return $0.score < $1.score
            }
        }
    }

    private var filtersAreActive: Bool {
        selectedTypeFilter != .all
            || selectedRiskFilter != .all
            || selectedSortOrder != .newest
    }

    private var resultCountText: String {
        let count =
            filteredHistoryItems.count

        return count == 1
            ? "1 Scan"
            : "\(count) Scans"
    }

    private func deleteFilteredHistoryItems(
        at offsets: IndexSet
    ) {
        let visibleItems = filteredHistoryItems

        let itemsToDelete: [ScanHistoryItem] =
            offsets.map { index in
                visibleItems[index]
            }

        for item in itemsToDelete {
            modelContext.delete(item)
        }

        saveDeletionChanges()
    }

    private func deleteAllHistory() {
        for item in historyItems {
            modelContext.delete(item)
        }

        saveDeletionChanges()
    }

    private func saveDeletionChanges() {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()

            deletionErrorMessage =
                error.localizedDescription

            isShowingDeletionError = true
        }
    }

    private func resetFilters() {
        selectedTypeFilter = .all
        selectedRiskFilter = .all
        selectedSortOrder = .newest
    }
}

private struct HistoryRowView: View {
    let item: ScanHistoryItem

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        item.riskLevel.color
                            .opacity(0.12)
                    )
                    .frame(
                        width: 46,
                        height: 46
                    )

                Image(
                    systemName:
                        item.riskLevel.iconName
                )
                .foregroundStyle(
                    item.riskLevel.color
                )
            }

            VStack(
                alignment: .leading,
                spacing: 5
            ) {
                HStack {
                    Label(
                        item.checkType.rawValue,
                        systemImage:
                            item.checkType.systemImage
                    )
                    .font(.headline)

                    Spacer()

                    Text("\(item.score)%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            item.riskLevel.color
                        )
                }

                Text(item.analyzedValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack {
                    Text(
                        item.riskLevel.shortTitle
                    )
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        item.riskLevel.color
                    )

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text(
                        item.createdAt,
                        format: .dateTime
                            .month(.abbreviated)
                            .day()
                            .hour()
                            .minute()
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct HistoryFilterSheet: View {
    @Binding var selectedType:
        HistoryTypeFilter

    @Binding var selectedRisk:
        HistoryRiskFilter

    @Binding var selectedSortOrder:
        HistorySortOrder

    let onReset: () -> Void

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Scan Type") {
                    Picker(
                        "Scan Type",
                        selection: $selectedType
                    ) {
                        ForEach(
                            HistoryTypeFilter.allCases
                        ) { filter in
                            Label(
                                filter.rawValue,
                                systemImage:
                                    filter.systemImage
                            )
                            .tag(filter)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Risk Level") {
                    Picker(
                        "Risk Level",
                        selection: $selectedRisk
                    ) {
                        ForEach(
                            HistoryRiskFilter.allCases
                        ) { filter in
                            Label(
                                filter.rawValue,
                                systemImage:
                                    filter.systemImage
                            )
                            .tag(filter)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Sort") {
                    Picker(
                        "Sort Order",
                        selection: $selectedSortOrder
                    ) {
                        ForEach(
                            HistorySortOrder.allCases
                        ) { sortOrder in
                            Label(
                                sortOrder.rawValue,
                                systemImage:
                                    sortOrder.systemImage
                            )
                            .tag(sortOrder)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section {
                    Button(
                        "Reset All Filters",
                        role: .destructive
                    ) {
                        onReset()
                    }
                }
            }
            .navigationTitle("Filter History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .topBarTrailing
                ) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(
            for: ScanHistoryItem.self,
            inMemory: true
        )
}
