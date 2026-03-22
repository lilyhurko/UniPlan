import SwiftUI


struct ExamsSection: View {
    @EnvironmentObject var examStore: ExamStore
    @State private var showAdd = false
    @State private var editingExam: ExamItem? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Egzaminy i zaliczenia", action: "+ Dodaj") {
                showAdd = true
            }

            if examStore.exams.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 32)).foregroundStyle(.orange.opacity(0.4))
                    Text("Brak egzaminów")
                        .font(.system(size: 14)).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity).padding(.top, 12)
            } else {
                VStack(spacing: 8) {
                    ForEach(examStore.exams.sorted { $0.date < $1.date }) { exam in
                        ExamCard(item: exam)
                            .padding(.horizontal, 20)
                            .onTapGesture { editingExam = exam }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    examStore.delete(exam)
                                } label: {
                                    Label("Usuń", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    editingExam = exam
                                } label: {
                                    Label("Edytuj", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                    }
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            ExamEditSheet(exam: nil)
        }
        .sheet(item: $editingExam) { exam in
            ExamEditSheet(exam: exam)
        }
    }
}


struct ExamEditSheet: View {
    let exam: ExamItem?
    @EnvironmentObject var examStore: ExamStore
    @Environment(\.dismiss) private var dismiss

    @State private var subject: String
    @State private var date: Date
    @State private var room: String
    @State private var type: ExamType
    @State private var notes: String
    @State private var selectedColor: Color

    private var isEditing: Bool { exam != nil }

    private let subjectSuggestions = [
        "Systemy sztucznej inteligencji",
        "Zaawansowana eksploracja danych",
        "Bezpieczeństwo w sieciach komputerowych",
        "Planowanie i analiza eksperymentu",
        "Internet rzeczy",
        "Metody wnioskowania wielokryterialnego",
        "Etyka i ekonomia biznesu informatycznego",
        "Przygotowanie i publikowanie artykułów",
        "Wykład monograficzny",
        "Język angielski dla informatyków",
    ]

    private let colorOptions: [Color] = [
        .orange,
        Color(red: 0.3, green: 0.6, blue: 0.9),
        Color(red: 0.25, green: 0.72, blue: 0.45),
        Color(red: 0.65, green: 0.35, blue: 0.85),
        Color(red: 0.9, green: 0.4, blue: 0.4),
        Color(red: 0.2, green: 0.7, blue: 0.8),
    ]

    init(exam: ExamItem?) {
        self.exam = exam
        _subject        = State(initialValue: exam?.subject ?? "")
        _date           = State(initialValue: exam?.date ?? Calendar.current.date(byAdding: .month, value: 2, to: Date()) ?? Date())
        _room           = State(initialValue: exam?.room ?? "")
        _type           = State(initialValue: exam?.type ?? .zaliczenie)
        _notes          = State(initialValue: exam?.notes ?? "")
        _selectedColor  = State(initialValue: exam?.color ?? Color(red: 0.3, green: 0.6, blue: 0.9))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Przedmiot") {
                    TextField("Nazwa przedmiotu", text: $subject)

                    if subject.isEmpty || subjectSuggestions.contains(where: { $0.lowercased().contains(subject.lowercased()) && $0 != subject }) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(subjectSuggestions.filter {
                                    subject.isEmpty || $0.lowercased().contains(subject.lowercased())
                                }.prefix(5), id: \.self) { s in
                                    Button(s) { subject = s }
                                        .font(.system(size: 12))
                                        .foregroundStyle(.orange)
                                        .padding(.horizontal, 10).padding(.vertical, 5)
                                        .background(Color.orange.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    }
                }

                Section("Szczegóły") {
                    Picker("Typ", selection: $type) {
                        ForEach(ExamType.allCases, id: \.self) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                    TextField("Sala (np. CT 202)", text: $room)
                }

                Section("Data i godzina") {
                    DatePicker("Data", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .environment(\.locale, Locale(identifier: "pl_PL"))
                }

                Section("Kolor") {
                    HStack(spacing: 12) {
                        ForEach(colorOptions, id: \.toHex) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .strokeBorder(.white, lineWidth: selectedColor.toHex == color.toHex ? 3 : 0)
                                )
                                .overlay(
                                    Circle()
                                        .strokeBorder(color, lineWidth: selectedColor.toHex == color.toHex ? 3 : 0)
                                        .padding(-2)
                                )
                                .onTapGesture { selectedColor = color }
                                .animation(.spring(response: 0.2), value: selectedColor.toHex)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Notatki") {
                    TextField("Np. materiał, zakres, wymagania...", text: $notes, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }

               
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            if let exam { examStore.delete(exam) }
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Usuń egzamin")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edytuj egzamin" : "Nowy egzamin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Zapisz" : "Dodaj") {
                        saveExam()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(subject.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveExam() {
        let newExam = ExamItem(
            id: exam?.id ?? UUID(),
            subject: subject.trimmingCharacters(in: .whitespaces),
            date: date,
            room: room.trimmingCharacters(in: .whitespaces),
            type: type,
            notes: notes.trimmingCharacters(in: .whitespaces),
            color: selectedColor
        )
        if isEditing {
            examStore.update(newExam)
        } else {
            examStore.add(newExam)
        }
    }
}
