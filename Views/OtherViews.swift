import SwiftUI


struct SearchView: View {
    @EnvironmentObject var store: ScheduleStore
    @State private var query = ""

    private var results: [ClassItem] {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()
        return store.classes.filter { !$0.isDeleted }.filter {
            $0.subject.lowercased().contains(q) ||
            $0.lecturer.lowercased().contains(q) ||
            $0.room.lowercased().contains(q)
        }
    }

    private let suggestions: [(String, String)] = [
        ("Systemy sztucznej inteligencji", "laptopcomputer"),
        ("Zdalnie", "wifi"),
        ("dr inż.T.Nowicki", "person.fill"),
        ("CT 202", "door.left.hand.open"),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Subject, lecturer, room, group...", text: $query).font(.system(size: 16))
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20).padding(.vertical, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if query.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Quick search")
                                    .font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
                                    .padding(.horizontal, 20)
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 8) {
                                    ForEach(suggestions, id: \.0) { (text, icon) in
                                        Button { query = text } label: {
                                            HStack(spacing: 8) {
                                                Image(systemName: icon).font(.system(size: 13)).foregroundStyle(.orange)
                                                Text(text).font(.system(size: 13, weight: .medium)).foregroundStyle(.primary)
                                                Spacer()
                                            }
                                            .padding(.horizontal, 12).padding(.vertical, 10)
                                            .background(Color(UIColor.secondarySystemGroupedBackground))
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        } else if results.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "magnifyingglass").font(.system(size: 36)).foregroundStyle(.orange.opacity(0.4))
                                Text("No results for \"\(query)\"").font(.system(size: 15)).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity).padding(.top, 60)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(results.count) result\(results.count == 1 ? "" : "s")")
                                    .font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
                                    .padding(.horizontal, 20)
                                ForEach(results) { ClassCard(item: $0).padding(.horizontal, 20) }
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}


