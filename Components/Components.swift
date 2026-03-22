import SwiftUI

// MARK: - Design System

extension Color {
    static let background = Color(UIColor.systemGroupedBackground)
    static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.93)
}


struct ClassCard: View {
    let item: ClassItem
    var isActive: Bool = false

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(item.color)
                .frame(width: 4)
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.subject)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Spacer()
                    HStack(spacing: 4) {
                        if item.isRemote {
                            Image(systemName: "wifi")
                                .font(.system(size: 10))
                                .foregroundStyle(item.color)
                        }
                        Text(item.type.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(item.color)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(item.color.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                Text("\(timeFormatter.string(from: item.startTime)) – \(timeFormatter.string(from: item.endTime))")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Label(item.isRemote ? "Zdalnie" : item.room,
                          systemImage: item.isRemote ? "wifi" : "door.left.hand.open")
                    Label(item.lecturer, systemImage: "person.fill")
                }
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            .padding(.leading, 12)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isActive ? item.color.opacity(0.08) : Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(isActive ? item.color.opacity(0.3) : .clear, lineWidth: 1.5)
                )
        )
    }
}


struct NextClassCard: View {
    let item: ClassItem
    let minutesUntil: Int

    private var timeFormatter: DateFormatter {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(item.color).frame(width: 50, height: 50)
                Image(systemName: item.isRemote ? "wifi" : "book.fill")
                    .font(.system(size: 20)).foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Następne zajęcia")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                Text(item.subject)
                    .font(.system(size: 17, weight: .bold))
                    .lineLimit(1)
                Text("\(timeFormatter.string(from: item.startTime)) · \(item.isRemote ? "Zdalnie" : item.room)")
                    .font(.system(size: 13)).foregroundStyle(.secondary)
            }

            Spacer()

            Text("za \(minutesUntil) min")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(item.color)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(item.color.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        )
    }
}


struct TaskRow: View {
    @Binding var item: TaskItem
    var onToggle: (Bool) -> Void = { _ in }

    private var deadlineText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(item.deadline) { return "Dziś" }
        if calendar.isDateInTomorrow(item.deadline) { return "Jutro" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: item.deadline)
    }

    private var isOverdue: Bool {
        item.deadline < Date() && !item.isCompleted
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                item.isCompleted.toggle()
                onToggle(item.isCompleted)
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(item.isCompleted ? item.color : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if item.isCompleted {
                        Circle()
                            .fill(item.color)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 15, weight: .medium))
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                HStack(spacing: 6) {
                    Text(item.subject)
                        .font(.system(size: 12))
                        .foregroundStyle(item.color)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(deadlineText)
                        .font(.system(size: 12))
                        .foregroundStyle(isOverdue ? .red : .secondary)
                }
            }

            Spacer()

            RoundedRectangle(cornerRadius: 3)
                .fill(item.color)
                .frame(width: 3, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}


struct ExamCard: View {
    let item: ExamItem

    private var dateText: String {
        let f = DateFormatter()
        f.dateFormat = "d MMM, HH:mm"
        return f.string(from: item.date)
    }

    private var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: item.date).day ?? 0
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(item.color.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(item.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.subject)
                    .font(.system(size: 15, weight: .semibold))
                Text(dateText + " · " + item.room)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text(item.type.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(item.color)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("\(max(0, daysUntil))")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(item.color)
                Text("days")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Week Day Selector (with week navigation)

struct WeekDaySelector: View {
    @Binding var selectedDate: Date
    @EnvironmentObject var store: ScheduleStore
    private let calendar = Calendar.current

    private var weekMonday: Date {
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysToMon = (weekday == 1) ? -6 : (2 - weekday)
        return calendar.date(byAdding: .day, value: daysToMon, to: selectedDate)!
    }

    private var weekDays: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekMonday) }
    }

    private var monthLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pl_PL")
        f.dateFormat = "LLLL yyyy"
        return f.string(from: selectedDate).capitalized
    }

    private func shiftWeek(by weeks: Int) {
        if let newDate = calendar.date(byAdding: .weekOfYear, value: weeks, to: selectedDate) {
            selectedDate = newDate
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            // Month label + navigation
            HStack {
                Button { shiftWeek(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.orange)
                        .frame(width: 32, height: 32)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Circle())
                }

                Spacer()

                Button { selectedDate = Date() } label: {
                    Text(monthLabel)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                }

                Spacer()

                Button { shiftWeek(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.orange)
                        .frame(width: 32, height: 32)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)

            HStack(spacing: 4) {
                ForEach(weekDays, id: \.self) { date in
                    DayCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isFreeDay: store.isFreeDay(date)
                    )
                    .onTapGesture { selectedDate = date }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)
        }
    }
}

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    var isFreeDay: Bool = false
    private let calendar = Calendar.current

    private var dayLetter: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pl_PL")
        f.dateFormat = "EEE"
        return String(f.string(from: date).prefix(2)).uppercased()
    }

    private var dayNumber: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }

    private var isToday: Bool { calendar.isDateInToday(date) }

    var body: some View {
        VStack(spacing: 4) {
            Text(dayLetter)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isSelected ? .white : (isFreeDay ? .red : .secondary))

            ZStack {
                Circle()
                    .fill(
                        isSelected ? Color.orange :
                        isToday ? Color.orange.opacity(0.15) :
                        isFreeDay ? Color.red.opacity(0.1) :
                        Color.clear
                    )
                    .frame(width: 34, height: 34)

                Text(dayNumber)
                    .font(.system(size: 15, weight: isSelected || isToday ? .bold : .regular))
                    .foregroundStyle(
                        isSelected ? Color.white :
                        isToday ? Color.orange :
                        isFreeDay ? Color.red :
                        Color.primary
                    )

                // Red dot for free day
                if isFreeDay && !isSelected {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 5, height: 5)
                        .offset(x: 11, y: -11)
                }
            }
        }
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.orange : Color.clear)
        )
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .bold))
            Spacer()
            if let action = action {
                Button(action: { onAction?() }) {
                    Text(action)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}
