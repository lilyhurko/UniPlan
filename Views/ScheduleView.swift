import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var store: ScheduleStore
    @State private var selectedDate = Date()
    @State private var viewMode: ViewMode = .day

    enum ViewMode: String, CaseIterable { case day = "Dzień"; case week = "Tydzień" }

    private var classesForDate: [ClassItem] {
        store.classesFor(date: selectedDate)
    }

    private var weekBadge: String {
        store.weekTypeFor(date: selectedDate) == "I" ? "Tydzień I" : "Tydzień II"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mode picker
                Picker("", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20).padding(.vertical, 10)

                // Week day selector with embedded week badge
                WeekDaySelector(selectedDate: $selectedDate)
                    .padding(.bottom, 4)

                // Week I/II + date info bar
                HStack(spacing: 8) {
                    Text(weekBadge)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 3)
                        .background(Color.orange)
                        .clipShape(Capsule())

                    if store.isFreeDay(selectedDate) {
                        Text(store.freeDayName(selectedDate) ?? "Dzień wolny")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 10).padding(.vertical, 3)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    Spacer()

                    let count = store.classesFor(date: selectedDate).count
                    if count > 0 {
                        Text("\(count) zajęć")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 8)
                .animation(.easeInOut(duration: 0.2), value: selectedDate)

                Divider()

                ScrollView {
                    if viewMode == .day {
                        DayScheduleView(classes: classesForDate, selectedDate: selectedDate)
                    } else {
                        WeekScheduleView(store: store, selectedDate: selectedDate)
                    }
                }
                .background(Color(UIColor.systemGroupedBackground))
                .gesture(
                    DragGesture(minimumDistance: 40)
                        .onEnded { value in
                            let horizontal = value.translation.width
                            let vertical = abs(value.translation.height)
                            guard abs(horizontal) > vertical else { return }
                            if let newDate = Calendar.current.date(
                                byAdding: .day, value: horizontal < 0 ? 1 : -1,
                                to: selectedDate
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) { selectedDate = newDate }
                            }
                        }
                )
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Plan zajęć")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation { selectedDate = Date() }
                    } label: {
                        Text("Dziś")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
    }
}


struct DayScheduleView: View {
    let classes: [ClassItem]
    let selectedDate: Date
    @EnvironmentObject var store: ScheduleStore

    private var dateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pl_PL")
        f.dateFormat = "EEEE, d MMMM"
        return f.string(from: selectedDate).capitalized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(dateString)
                .font(.system(size: 14, weight: .medium)).foregroundStyle(.secondary)
                .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 10)

            if let holidayName = store.freeDayName(selectedDate) {
                HStack(spacing: 10) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.red)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dzień wolny")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.red)
                        Text(holidayName)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color.red.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.red.opacity(0.2), lineWidth: 1))
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }

            if classes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: store.isFreeDay(selectedDate) ? "sun.max.fill" : "moon.stars.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(store.isFreeDay(selectedDate) ? .yellow : .orange.opacity(0.5))
                    Text(store.isFreeDay(selectedDate) ? "Miłego wolnego! 🎉" : "Brak zajęć")
                        .font(.system(size: 16, weight: .medium)).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity).padding(.top, 40)
            } else {
                VStack(spacing: 8) {
                    ForEach(classes) { item in
                        EditableClassCard(item: item)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }
}


struct WeekScheduleView: View {
    let store: ScheduleStore
    let selectedDate: Date
    private let calendar = Calendar.current

    private var weekDays: [Date] {
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysToMon = (weekday == 1) ? -6 : (2 - weekday)
        let mon = calendar.date(byAdding: .day, value: daysToMon, to: selectedDate)!
        return (0..<5).compactMap { calendar.date(byAdding: .day, value: $0, to: mon) }
    }

    var body: some View {
        VStack(spacing: 16) {
            ForEach(weekDays, id: \.self) { day in
                let dayClasses = store.classesFor(date: day)
                if !dayClasses.isEmpty {
                    WeekDayBlock(date: day, classes: dayClasses)
                        .padding(.horizontal, 20)
                }
            }
        }
        .padding(.vertical, 16)
    }
}

struct WeekDayBlock: View {
    let date: Date
    let classes: [ClassItem]
    private let calendar = Calendar.current

    private var dayLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pl_PL")
        f.dateFormat = "EEE d MMM"
        return f.string(from: date).uppercased()
    }
    private var isToday: Bool { calendar.isDateInToday(date) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(dayLabel)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isToday ? .orange : .secondary)
                if isToday {
                    Text("DZIŚ")
                        .font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.orange).clipShape(Capsule())
                }
            }
            ForEach(classes) { EditableClassCard(item: $0) }
        }
    }
}


