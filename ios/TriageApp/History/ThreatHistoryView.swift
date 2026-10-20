import SwiftUI

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
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(HistoryFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                if filteredEvents.isEmpty {
                    emptyStateView
                } else {
                    List {
                        Section {
                            ForEach(filteredEvents) { event in
                                eventRow(for: event)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedEvent = event
                                    }
                            }
                            .onDelete(perform: deleteEvents)
                        } header: {
                            Text("\(filteredEvents.count) Blocked Threats")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        loadEvents()
                    }
                }
            }
            .navigationTitle("Threat History")
            .searchable(text: $searchText, prompt: "Search blocked links or senders...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !events.isEmpty {
                        Button(role: .destructive, action: { showingClearConfirmation = true }) {
                            Text("Clear")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .confirmationDialog(
                "Clear History",
                isPresented: $showingClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear All Threat History", role: .destructive) {
                    ThreatDatabase.shared.clearAllEvents()
                    loadEvents()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all on-device threat activity logs from your phone.")
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
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.shield.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.green)
            }

            VStack(spacing: 6) {
                Text(searchText.isEmpty ? "No Threats Detected" : "No Matching Events")
                    .font(.headline)
                    .fontWeight(.bold)

                Text(searchText.isEmpty ?
                     "Triage is actively guarding your SMS messages and Safari browsing. Blocked threats will be logged here locally on your device." :
                     "Try searching with a different term or URL.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private func eventRow(for event: ThreatEventRecord) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Source Icon Badge
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill((event.source == "sms" ? Color.green : Color.blue).opacity(0.15))
                    .frame(width: 38, height: 38)

                Image(systemName: event.source == "sms" ? "message.badge.filled.fill" : "safari.fill")
                    .font(.system(size: 17))
                    .foregroundColor(event.source == "sms" ? .green : .blue)
            }
            .padding(.top, 2)

            // Content
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(title(for: event))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    Text(badgeTitle(for: event))
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.12))
                        .foregroundColor(.red)
                        .clipShape(Capsule())
                }

                if let sender = event.sender, !sender.isEmpty {
                    Text("From: \(sender)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }

                Text(event.target)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack {
                    Text("\(event.timestamp, style: .relative) ago")
                        .font(.caption2)
                        .foregroundColor(Color(.tertiaryLabel))
                    Spacer()
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 2)
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

    private func deleteEvents(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { filteredEvents[$0] }
        for item in itemsToDelete {
            ThreatDatabase.shared.deleteEvent(id: item.id)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        loadEvents()
    }

    private func title(for event: ThreatEventRecord) -> String {
        if let brand = event.targetBrand, !brand.isEmpty {
            return "\(brand) Phishing"
        } else {
            return event.source == "sms" ? "Suspicious SMS Blocked" : "Malicious URL Blocked"
        }
    }

    private func badgeTitle(for event: ThreatEventRecord) -> String {
        return event.source == "sms" ? "JUNK" : "BLOCKED"
    }
}
