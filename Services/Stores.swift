import SwiftUI
import Combine


private struct SavedExam: Codable {
    let id: UUID
    var subject: String
    var date: Date
    var room: String
    var type: String
    var notes: String
    var colorHex: String
}

private struct SavedTask: Codable {
    let id: UUID
    var title: String
    var subject: String
    var deadline: Date
    var notes: String
    var isCompleted: Bool
    var colorHex: String
}


class ExamStore: ObservableObject {
    @Published var exams: [ExamItem] = []
    private let key = "uniplan_exams_v1"

    init() {
        load()
        if exams.isEmpty { exams = makeDefaultExams() }
    }

    func add(_ exam: ExamItem) { exams.append(exam); save() }
    func update(_ exam: ExamItem) {
        if let i = exams.firstIndex(where: { $0.id == exam.id }) { exams[i] = exam; save() }
    }
    func delete(_ exam: ExamItem) { exams.removeAll { $0.id == exam.id }; save() }

    private func save() {
        let saved = exams.map {
            SavedExam(id: $0.id, subject: $0.subject, date: $0.date,
                      room: $0.room, type: $0.type.rawValue,
                      notes: $0.notes, colorHex: $0.colorHex)
        }
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode([SavedExam].self, from: data) else { return }
        exams = saved.map {
            ExamItem(id: $0.id, subject: $0.subject, date: $0.date,
                     room: $0.room, type: ExamType(rawValue: $0.type) ?? .zaliczenie,
                     notes: $0.notes, color: Color(hex: $0.colorHex) ?? .orange)
        }
    }
}


class TaskStore: ObservableObject {
    @Published var tasks: [TaskItem] = []
    private let key = "uniplan_tasks_v1"

    init() {
        load()
        if tasks.isEmpty { tasks = makeSampleTasks() }
    }

    func add(_ task: TaskItem) { tasks.append(task); save() }

    func update(_ task: TaskItem) {
        if let i = tasks.firstIndex(where: { $0.id == task.id }) { tasks[i] = task; save() }
    }

    func delete(_ task: TaskItem) { tasks.removeAll { $0.id == task.id }; save() }

    func deleteAt(offsets: IndexSet, from filtered: [TaskItem]) {
        let ids = offsets.map { filtered[$0].id }
        tasks.removeAll { ids.contains($0.id) }
        save()
    }

 
    func savePublic() { save() }

    private func save() {
        let saved = tasks.map {
            SavedTask(id: $0.id, title: $0.title, subject: $0.subject,
                      deadline: $0.deadline, notes: $0.notes,
                      isCompleted: $0.isCompleted, colorHex: $0.colorHex)
        }
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode([SavedTask].self, from: data) else { return }
        tasks = saved.map {
            TaskItem(id: $0.id, title: $0.title, subject: $0.subject,
                     deadline: $0.deadline, notes: $0.notes,
                     isCompleted: $0.isCompleted, color: Color(hex: $0.colorHex) ?? .orange)
        }
    }
}
