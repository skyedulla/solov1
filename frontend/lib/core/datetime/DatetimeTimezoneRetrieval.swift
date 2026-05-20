import Foundation

/// API **`upload_date`** can be (a) client display **`YYYY-MM-DD`** with **`HH:mm:ss`** (no zone), or
/// (b) legacy UTC split from an ISO **`…Z`** instant. Formatting helpers pick the right interpretation.
enum StoredUploadInstantFormatting {
    /// Builds **`yyyy-MM-dd`** and **`HH:mm:ss`** for **`TimeZone.current`** (or another zone) at **`date`** — send on **`POST /storage/files`**.
    static func clientUploadDisplayStrings(
        at date: Date = Date(),
        timeZone: TimeZone = .current,
        calendarLocale: Locale = .current
    ) -> (uploadDate: String, uploadTime: String) {
        let datePart = DateFormatter()
        datePart.locale = calendarLocale
        datePart.timeZone = timeZone
        datePart.dateFormat = "yyyy-MM-dd"

        let timePart = DateFormatter()
        timePart.locale = Locale(identifier: "en_US_POSIX")
        timePart.timeZone = timeZone
        timePart.dateFormat = "HH:mm:ss"

        return (datePart.string(from: date), timePart.string(from: date))
    }

    /// UTC instant when the API used **`Z`**. For display-only **`HH:mm:ss`** strings (no zone), returns **`nil`**.
    static func utcInstant(uploadDate: String, uploadTime: String) -> Date? {
        let trimmedTime = uploadTime.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTime.range(of: #"^\d{2}:\d{2}:\d{2}$"#, options: .regularExpression) != nil {
            return nil
        }

        let combined = "\(uploadDate)T\(uploadTime)"
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = withFractional.date(from: combined) { return d }
        let withoutFractional = ISO8601DateFormatter()
        withoutFractional.formatOptions = [.withInternetDateTime]
        return withoutFractional.date(from: combined)
    }

    /// Formats an absolute **`Date`** (typically a UTC instant from the backend) into
    /// **`yyyy-MM-dd`** and **`HH:mm:ss`** wall-clock parts for **`timeZone`**. Use **`TimeZone.current`**
    /// for the device's local timezone, or **`TimeZone(identifier: "America/New_York")`** etc.
    static func utcInstantToTimezoneDisplayParts(
        _ instant: Date,
        timeZone: TimeZone = .current,
        calendarLocale: Locale = .current
    ) -> (calendarDate: String, wallClockTime: String) {
        let u = clientUploadDisplayStrings(at: instant, timeZone: timeZone, calendarLocale: calendarLocale)
        return (calendarDate: u.uploadDate, wallClockTime: u.uploadTime)
    }

    /// Parses **`isoUtc`** (e.g. **`2026-05-19T05:54:31Z`** / **`...+00:00`**) then returns **`utcInstantToTimezoneDisplayParts`**
    /// as wall clock in **`timeZone`** (**`TimeZone.current`** = user locale).
    static func utcIsoStringToTimezoneDisplayParts(
        _ isoUtc: String,
        timeZone: TimeZone = .current,
        calendarLocale: Locale = .current
    ) -> (calendarDate: String, wallClockTime: String)? {
        let trimmed = isoUtc.trimmingCharacters(in: .whitespacesAndNewlines)
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var instant = withFractional.date(from: trimmed)
        if instant == nil {
            let plain = ISO8601DateFormatter()
            plain.formatOptions = [.withInternetDateTime]
            instant = plain.date(from: trimmed)
        }
        guard let instant else { return nil }
        let parts = utcInstantToTimezoneDisplayParts(
            instant,
            timeZone: timeZone,
            calendarLocale: calendarLocale
        )
        return parts
    }

    static func formattedDateTime(
        uploadDate: String,
        uploadTime: String,
        dateStyle: DateFormatter.Style = .medium,
        timeStyle: DateFormatter.Style = .short,
        locale: Locale = .current,
        timeZone: TimeZone = .current
    ) -> String {
        guard let date = utcInstant(uploadDate: uploadDate, uploadTime: uploadTime) else {
            return "\(uploadDate) \(uploadTime)"
        }
        let f = DateFormatter()
        f.locale = locale
        f.timeZone = timeZone
        f.dateStyle = dateStyle
        f.timeStyle = timeStyle
        return f.string(from: date)
    }

    static func formattedDate(
        uploadDate: String,
        uploadTime: String,
        dateStyle: DateFormatter.Style = .medium,
        locale: Locale = .current,
        timeZone: TimeZone = .current
    ) -> String {
        guard let date = utcInstant(uploadDate: uploadDate, uploadTime: uploadTime) else { return uploadDate }
        let f = DateFormatter()
        f.locale = locale
        f.timeZone = timeZone
        f.dateStyle = dateStyle
        f.timeStyle = .none
        return f.string(from: date)
    }

    static func formattedTime(
        uploadDate: String,
        uploadTime: String,
        timeStyle: DateFormatter.Style = .short,
        locale: Locale = .current,
        timeZone: TimeZone = .current
    ) -> String {
        guard let date = utcInstant(uploadDate: uploadDate, uploadTime: uploadTime) else { return uploadTime }
        let f = DateFormatter()
        f.locale = locale
        f.timeZone = timeZone
        f.dateStyle = .none
        f.timeStyle = timeStyle
        return f.string(from: date)
    }
}
