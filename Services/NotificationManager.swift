import Foundation
import UserNotifications


class NotificationManager {

    static let shared = NotificationManager()
    private init() {}


    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func checkPermission() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }



    func scheduleAll(classes: [ClassItem], minutesBefore: Int) async {
        let center = UNUserNotificationCenter.current()

        center.removePendingNotificationRequests(withIdentifiers:
            (await center.pendingNotificationRequests()).map { $0.identifier }.filter { $0.hasPrefix("uniplan-") }
        )

        let now = Date()
        var scheduled = 0

        for item in classes {
            guard !item.isDeleted else { continue }
            guard item.startTime > now else { continue }

            let triggerDate = item.startTime.addingTimeInterval(TimeInterval(-minutesBefore * 60))
            guard triggerDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = item.subject
            content.body = item.isRemote
                ? "Za \(minutesBefore) min · Zdalnie"
                : "Za \(minutesBefore) min · \(item.room)"
            content.sound = .default
            content.badge = 1

            var comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            comps.second = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

            let request = UNNotificationRequest(
                identifier: "uniplan-\(item.id.uuidString)",
                content: content,
                trigger: trigger
            )

            try? await center.add(request)
            scheduled += 1


            if scheduled >= 60 { break }
        }
    }


    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }


    func pendingCount() async -> Int {
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return pending.filter { $0.identifier.hasPrefix("uniplan-") }.count
    }
}