struct TasksView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var examStore: ExamStore
    @State private var showingAddTask = false
    @State private var selectedFilter: FilterType = .all
    private let calendar = Calendar.current

    enum FilterType: String, CaseIterable {
        case all = "Wszystkie"
        case today = "Dziś"
        case upcoming = "Nadchodzące"
        case done = "Zrobione"
    }

    private var filteredTasks: [TaskItem] {
        switch selectedFilter {
        case .all:      return taskStore.tasks.filter { !$0.isCompleted }
        case .today:    return taskStore.tasks.filter { !$0.isCompleted && calendar.isDateInToday($0.deadline) }
        case .upcoming: return taskStore.tasks.filter { !$0.isCompleted && $0.deadline > Date() }
        case .done:     return taskStore.tasks.filter { $0.isCompleted }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(FilterType.allCases, id: \.self) { filter in
                                FilterChip(title: filter.rawValue, isSelected: selectedFilter == filter) {
                                    selectedFilter = filter
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    if selectedFilter == .all || selectedFilter == .upcoming {
                        ExamsSection()
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(
                            title: selectedFilter == .done ? "Ukończone" : "Zadania domowe",
                            action: "+ Dodaj"
                        ) { showingAddTask = true }

                        if filteredTasks.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: selectedFilter == .done ? "checkmark.seal.fill" : "tray.fill")
                                    .font(.system(size: 32)).foregroundStyle(.orange.opacity(0.4))
                                Text(selectedFilter == .done ? "Brak ukończonych zadań" : "Nic do zrobienia! 🎉")
                                    .font(.system(size: 14)).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity).padding(.top, 20)
                        } else {
                            VStack(spacing: 6) {
                                ForEach(filteredTasks) { task in
                                    if let idx = taskStore.tasks.firstIndex(where: { $0.id == task.id }) {
                                        TaskRow(item: $taskStore.tasks[idx])
                                            .padding(.horizontal, 20)
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button(role: .destructive) {
                                                    withAnimation {
                                                        taskStore.delete(task)
                                                    }
                                                } label: {
                                                    Label("Usuń", systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Zadania")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.orange)
                            .font(.system(size: 20))
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskSheet()
            }
        }
    }
}

struct FilterChip: View {
    let title: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(isSelected ? Color.orange : Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct AddTaskSheet: View {
    var prefilledSubject: String = ""
    @EnvironmentObject var taskStore: TaskStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var subject = ""
    @State private var deadline = Date()
    @State private var notes = ""

    init(prefilledSubject: String = "") {
        self.prefilledSubject = prefilledSubject
        _subject = State(initialValue: prefilledSubject)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Zadanie") {
                    TextField("Tytuł", text: $title)
                    TextField("Przedmiot", text: $subject)
                }
                Section("Termin") {
                    DatePicker("Data", selection: $deadline, displayedComponents: .date)
                }
                Section("Notatki") {
                    TextField("Opcjonalne notatki...", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle("Nowe zadanie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Dodaj") {
                        taskStore.add(TaskItem(
                            title: title.isEmpty ? "Nowe zadanie" : title,
                            subject: subject,
                            deadline: deadline,
                            notes: notes,
                            isCompleted: false,
                            color: .orange
                        ))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}


struct MoreView: View {
    @Binding var importedClasses: [ClassItem]
    @State private var notificationsEnabled = true
    @State private var notifyMinutesBefore = 15
    @State private var showingImport = false

    var body: some View {
        NavigationStack {
            List {
                Section("Schedule") {
                    Button { showingImport = true } label: {
                        HStack {
                            Label("Import ICS schedule", systemImage: "square.and.arrow.down.fill")
                                .foregroundStyle(.orange)
                            Spacer()
                            if !importedClasses.isEmpty {
                                Text("\(importedClasses.count) classes")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if !importedClasses.isEmpty {
                        NavigationLink {
                            BrowseImportedView(classes: importedClasses)
                        } label: {
                            Label("Browse imported schedule", systemImage: "list.bullet.rectangle")
                        }
                    }
                }

                Section("Notifications") {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Class reminders", systemImage: "bell.fill")
                    }.tint(.orange)
                    if notificationsEnabled {
                        Stepper("Notify \(notifyMinutesBefore) min before",
                                value: $notifyMinutesBefore, in: 5...60, step: 5)
                    }
                }

                Section("Preferences") {
                    NavigationLink { Text("Coming soon").foregroundStyle(.secondary) } label: {
                        Label("Subject colours", systemImage: "paintpalette.fill")
                    }
                    NavigationLink { Text("Coming soon").foregroundStyle(.secondary) } label: {
                        Label("Appearance", systemImage: "moon.fill")
                    }
                }

                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingImport) {
                ImportAndBrowseView(importedClasses: $importedClasses)
            }
        }
    }
}



struct BrowseImportedView: View {
    let classes: [ClassItem]
    @State private var selectedTab: ImportAndBrowseView.BrowseTab = .lecturers

    private var schedule: ParsedSchedule { ParsedSchedule(classes: classes) }

    var body: some View {
        VStack(spacing: 0) {
            ScheduleStatsBar(schedule: schedule)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ImportAndBrowseView.BrowseTab.allCases, id: \.self) { tab in
                        BrowseTabChip(
                            tab: tab, isSelected: selectedTab == tab,
                            count: countFor(tab: tab)
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
                        BrowseGroupedList(groups: schedule.classesByLecturer(), icon: "person.fill", emptyText: "No lecturers")
                    case .rooms:
                        BrowseGroupedList(groups: schedule.classesByRoom(), icon: "door.left.hand.open", emptyText: "No rooms")
                    case .subjects:
                        BrowseGroupedList(groups: schedule.classesBySubject(), icon: "book.fill", emptyText: "No subjects")
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Imported Schedule")
        .navigationBarTitleDisplayMode(.large)
    }

    private func countFor(tab: ImportAndBrowseView.BrowseTab) -> Int {
        switch tab {
        case .lecturers: return schedule.lecturers.count
        case .rooms:     return schedule.rooms.count
        case .subjects:  return schedule.subjects.count
        }
    }
}