struct EditableClassCard: View {
    let item: ClassItem
    @EnvironmentObject var store: ScheduleStore
    @State private var showDetail = false
    @State private var showDeleteAlert = false

    var body: some View {
        ClassCard(item: item)
            .onTapGesture { showDetail = true }
            .contextMenu {
                Button { showDetail = true } label: {
                    Label("Szczegóły / Zadanie", systemImage: "plus.circle")
                }
                Button { showDetail = true } label: {
                    Label("Edytuj", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Usuń z planu", systemImage: "trash")
                }
            }
            .sheet(isPresented: $showDetail) {
                ClassDetailSheet(item: item)
            }
            .alert("Usunąć zajęcia?", isPresented: $showDeleteAlert) {
                Button("Usuń", role: .destructive) { store.delete(item) }
                Button("Anuluj", role: .cancel) {}
            } message: {
                Text("Zajęcia \"\(item.subject)\" zostaną usunięte z planu.")
            }
    }
}



struct ClassDetailSheet: View {
    let item: ClassItem
    @EnvironmentObject var store: ScheduleStore
    @EnvironmentObject var taskStore: TaskStore
    @Environment(\.dismiss) private var dismiss

    @State private var tab: DetailTab = .info
    @State private var showEditClass = false

    enum DetailTab: String, CaseIterable {
        case info = "Info"
        case addTask = "Dodaj zadanie"
    }

    private var timeText: String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        return "\(f.string(from: item.startTime)) – \(f.string(from: item.endTime))"
    }
    private var dateText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pl_PL")
        f.dateFormat = "EEEE, d MMMM"
        return f.string(from: item.startTime).capitalized
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header card
                VStack(spacing: 0) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(item.color.opacity(0.15))
                                .frame(width: 52, height: 52)
                            Image(systemName: item.isRemote ? "wifi" : "building.2.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(item.color)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.subject)
                                .font(.system(size: 17, weight: .bold))
                                .lineLimit(2)
                            Text(dateText)
                                .font(.system(size: 13)).foregroundStyle(.secondary)
                            Text(timeText)
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundStyle(item.color)
                        }
                        Spacer()
                        Text(item.type.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(item.color)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(item.color.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .padding(16)

                    HStack(spacing: 20) {
                        Label(item.isRemote ? "Zdalnie" : item.room,
                              systemImage: item.isRemote ? "wifi" : "door.left.hand.open")
                        Label(item.lecturer, systemImage: "person.fill")
                        Label("Tyg. \(item.week)", systemImage: "calendar")
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16).padding(.bottom, 14)
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))

                Picker("", selection: $tab) {
                    ForEach(DetailTab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(16)

                if tab == .info {
                    ClassInfoTab(item: item, onEdit: { showEditClass = true })
                } else {
                    AddTaskFromClassTab(subject: item.subject)
                }

                Spacer()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Gotowe") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showEditClass) {
                EditClassSheet(item: item)
            }
        }
    }
}

// MARK: - Class Info Tab

struct ClassInfoTab: View {
    let item: ClassItem
    let onEdit: () -> Void
    @EnvironmentObject var taskStore: TaskStore

