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
                    searchBar
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)

                    if filteredEvents.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                HStack {
                                    Text("// \(filteredEvents.count) LOGGED EVENT\(filteredEvents.count == 1 ? "" : "S")")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
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
                            RetroBadge("CLEAR", color: .danger, isFilled: false)
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
                    Text("[ \(filter.rawValue) ]")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundColor(isSelected ? RetroTheme.primaryContrast : RetroTheme.foreground)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isSelected ? RetroTheme.primary : RetroTheme.content1)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(RetroTheme.border, lineWidth: isSelected ? 2 : 1)
                        )
                }
            }
            Spacer()
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(RetroTheme.secondaryForeground)

            TextField("Filter links, brands, senders...", text: $searchText)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(RetroTheme.foreground)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(RetroTheme.secondaryForeground)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RetroTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(RetroTheme.border, lineWidth: 1)
        )
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            RetroCard(cornerRadius: 12) {
                VStack(spacing: 14) {
                    ZStack {
                        Rectangle()
                            .fill(RetroTheme.content1)
                            .frame(width: 52, height: 52)
                            .overlay(
                                Rectangle()
                                    .stroke(RetroTheme.border, lineWidth: 1.5)
                            )

                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(RetroTheme.success)
                    }

                    VStack(spacing: 6) {
                        Text(searchText.isEmpty ? "> 0 THREATS LOGGED" : "> NO MATCHING RECORDS")
                            .font(.system(size: 14, weight: .heavy, design: .monospaced))
                            .foregroundColor(RetroTheme.foreground)

                        Text(searchText.isEmpty ?
                             "On-device SQLite filter active. Blocked scam texts and malicious Safari links will be cataloged here." :
                             "Try searching with an alternate keyword or domain query.")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(RetroTheme.secondaryForeground)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }

                    RetroBadge("SYSTEM SECURED", color: .success, isFilled: true)
                }
                .padding(20)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func eventCard(for event: ThreatEventRecord) -> some View {
        RetroCard(cornerRadius: 8) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    HStack(spacing: 6) {
                        Image(systemName: event.source == "sms" ? "message.badge.filled.fill" : "safari.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(event.source == "sms" ? RetroTheme.success : .blue)

                        Text(title(for: event).uppercased())
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                            .foregroundColor(RetroTheme.foreground)
                            .lineLimit(1)
                    }

                    Spacer()

                    RetroBadge(badgeTitle(for: event), color: .danger, isFilled: true)
                }

                if let sender = event.sender, !sender.isEmpty {
                    Text("FROM: \(sender)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(RetroTheme.secondaryForeground)
                }

                Text(event.target)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(RetroTheme.foreground)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RetroTheme.content1)
                    .overlay(
                        Rectangle()
                            .stroke(RetroTheme.border, lineWidth: 1)
                    )

                HStack {
                    Text("\(event.timestamp, style: .relative) ago // \(event.category.uppercased())")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(RetroTheme.secondaryForeground)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
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
