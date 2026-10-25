import SwiftUI
import ComponentsKit

public struct ThreatHistoryView: View {
    @State private var events: [ThreatEventRecord] = []
    @State private var selectedFilter: HistoryFilter = .all
    @State private var searchText: String = ""
    @State private var showingClearConfirmation: Bool = false
    @State private var selectedEvent: ThreatEventRecord?

    public enum HistoryFilter: String, CaseIterable, Identifiable {
        case all = "ALL"
        case safari = "SAFARI"
        case sms = "SMS"

        public var id: String { rawValue }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                RetroTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Retro Segmented Filter Tabs
                    filterBar
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 10)

                    // Search Input
                    AppSearchField("Filter links, brands, senders...", text: $searchText)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)

                    if filteredEvents.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                HStack {
                                    Text("\(filteredEvents.count) LOGGED EVENT\(filteredEvents.count == 1 ? "" : "S")")
                                        .font(RetroTheme.captionSmall)
                                        .foregroundColor(RetroTheme.secondaryForeground)
                                    Spacer()
                                }
                                .padding(.horizontal, 4)

                                ForEach(filteredEvents) { event in
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        selectedEvent = event
                                    }) {
                                        eventCard(for: event)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 96)
                        }
                        .refreshable {
                            loadEvents()
                        }
                    }
                }
            }
            .navigationTitle("AUDIT LOG")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !events.isEmpty {
                        Button(action: { showingClearConfirmation = true }) {
                            AppBadge("CLEAR", color: .danger, isFilled: false)
                        }
                    }
                }
            }
            .confirmationDialog(
                "CLEAR AUDIT LOG",
                isPresented: $showingClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All Threat Logs", role: .destructive) {
                    ThreatDatabase.shared.clearAllEvents()
                    loadEvents()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes all on-device threat activity logs from your iPhone.")
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

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(HistoryFilter.allCases) { filter in
                let isSelected = selectedFilter == filter
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedFilter = filter
                }) {
                    Text(filter.rawValue)
                        .font(RetroTheme.buttonSmall)
                        .foregroundColor(isSelected ? RetroTheme.primaryContrast : RetroTheme.foreground)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(isSelected ? RetroTheme.primary : RetroTheme.content1)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(RetroTheme.border, lineWidth: 1)
                        )
                }
            }
            Spacer()
        }
    }

    private var emptyStateView: some View {
        AppEmptyState(
            icon: "shield.lefthalf.filled",
            title: searchText.isEmpty ? "0 Threats Logged" : "No Matching Records",
            subtitle: searchText.isEmpty ?
                 "On-device SQLite filter active. Blocked scam texts and malicious Safari links will be cataloged here." :
                 "Try searching with an alternate keyword or domain query.",
            badgeText: "SYSTEM SECURED",
            badgeColor: .accent
        )
    }

    private func eventCard(for event: ThreatEventRecord) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    HStack(spacing: 6) {
                        Image(systemName: event.source == "sms" ? "message.badge.filled.fill" : "safari.fill")
                            .font(RetroTheme.captionLarge)
                            .foregroundColor(RetroTheme.accent)

                        Text(title(for: event))
                            .font(RetroTheme.bodyMedium)
                            .foregroundColor(RetroTheme.foreground)
                            .lineLimit(1)
                    }

                    Spacer()

                    AppBadge(badgeTitle(for: event), color: .danger, isFilled: true)
                }

                if let sender = event.sender, !sender.isEmpty {
                    Text("FROM: \(sender)")
                        .font(RetroTheme.captionSmall)
                        .foregroundColor(RetroTheme.secondaryForeground)
                }

                Text(event.target)
                    .font(RetroTheme.captionMedium)
                    .foregroundColor(RetroTheme.foreground)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RetroTheme.content1)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(RetroTheme.border, lineWidth: 1)
                    )

                HStack {
                    Text("\(event.timestamp, style: .relative) ago // \(event.category.uppercased())")
                        .font(RetroTheme.captionSmall)
                        .foregroundColor(RetroTheme.secondaryForeground)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(RetroTheme.captionSmall)
                        .foregroundColor(RetroTheme.secondaryForeground)
                }
            }
            .padding(14)
        }
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
            return "\(cleanBrand) Phishing"
        } else if let url = URL(string: event.target), let host = url.host, !host.isEmpty {
            return host
        } else {
            return event.source == "sms" ? "Suspicious SMS" : "Malicious Website"
        }
    }

    private func badgeTitle(for event: ThreatEventRecord) -> String {
        return event.source == "sms" ? "JUNK" : "BLOCKED"
    }
}
