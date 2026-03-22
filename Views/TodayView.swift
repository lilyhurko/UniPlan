import SwiftUI

struct TodayView: View {
    @EnvironmentObject var scheduleStore: ScheduleStore
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var examStore: ExamStore
    private let calendar = Calendar.current

    private var todayClasses: [ClassItem] {
        scheduleStore.classesFor(date: Date())
    }

    private var nextClass: ClassItem? {
        todayClasses.first { $0.startTime > Date() }
    }

    private var minutesUntilNext: Int {
        guard let next = nextClass else { return 0 }
        return max(0, Int(next.startTime.timeIntervalSince(Date()) / 60))
    }

    private var currentClass: ClassItem? {
        todayClasses.first { $0.startTime <= Date() && $0.endTime > Date() }
    }

    private var greeting: String {
        let h = calendar.component(.hour, from: Date())
        if h < 12 { return "Dzień dobry" }
        if h < 17 { return "Miłego popołudnia" }
        return "Dobry wieczór"
    }

    private var todayDateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pl_PL")
        f.dateFormat = "EEEE, d MMMM"
        return f.string(from: Date()).capitalized
    }

    private var weekBadge: String {
        scheduleStore.weekTypeFor(date: Date()) == "I" ? "Tydzień I" : "Tydzień II"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(greeting)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(weekBadge)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Color.orange)
                                .clipShape(Capsule())
                        }
                        Text(todayDateString)
                            .font(.system(size: 28, weight: .bold))
                    }
                    .padding(.horizontal, 20).padding(.top, 8)

                    if let holidayName = scheduleStore.freeDayName(Date()) {
                        HStack(spacing: 10) {
                            Image(systemName: "star.fill").foregroundStyle(.red)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Dzień wolny od zajęć")
                                    .font(.system(size: 13, weight: .bold)).foregroundStyle(.red)
                                Text(holidayName)
                                    .font(.system(size: 12)).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.red.opacity(0.2), lineWidth: 1))
                        .padding(.horizontal, 20)
                    }

                    HStack(spacing: 12) {
                        StatPill(value: "\(todayClasses.count)", label: "zajęć", color: .orange)
                        StatPill(value: "\(taskStore.tasks.filter { !$0.isCompleted }.count)", label: "zadań",
                                 color: Color(red: 0.3, green: 0.6, blue: 0.9))
                        StatPill(value: "\(examStore.exams.count)", label: "egz.",
                                 color: Color(red: 0.65, green: 0.35, blue: 0.85))
                    }
                    .padding(.horizontal, 20)

                    if let current = currentClass {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Teraz trwa")
                            CurrentClassCard(item: current)
                                .padding(.horizontal, 20)
                        }
                    }

                    if let next = nextClass {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Następne zajęcia")
                            NextClassCard(item: next, minutesUntil: minutesUntilNext)
                                .padding(.horizontal, 20)
                        }
                    }

                    if !todayClasses.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Plan na dziś")
                            VStack(spacing: 8) {
                                ForEach(todayClasses) { item in
                                    ClassCard(item: item,
                                              isActive: item.id == currentClass?.id || item.id == nextClass?.id)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 40)).foregroundStyle(.orange.opacity(0.5))
                            Text("Brak zajęć dziś 🎉")
                                .font(.system(size: 16, weight: .medium)).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity).padding(.top, 20)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Zadania")
                        VStack(spacing: 6) {
                            ForEach(taskStore.tasks.filter { !$0.isCompleted }.prefix(3)) { task in
                                if let idx = taskStore.tasks.firstIndex(where: { $0.id == task.id }) {
                                    TaskRow(item: $taskStore.tasks[idx]).padding(.horizontal, 20)
                                }
                            }
                        }
                    }

                    Spacer(minLength: 24)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "bell.fill").foregroundStyle(.orange)
                }
            }
        }
    }
}


struct CurrentClassCard: View {
    let item: ClassItem
    private var endText: String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: item.endTime)
    }
    private var minutesLeft: Int {
        max(0, Int(item.endTime.timeIntervalSince(Date()) / 60))
    }
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(item.color).frame(width: 50, height: 50)
                Image(systemName: "play.fill").font(.system(size: 18)).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("W trakcie").font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white).padding(.horizontal, 8).padding(.vertical, 2)
                    .background(item.color).clipShape(Capsule())
                Text(item.subject).font(.system(size: 16, weight: .bold))
                Text("Kończy się \(endText) · jeszcze \(minutesLeft) min")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer()
            if item.isRemote {
                Image(systemName: "wifi").foregroundStyle(item.color)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(item.color.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(item.color.opacity(0.3), lineWidth: 1.5))
        )
    }
}

private struct StatPill: View {
    let value: String; let label: String; let color: Color
    var body: some View {
        HStack(spacing: 6) {
            Text(value).font(.system(size: 18, weight: .bold)).foregroundStyle(color)
            Text(label).font(.system(size: 13)).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    TodayView()
        .environmentObject(ScheduleStore())
        .environmentObject(TaskStore())
        .environmentObject(ExamStore())
}
