import SwiftUI
import ComponentsKit

public struct ThreatHistoryView: View {
    @State private var events: [ThreatEventRecord] = []
    @State private var selectedFilter: HistoryFilter = .all
    @State private var searchText: String = ""
    @State private var showingClearConfirmation: Bool = false
    @State private var selectedEvent: ThreatEventRecord?

    public enum HistoryFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case safari = "Safari"
        case sms = "SMS"

        public var id: String { rawValue }

        public var title: String { rawValue }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                RetroTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Segmented Filter Control
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(HistoryFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 12)

                    if filteredEvents.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 10) {
                                AppSectionHeader("LOGGED THREATS (\(filteredEvents.count))")
                                    .padding(.horizontal, 4)

                                AppCard {
                                    VStack(spacing: 0) {
                                        ForEach(Array(filteredEvents.enumerated()), id: \.element.id) { index, event in
                                            if index > 0 {
                                                Divider()
                                                    .padding(.leading, 56)
                                            }

                                            Button(action: {
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                selectedEvent = event
                                            }) {
                                                HStack(spacing: 12) {
                                                    AppIconWell(
                                                        icon: event.source == "sms" ? "message.badge.filled.fill" : "safari.fill",
                                                        iconColor: RetroTheme.accent,
                                                        backgroundColor: RetroTheme.content1,
                                                        size: 40,
                                                        iconSize: 18
                                                    )

                                                    VStack(alignment: .leading, spacing: 3) {
                                                        Text(title(for: event))
                                                            .font(RetroTheme.headlineSmall)
                                                            .foregroundColor(RetroTheme.foreground)
                                                            .lineLimit(1)

                                                        Text(subtitle(for: event))
                                                            .font(RetroTheme.captionMedium)
                                                            .foregroundColor(RetroTheme.secondaryForeground)
                                                            .lineLimit(1)
                                                    }

                                                    Spacer()

                                                    Text(event.actionTaken == "blocked" ? "Blocked" : "Junked")
                                                        .font(RetroTheme.captionLarge)
                                                        .foregroundColor(RetroTheme.secondaryForeground)

                                                    Image(systemName: "chevron.right")
                                                        .font(RetroTheme.captionSmall)
                                                        .foregroundColor(RetroTheme.secondaryForeground)
                                                }
                                                .padding(.vertical, 10)
                                                .contentShape(Rectangle())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                        }
                        .refreshable {
                            loadEvents()
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search links, senders, or brands")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !events.isEmpty {
                        Button(role: .destructive) {
                            showingClearConfirmation = true
                        } label: {
                            Text("Clear")
                                .font(RetroTheme.buttonSmall)
                                .foregroundColor(RetroTheme.danger)
                        }
                    }
                }
            }
            .confirmationDialog(
                "Clear History",
                isPresented: $showingClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All History", role: .destructive) {
                    ThreatDatabase.shared.clearAllEvents()
                    loadEvents()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes all logged threats from your device.")
            }
            .sheet(item: $selectedEvent) { event in
                ThreatEventDetailSheet(event: event)
            }
            .onAppear {
                loadEvents()
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        AppEmptyState(
            icon: searchText.isEmpty ? "shield.checkered" : "magnifyingglass",
            title: searchText.isEmpty ? "No Threats Detected" : "No Results Found",
            subtitle: searchText.isEmpty ?
                 "Blocked scam messages and deceptive websites will appear here." :
                 "No logged threats match \"\(searchText)\". Try another search term."
        )
    }

    // MARK: - Helpers

    private var filteredEvents: [ThreatEventRecord] {
        events.filter { event in
            let matchesFilter: Bool
            switch selectedFilter {
            case .all: matchesFilter = true
            case .safari: matchesFilter = event.source == "safari"
            case .sms: matchesFilter = event.source == "sms"
            }

            guard matchesFilter else { return false }

            if searchText.isEmpty {
                return true
            } else {
                let term = searchText.lowercased()
                return event.target.lowercased().contains(term) ||
                    (event.sender?.lowercased().contains(term) ?? false) ||
                    (event.targetBrand?.lowercased().contains(term) ?? false) ||
                    event.category.lowercased().contains(term)
            }
        }
    }

    private func loadEvents() {
        events = ThreatDatabase.shared.fetchRecentEvents()
    }

    private func title(for event: ThreatEventRecord) -> String {
        if let brand = event.targetBrand, !brand.isEmpty, !brand.contains("://") {
            let cleanBrand = brand
                .replacingOccurrences(of: " (Domain Test)", with: "")
                .replacingOccurrences(of: " (URL Test)", with: "")
            return cleanBrand
        } else if let url = URL(string: event.target), let host = url.host, !host.isEmpty {
            return host
        } else {
            return event.source == "sms" ? "Scam Message" : "Deceptive Website"
        }
    }

    private func subtitle(for event: ThreatEventRecord) -> String {
        let timeStr = event.timestamp.relativeFormatted
        if let sender = event.sender, !sender.isEmpty {
            return "\(sender) · \(timeStr)"
        } else {
            return "\(event.category.capitalized) · \(timeStr)"
        }
    }
}