    private var relatedTasks: [TaskItem] {
        taskStore.tasks.filter { $0.subject == item.subject && !$0.isCompleted }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !item.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Notatki", systemImage: "note.text")
                            .font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
                        Text(item.notes)
                            .font(.system(size: 14))
                            .padding(12)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal, 20)
                }

                if !relatedTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Zadania z tego przedmiotu", systemImage: "checkmark.circle")
                            .font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                        ForEach(relatedTasks) { task in
                            if let idx = taskStore.tasks.firstIndex(where: { $0.id == task.id }) {
                                TaskRow(item: $taskStore.tasks[idx]).padding(.horizontal, 20)
                            }
                        }
                    }
                }

                Button(action: onEdit) {
                    Label("Edytuj zajęcia", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
            }
            .padding(.top, 8).padding(.bottom, 32)
        }
    }
}

// MARK: - Add Task from Class Tab

struct AddTaskFromClassTab: View {
    let subject: String
    @EnvironmentObject var taskStore: TaskStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var deadline = Date()
    @State private var notes = ""
    @State private var saved = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Subject pill (pre-filled, locked)
                HStack {
                    Image(systemName: "book.fill").foregroundStyle(.orange)
                    Text(subject)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11)).foregroundStyle(.tertiary)
                }
                .padding(14)
                .background(Color.orange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.orange.opacity(0.2), lineWidth: 1))
                .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Tytuł zadania").font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
                    TextField("np. Projekt REST API, Sprawozdanie...", text: $title)
                        .font(.system(size: 15))
                        .padding(12)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Termin oddania").font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
                    DatePicker("", selection: $deadline, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding(12)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Notatki (opcjonalnie)").font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
                    TextField("Dodatkowe informacje...", text: $notes, axis: .vertical)
                        .font(.system(size: 14))
                        .lineLimit(3, reservesSpace: true)
                        .padding(12)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 20)

                if saved {
                    Label("Zadanie dodane!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.top, 4)
                }

                Button {
                    guard !title.isEmpty else { return }
                    taskStore.add(TaskItem(
                        title: title,
                        subject: subject,
                        deadline: deadline,
                        notes: notes,
                        isCompleted: false,
                        color: .orange
                    ))
                    title = ""; notes = ""
                    withAnimation { saved = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saved = false }
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Dodaj zadanie")
                    }
                    .frame(maxWidth: .infinity).padding()
                    .background(title.isEmpty ? Color.secondary.opacity(0.2) : Color.orange)
                    .foregroundStyle(title.isEmpty ? Color.secondary : Color.white)
                    .font(.system(size: 16, weight: .semibold))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(title.isEmpty)
                .padding(.horizontal, 20)
            }
            .padding(.top, 8).padding(.bottom, 32)
        }
    }
}


struct EditClassSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: ScheduleStore
    let item: ClassItem

    @State private var subject: String
    @State private var lecturer: String
    @State private var room: String
    @State private var notes: String
    @State private var startTime: Date
    @State private var endTime: Date

    init(item: ClassItem) {
        self.item = item
        _subject  = State(initialValue: item.subject)
        _lecturer = State(initialValue: item.lecturer)
        _room     = State(initialValue: item.room)
        _notes    = State(initialValue: item.notes)
        _startTime = State(initialValue: item.startTime)
        _endTime   = State(initialValue: item.endTime)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Zajęcia") {
                    TextField("Przedmiot", text: $subject)
                    TextField("Prowadzący", text: $lecturer)
                }
                Section("Miejsce i czas") {
                    TextField("Sala", text: $room)
                    DatePicker("Początek", selection: $startTime, displayedComponents: [.hourAndMinute])
                    DatePicker("Koniec", selection: $endTime, displayedComponents: [.hourAndMinute])
                }
                Section("Notatki") {
                    TextField("Notatki do zajęć...", text: $notes, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }
            }
            .navigationTitle("Edytuj zajęcia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Zapisz") {
                        var updated = item
                        updated.subject  = subject
                        updated.lecturer = lecturer
                        updated.room     = room
                        updated.notes    = notes
                        updated.startTime = startTime
                        updated.endTime   = endTime
                        store.update(updated)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    ScheduleView()
        .environmentObject(ScheduleStore())
        .environmentObject(TaskStore())
}
