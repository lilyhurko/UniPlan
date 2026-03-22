import SwiftUI
import Foundation

struct ParsedSchedule {
    var classes: [ClassItem]

    var lecturers: [String] {
        Array(Set(classes.map { $0.lecturer })).filter { $0 != "Prowadzący" }.sorted()
    }
    var rooms: [String] {
        Array(Set(classes.map { $0.room })).filter { $0 != "TBA" }.sorted()
    }
    var groups: [String] {
        Array(Set(classes.compactMap { $0.group })).sorted()
    }
    var subjects: [String] {
        Array(Set(classes.map { $0.subject })).sorted()
    }

    func classesByLecturer() -> [String: [ClassItem]] {
        Dictionary(grouping: classes, by: { $0.lecturer })
    }
    func classesByRoom() -> [String: [ClassItem]] {
        Dictionary(grouping: classes, by: { $0.room })
    }
    func classesByGroup() -> [String: [ClassItem]] {
        Dictionary(grouping: classes.filter { $0.group != nil }, by: { $0.group! })
    }
    func classesBySubject() -> [String: [ClassItem]] {
        Dictionary(grouping: classes, by: { $0.subject })
    }
    func classes(forLecturer l: String) -> [ClassItem] {
        classes.filter { $0.lecturer == l }.sorted { $0.startTime < $1.startTime }
    }
    func classes(forRoom r: String) -> [ClassItem] {
        classes.filter { $0.room == r }.sorted { $0.startTime < $1.startTime }
    }
    func classes(forGroup g: String) -> [ClassItem] {
        classes.filter { $0.group == g }.sorted { $0.startTime < $1.startTime }
    }
}

struct ICSParserService {

    // MARK: - Public

    static func parseICS(fileURL: URL) -> ParsedSchedule {
        let content: String
        if let utf8 = try? String(contentsOf: fileURL, encoding: .utf8) {
            content = utf8
        } else if let latin = try? String(contentsOf: fileURL, encoding: .isoLatin1) {
            content = latin
        } else {
            return ParsedSchedule(classes: [])
        }
        return parseContent(content)
    }

    static func parseContent(_ raw: String) -> ParsedSchedule {

        let unfolded = raw
            .replacingOccurrences(of: "\r\n ", with: "")
            .replacingOccurrences(of: "\r\n\t", with: "")
            .replacingOccurrences(of: "\n ", with: "")
            .replacingOccurrences(of: "\n\t", with: "")

        let lines = unfolded
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var classes: [ClassItem] = []
        var subjectColorMap: [String: Color] = [:]
        let palette: [Color] = [
            .orange,
            Color(red: 0.3,  green: 0.6,  blue: 0.9),
            Color(red: 0.25, green: 0.72, blue: 0.45),
            Color(red: 0.65, green: 0.35, blue: 0.85),
            Color(red: 0.9,  green: 0.4,  blue: 0.4),
            Color(red: 0.2,  green: 0.7,  blue: 0.8),
            Color(red: 0.85, green: 0.6,  blue: 0.2),
        ]

        var inEvent = false
        var summary = ""
        var dtStart: Date?
        var dtEnd: Date?

        for line in lines {
            if line == "BEGIN:VEVENT" {
                inEvent = true
                summary = ""; dtStart = nil; dtEnd = nil

            } else if line == "END:VEVENT", inEvent {
                inEvent = false
                guard let start = dtStart, let end = dtEnd, !summary.isEmpty else { continue }

                let parsed = parseSummary(summary)

                if subjectColorMap[parsed.subject] == nil {
                    subjectColorMap[parsed.subject] = palette[subjectColorMap.count % palette.count]
                }

                classes.append(ClassItem(
                    subject: parsed.subject,
                    lecturer: parsed.lecturer,
                    room: parsed.room,
                    startTime: start,
                    endTime: end,
                    dayOfWeek: Calendar.current.component(.weekday, from: start),
                    color: subjectColorMap[parsed.subject]!,
                    type: parsed.classType,
                    group: parsed.group
                ))

            } else if inEvent {
                if line.hasPrefix("SUMMARY:") {
                    summary = unescape(String(line.dropFirst(8)))
                } else if line.uppercased().hasPrefix("DTSTART") {
                    dtStart = parseDate(line)
                } else if line.uppercased().hasPrefix("DTEND") {
                    dtEnd = parseDate(line)
                }
            }
        }

        return ParsedSchedule(classes: classes.sorted { $0.startTime < $1.startTime })
    }


    private struct ParsedSummary {
        var subject: String
        var lecturer: String
        var room: String
        var classType: ClassType
        var group: String?
        var isRemote: Bool
    }

