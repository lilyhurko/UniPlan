import SwiftUI

extension Color {
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if h.hasPrefix("#") { h = String(h.dropFirst()) }
        guard h.count == 6, let rgb = UInt64(h, radix: 16) else { return nil }
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8)  & 0xFF) / 255,
            blue:  Double( rgb        & 0xFF) / 255
        )
    }

    var toHex: String {
        let c = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X",
                      Int(r * 255), Int(g * 255), Int(b * 255))
    }
}


struct ClassItem: Identifiable {
    let id: UUID
    var subject: String
    var lecturer: String
    var room: String
    var startTime: Date
    var endTime: Date
    var dayOfWeek: Int
    var color: Color
    var type: ClassType
    var group: String?
    var week: String
    var isRemote: Bool
    var isDeleted: Bool
    var notes: String

    init(subject: String, lecturer: String, room: String,
         startTime: Date, endTime: Date, dayOfWeek: Int,
         color: Color, type: ClassType,
         group: String? = nil, week: String = "both",
         isRemote: Bool = false, isDeleted: Bool = false, notes: String = "") {
        self.id = UUID()
        self.subject = subject
        self.lecturer = lecturer
        self.room = room
        self.startTime = startTime
        self.endTime = endTime
        self.dayOfWeek = Calendar.current.component(.weekday, from: startTime)
        self.color = color
        self.type = type
        self.group = group
        self.week = week
        self.isRemote = isRemote
        self.isDeleted = isDeleted
        self.notes = notes
    }

    var colorHex: String { color.toHex }
}

enum ClassType: String, CaseIterable {
    case lecture  = "Lecture"
    case lab      = "Lab"
    case seminar  = "Seminar"
    case exercise = "Exercise"
}


struct ExamItem: Identifiable {
    let id: UUID
    var subject: String
    var date: Date
    var room: String
    var type: ExamType
    var notes: String
    var color: Color

    init(id: UUID = UUID(), subject: String, date: Date, room: String,
         type: ExamType, notes: String, color: Color) {
        self.id = id
        self.subject = subject
        self.date = date
        self.room = room
        self.type = type
        self.notes = notes
        self.color = color
    }

    var colorHex: String { color.toHex }
}

enum ExamType: String, CaseIterable {
    case exam       = "Exam"
    case zaliczenie = "Zaliczenie"
    case kolokwium  = "Kolokwium"

    var displayName: String {
        switch self {
        case .exam:       return "Egzamin"
        case .zaliczenie: return "Zaliczenie"
        case .kolokwium:  return "Kolokwium"
        }
    }
}


struct TaskItem: Identifiable, Equatable {
    static func == (lhs: TaskItem, rhs: TaskItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.subject == rhs.subject &&
        lhs.deadline == rhs.deadline &&
        lhs.notes == rhs.notes &&
        lhs.isCompleted == rhs.isCompleted &&
        lhs.colorHex == rhs.colorHex
    }
    let id: UUID
    var title: String
    var subject: String
    var deadline: Date
    var notes: String
    var isCompleted: Bool
    var color: Color

    init(id: UUID = UUID(), title: String, subject: String,
         deadline: Date, notes: String, isCompleted: Bool, color: Color) {
        self.id = id
        self.title = title
        self.subject = subject
        self.deadline = deadline
        self.notes = notes
        self.isCompleted = isCompleted
        self.color = color
    }

    var colorHex: String { color.toHex }
}



func makeDefaultExams() -> [ExamItem] {
    let calendar = Calendar.current
    var c = calendar.dateComponents([.year], from: Date())
    c.month = 6; c.day = 20; c.hour = 10
    let d1 = calendar.date(from: c) ?? Date()
    c.day = 25; c.hour = 12
    let d2 = calendar.date(from: c) ?? Date()
    return [
        ExamItem(subject: "Systemy sztucznej inteligencji", date: d1, room: "CT 202",
                 type: .exam, notes: "Materiał z całego semestru",
                 color: Color(red: 0.3, green: 0.6, blue: 0.9)),
        ExamItem(subject: "Zaawansowana eksploracja danych", date: d2, room: "PE 102",
                 type: .zaliczenie, notes: "Projekt + test",
                 color: Color(red: 0.25, green: 0.72, blue: 0.45)),
    ]
}

func makeSampleTasks() -> [TaskItem] {
    let calendar = Calendar.current
    func dl(_ days: Int) -> Date { calendar.date(byAdding: .day, value: days, to: Date()) ?? Date() }
    return [
        TaskItem(title: "Projekt IoT", subject: "Internet rzeczy",
                 deadline: dl(5), notes: "PE 122", isCompleted: false,
                 color: Color(red: 0.65, green: 0.35, blue: 0.85)),
        TaskItem(title: "Sprawozdanie lab", subject: "Bezpieczeństwo w sieciach",
                 deadline: dl(2), notes: "", isCompleted: false,
                 color: Color(red: 0.2, green: 0.7, blue: 0.8)),
        TaskItem(title: "Artykuł naukowy", subject: "Przygotowanie artykułów",
                 deadline: dl(7), notes: "tyg.I", isCompleted: false,
                 color: .orange),
    ]
}
