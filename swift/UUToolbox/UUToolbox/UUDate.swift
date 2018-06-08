//
//  UUDate
//  Useful Utilities - Handy helpers for working with Date's
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

import UIKit

public struct UUDate
{
    public struct Constants
    {
        public static let secondsInOneMinute : TimeInterval = 60
        public static let minutesInOneHour : TimeInterval = 60
        public static let hoursInOneDay : TimeInterval = 24
        public static let daysInOneWeek : TimeInterval = 7
        public static let millisInOneSecond : TimeInterval = 1000
        
        public static let secondsInOneHour : TimeInterval = secondsInOneMinute * minutesInOneHour
        public static let secondsInOneDay : TimeInterval = secondsInOneHour * hoursInOneDay
        public static let secondsInOneWeek : TimeInterval = secondsInOneDay * daysInOneWeek
    }
    
    public struct Formats
    {
        public static let rfc3339               = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        public static let rfc3339WithMillis     = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        public static let iso8601DateOnly       = "yyyy-MM-dd"
        public static let iso8601TimeOnly       = "HH:mm:ss"
        public static let iso8601DateTime       = "yyyy-MM-dd HH:mm:ss"
        public static let timeOfDay             = "h:mm a"
        public static let dayOfMonth            = "d"
        public static let numericMonthOfYear    = "L"
        public static let shortMonthOfYear      = "LLL"
        public static let longMonthOfYear       = "LLLL"
        public static let shortDayOfWeek        = "EE"
        public static let longDayOfWeek         = "EEEE"
        public static let twoDigitYear          = "yy"
        public static let fourDigitYear         = "yyyy"
    }
}

extension DateFormatter
{
    private static var uuSharedFormatterCache : Dictionary<String, DateFormatter> = Dictionary()
    
    public static func uuCachedFormatter(_ format : String) -> DateFormatter
    {
        var df = uuSharedFormatterCache[format]
        if (df == nil)
        {
            df = DateFormatter()
            df!.dateFormat = format
            df!.locale = Locale(identifier: "en_US_POSIX")
            df!.calendar = Calendar(identifier: .gregorian)
            uuSharedFormatterCache[format] = df!
        }
        
        return df!
    }
}

public extension Date
{
    public func uuFormat(_ format : String, timeZone : TimeZone = TimeZone.current) -> String
    {
        let df = DateFormatter.uuCachedFormatter(format)
        df.timeZone = timeZone
        
        return df.string(from: self)
    }
    
    public func uuRfc3339String(timeZone : TimeZone = TimeZone.current) -> String
    {
        return uuFormat(UUDate.Formats.rfc3339, timeZone: timeZone)
    }
    
    public func uuRfc3339StringUtc() -> String
    {
        return uuFormat(UUDate.Formats.rfc3339, timeZone: TimeZone(abbreviation: "UTC")!)
    }
    
    public func uuRfc3339WithMillisStringUtc() -> String
    {
        return uuFormat(UUDate.Formats.rfc3339WithMillis, timeZone: TimeZone(abbreviation: "UTC")!)
    }
    
    public var uuDayOfMonth : String
    {
        return uuFormat(UUDate.Formats.dayOfMonth)
    }
    
    public var uuNumericMonthOfYear : String
    {
        return uuFormat(UUDate.Formats.numericMonthOfYear)
    }
    
    public var uuShortMonthOfYear : String
    {
        return uuFormat(UUDate.Formats.shortMonthOfYear)
    }
    
    public var uuLongMonthOfYear : String
    {
        return uuFormat(UUDate.Formats.longMonthOfYear)
    }
    
    public var uuShortDayOfWeek : String
    {
        return uuFormat(UUDate.Formats.shortDayOfWeek)
    }
    
    public var uuLongDayOfWeek : String
    {
        return uuFormat(UUDate.Formats.longDayOfWeek)
    }
    
    public var uuTwoDigitYear : String
    {
        return uuFormat(UUDate.Formats.twoDigitYear)
    }
    
    public var uuFourDigitYear : String
    {
        return uuFormat(UUDate.Formats.fourDigitYear)
    }
    
    public func uuIsDatePartEqual(_ other: Date) -> Bool
    {
        let cal = Calendar(identifier: .gregorian)
        let parts: Set<Calendar.Component> = [.year, .month, .day]
        
        let thisDate = cal.dateComponents(parts, from: self)
        let otherDate = cal.dateComponents(parts, from: other)
        
        guard   let thisYear = thisDate.year, let thisMonth = thisDate.month, let thisDay = thisDate.day,
                let otherYear = otherDate.year, let otherMonth = otherDate.month, let otherDay = otherDate.day else
        {
            return false
        }
        
        return (thisYear == otherYear) && (thisMonth == otherMonth) && (thisDay == otherDay)
    }
    
    public func uuIsToday() -> Bool
    {
        return uuIsDatePartEqual(Date())
    }
}