    private static func parseSummary(_ summary: String) -> ParsedSummary {

        let isRemote = summary.lowercased().contains("zdalny") || summary.lowercased().contains("online")

        let typeKeywords = ["- tyg", "wy ", "lab ", "ćw ", "proj ", "lekt ", "sem ", "ćwicz"]

        var typeRange: Range<String.Index>? = nil
        var detectedType: ClassType = .lecture
        var typeKeywordFound = ""

        for keyword in typeKeywords {
            if let range = summary.range(of: keyword, options: .caseInsensitive) {

                if range.lowerBound > summary.startIndex {
                    if typeRange == nil || range.lowerBound < typeRange!.lowerBound {
                        typeRange = range
                        typeKeywordFound = keyword.trimmingCharacters(in: .whitespaces)
                    }
                }
            }
        }

        switch typeKeywordFound.lowercased() {
        case "lab":           detectedType = .lab
        case "ćw", "ćwicz":  detectedType = .exercise
        case "proj":          detectedType = .exercise
        case "lekt":          detectedType = .seminar
        case "sem":           detectedType = .seminar
        default:              detectedType = .lecture
        }


        var subject: String
        if let typeStart = typeRange {
            subject = String(summary[..<typeStart.lowerBound])
        } else {

            subject = summary
        }

        subject = subject
            .replacingOccurrences(of: #"\s*[-–]\s*zdalny\s*"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s*[-–]\s*tyg\.[IVX]+.*$"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\(zdalny\)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s*bez \d+\.\d+.*?\)"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ",-–/ "))
            .trimmingCharacters(in: .whitespacesAndNewlines)


        if let slashRange = subject.range(of: " / ") {
            subject = String(subject[..<slashRange.lowerBound])
        }
        if subject.isEmpty { subject = summary }


        var lecturer = "Prowadzący"
        var room = isRemote ? "Zdalnie" : "TBA"

        if let typeStart = typeRange {
            
            let afterType = String(summary[typeStart.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)


            lecturer = extractLecturerPL(from: afterType)
            room = extractRoomPL(from: afterType, isRemote: isRemote)
        }


        let group: String? = nil

        return ParsedSummary(
            subject: subject,
            lecturer: lecturer,
            room: room,
            classType: detectedType,
            group: group,
            isRemote: isRemote
        )
    }


    private static func extractLecturerPL(from text: String) -> String {

        let pattern = #"(?:dr\s+hab\.inż\.|dr\s+hab\.|dr\s+inż\.|dr|mgr\s+inż\.|mgr|prof|lekt\.?)\s*[A-ZŁŚŻŹĆŃÓĄ](?:[a-złśżźćńóąA-ZŁŚŻŹĆŃÓĄ\.]*\.)+\s*[A-ZŁŚŻŹĆŃÓĄ][a-złśżźćńóą\-]+"#

        if let range = text.range(of: pattern, options: .regularExpression) {
            var result = String(text[range])

            let afterMatch = String(text[range.upperBound...])
            if afterMatch.lowercased().hasPrefix(", prof") {
                let profEnd = afterMatch.range(of: #",\s*prof[^\s,]*(?:\s+uczelni)?"#,
                                               options: .regularExpression)?.upperBound
                if let end = profEnd {
                    result += String(afterMatch[..<end])
                }
            }
            return result.trimmingCharacters(in: .whitespacesAndNewlines)
        }


        let roomPattern = #"\s+(?:[A-Z]{1,4}\s+\d{1,4}|[A-Z]\d{3,4}|PE\s*\d+|CT\s*\d+|E\d{3})\s*$"#
        if let roomRange = text.range(of: roomPattern, options: .regularExpression) {
            let beforeRoom = String(text[..<roomRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !beforeRoom.isEmpty { return beforeRoom }
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }


    private static func extractRoomPL(from text: String, isRemote: Bool) -> String {
        if isRemote { return "Zdalnie" }


        let patterns = [
            #"(?:CT|PE|E|A|B|C|D)\s*\d{1,4}[a-zA-Z]?\s*$"#,
            #"[A-Z]{1,3}\s+\d{1,4}[a-zA-Z]?\s*$"#,            #"\bsala\s+\d{1,4}[a-zA-Z]?\b"#,
            #"\baula\s*[A-Za-z0-9]*\b"#,
        ]

        for pattern in patterns {
            if let range = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                return String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return "TBA"
    }

    private static func parseDate(_ line: String) -> Date? {
        guard let colon = line.firstIndex(of: ":") else { return nil }
        let value = String(line[line.index(after: colon)...])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")

        if value.hasSuffix("Z") {
            f.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
            f.timeZone = TimeZone(identifier: "UTC")
        } else if value.contains("T") {
            f.dateFormat = "yyyyMMdd'T'HHmmss"
            f.timeZone = TimeZone(identifier: "Europe/Warsaw") ?? .current
        } else {
            f.dateFormat = "yyyyMMdd"
            f.timeZone = .current
        }
        return f.date(from: value)
    }

    private static func unescape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\n", with: "\n")
         .replacingOccurrences(of: "\\,", with: ",")
         .replacingOccurrences(of: "\\;", with: ";")
         .replacingOccurrences(of: "\\\\", with: "\\")
    }
}
