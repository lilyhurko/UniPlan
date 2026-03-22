import SwiftUI
import Foundation
import Combine


class ScheduleStore: ObservableObject {
    @Published var classes: [ClassItem]
    @Published var deletedIDs: Set<UUID> = []

    private let calendar = Calendar.current


    private let weekIMondays: Set<String> = [
        "2026-02-23","2026-03-02","2026-03-16","2026-03-30",
        "2026-04-13","2026-04-27","2026-05-11","2026-05-25","2026-06-08"
    ]
    private let weekIIMondays: Set<String> = [
        "2026-02-16","2026-03-09","2026-03-23","2026-04-09","2026-04-20",
        "2026-05-04","2026-05-18","2026-06-01","2026-06-15"
    ]

    let freeDays: [String: String] = [
        "2026-04-02": "Wielki Czwartek",
        "2026-04-03": "Wielki Piątek",
        "2026-04-04": "Sobota Wielkanocna",
        "2026-04-05": "Wielkanoc",
        "2026-04-06": "Poniedziałek Wielkanocny",
        "2026-04-07": "Wtorek Wielkanocny",
        "2026-04-08": "Środa Wielkanocna",
        "2026-05-01": "Święto Pracy",
        "2026-05-02": "Sobota",
        "2026-05-03": "Święto Konstytucji",
        "2026-05-13": "Wniebowstąpienie Pańskie",
        "2026-06-04": "Boże Ciało",
    ]

    init() {
        self.classes = loadHardcodedSchedule()
    }


    func weekTypeFor(date: Date) -> String {
        let weekday = calendar.component(.weekday, from: date)
        let daysToMon = (weekday == 1) ? -6 : (2 - weekday)
        guard let mon = calendar.date(byAdding: .day, value: daysToMon, to: date) else { return "I" }
        let monStr = isoDate(mon)
        if weekIMondays.contains(monStr) { return "I" }
        if weekIIMondays.contains(monStr) { return "II" }
        return "I"
    }


    func isFreeDay(_ date: Date) -> Bool {
        freeDays[isoDate(date)] != nil
    }

    func freeDayName(_ date: Date) -> String? {
        freeDays[isoDate(date)]
    }



    func classesFor(date: Date) -> [ClassItem] {
        guard !isFreeDay(date) else { return [] }
        return classes.filter { item in
            guard !item.isDeleted else { return false }
            return calendar.isDate(item.startTime, inSameDayAs: date)
        }.sorted { $0.startTime < $1.startTime }
    }


    func classesForWeek(containing date: Date) -> [ClassItem] {
        let weekday = calendar.component(.weekday, from: date)
        let daysToMon = (weekday == 1) ? -6 : (2 - weekday)
        guard let mon = calendar.date(byAdding: .day, value: daysToMon, to: date) else { return [] }
        let weekDays = (0..<5).compactMap { calendar.date(byAdding: .day, value: $0, to: mon) }
        return classes.filter { item in
            guard !item.isDeleted else { return false }
            guard !isFreeDay(item.startTime) else { return false }
            return weekDays.contains { calendar.isDate(item.startTime, inSameDayAs: $0) }
        }.sorted { $0.startTime < $1.startTime }
    }


    func delete(_ item: ClassItem) {
        if let idx = classes.firstIndex(where: { $0.id == item.id }) {
            classes[idx].isDeleted = true
        }
    }

    func update(_ item: ClassItem) {
        if let idx = classes.firstIndex(where: { $0.id == item.id }) {
            classes[idx] = item
        }
    }


    func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Europe/Warsaw")
        return f.string(from: date)
    }
}
