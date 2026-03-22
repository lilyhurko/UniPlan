import SwiftUI
import UniformTypeIdentifiers


struct ImportAndBrowseView: View {
    @Binding var importedClasses: [ClassItem]
    @Environment(\.dismiss) private var dismiss

    @State private var schedule: ParsedSchedule? = nil
    @State private var errorMessage: String? = nil
    @State private var selectedTab: BrowseTab = .lecturers
    @State private var showFilePicker = false

    enum BrowseTab: String, CaseIterable {
        case lecturers = "Lecturers"
        case rooms     = "Rooms"
        case subjects  = "Subjects"

        var icon: String {
            switch self {
            case .lecturers: return "person.2.fill"
            case .rooms:     return "door.left.hand.open"
            case .subjects:  return "book.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let schedule = schedule {

                    ScheduleStatsBar(schedule: schedule)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(BrowseTab.allCases, id: \.self) { tab in
                                BrowseTabChip(
                                    tab: tab,
                                    isSelected: selectedTab == tab,
                                    count: countFor(tab: tab, schedule: schedule)
                                ) { selectedTab = tab }
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                    }

                    Divider()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            switch selectedTab {
                            case .lecturers:
                                BrowseGroupedList(
                                    groups: schedule.classesByLecturer(),
                                    icon: "person.fill",
                                    emptyText: "No lecturers found"
                                )
                            case .rooms:
                                BrowseGroupedList(
                                    groups: schedule.classesByRoom(),
                                    icon: "door.left.hand.open",
                                    emptyText: "No rooms found"
                                )
                            case .subjects:
                                BrowseGroupedList(
                                    groups: schedule.classesBySubject(),
                                    icon: "book.fill",
                                    emptyText: "No subjects found"
                                )
                            }
                        }
                        .padding(.bottom, 32)
                    }

                } else {
                    ImportPromptView(onTap: { showFilePicker = true })
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Import Schedule")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if schedule != nil {
                        Button {
                            importedClasses = schedule?.classes ?? []
                            dismiss()
                        } label: {
                            Text("Use schedule")
                                .fontWeight(.semibold)
                                .foregroundStyle(.orange)
                        }
                    } else {
                        Button {
                            showFilePicker = true
                        } label: {
                            Label("Import .ics", systemImage: "square.and.arrow.down")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [
                    UTType(filenameExtension: "ics") ?? .data,
                    UTType(mimeType: "text/calendar") ?? .plainText,
                    .plainText,
                    .text,
                    .data
                ],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
        }
    }


    private func countFor(tab: BrowseTab, schedule: ParsedSchedule) -> Int {
        switch tab {
        case .lecturers: return schedule.lecturers.count
        case .rooms:     return schedule.rooms.count
        case .subjects:  return schedule.subjects.count
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }

            let parsed = ICSParserService.parseICS(fileURL: url)
            if parsed.classes.isEmpty {
                errorMessage = "No classes found. Make sure it's a valid ICS file."
            } else {
                errorMessage = nil
                schedule = parsed
            }
        case .failure(let error):
            errorMessage = "Import failed: \(error.localizedDescription)"
        }
    }
}


struct ScheduleStatsBar: View {
    let schedule: ParsedSchedule

    var body: some View {
        HStack(spacing: 0) {
            StatCell(value: schedule.classes.count,    label: "classes",   color: .orange)
            Divider().frame(height: 32)
            StatCell(value: schedule.lecturers.count,  label: "lecturers", color: Color(red: 0.3, green: 0.6, blue: 0.9))
            Divider().frame(height: 32)
            StatCell(value: schedule.rooms.count,      label: "rooms",     color: Color(red: 0.25, green: 0.72, blue: 0.45))
            Divider().frame(height: 32)
            StatCell(value: schedule.subjects.count,   label: "subjects",  color: Color(red: 0.65, green: 0.35, blue: 0.85))
        }
        .padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
}

private struct StatCell: View {
    let value: Int; let label: String; let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)").font(.system(size: 20, weight: .bold)).foregroundStyle(color)
            Text(label).font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}


struct BrowseTabChip: View {
    let tab: ImportAndBrowseView.BrowseTab
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: tab.icon).font(.system(size: 12))
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isSelected ? .white : .secondary)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.secondary.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(isSelected ? Color.orange : Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}


struct BrowseGroupedList: View {
    let groups: [String: [ClassItem]]
    let icon: String
    let emptyText: String

    private var sortedKeys: [String] { groups.keys.sorted() }

    var body: some View {
        if groups.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 36)).foregroundStyle(.orange.opacity(0.3))
                Text(emptyText)
                    .font(.system(size: 14)).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity).padding(.top, 60)
        } else {
            VStack(spacing: 12) {
                ForEach(sortedKeys, id: \.self) { key in
                    GroupSection(title: key, icon: icon, classes: groups[key] ?? [])
                }
            }
            .padding(.horizontal, 16).padding(.top, 16)
        }
    }
}

struct GroupSection: View {
    let title: String
    let icon: String
    let classes: [ClassItem]
    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(classes.first?.color.opacity(0.15) ?? Color.orange.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: icon)
                            .font(.system(size: 15))
                            .foregroundStyle(classes.first?.color ?? .orange)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Text("\(classes.count) class\(classes.count == 1 ? "" : "es")")
                            .font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 6) {
                    ForEach(classes) { CompactClassRow(item: $0) }
                }
                .padding(.horizontal, 14).padding(.bottom, 14)
            }
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}


struct CompactClassRow: View {
    let item: ClassItem

    private var timeText: String {
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM, HH:mm"
        f.timeZone = TimeZone(identifier: "Europe/Warsaw") ?? .current
        return f.string(from: item.startTime)
    }

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2).fill(item.color).frame(width: 3, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.subject).font(.system(size: 13, weight: .semibold))
                HStack(spacing: 6) {
                    Text(timeText).font(.system(size: 11)).foregroundStyle(.secondary)
                    if item.room != "TBA" {
                        Text("·").foregroundStyle(.tertiary)
                        Text(item.room).font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Text(item.type.rawValue)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(item.color)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(item.color.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.vertical, 6)
    }
}


struct ImportPromptView: View {
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            VStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.orange.opacity(0.1)).frame(width: 90, height: 90)
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40)).foregroundStyle(.orange)
                }
                Text("Import ICS Schedule")
                    .font(.system(size: 22, weight: .bold))
                Text("Import your timetable from Politechnika Lubelska.\nAfter import browse classes by lecturer, room or subject.")
                    .font(.system(size: 14)).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 32)
            }

            VStack(spacing: 16) {
                Button(action: onTap) {
                    HStack(spacing: 10) {
                        Image(systemName: "doc.fill")
                        Text("Choose .ics file")
                    }
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.orange).foregroundStyle(.white)
                    .font(.system(size: 16, weight: .semibold))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                VStack(spacing: 4) {
                    Text("How to get your ICS file:")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                    Text("planzajec.pollub.pl → your schedule → Export/Download → .ics")
                        .font(.system(size: 12)).foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }
}
