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
        public static let rfc3339 : String = "yyyy-MM-dd'T'HH:mm:ssZZ"
        public static let iso8601DateOnly : String = "yyyy-MM-dd"
        public static let iso8601TimeOnly : String = "HH:mm:ss"
        public static let iso8601DateTime : String = "yyyy-MM-dd HH:mm:ss"
        public static let timeOfDay : String = "h:mm a"
        public static let dayOfMonth : String = "d"
        public static let numericMonthOfYear : String = "L"
        public static let shortMonthOfYear : String = "LLL"
        public static let longMonthOfYear : String = "LLLL"
        public static let shortDayOfWeek : String = "EE"
        public static let longDayOfWeek : String = "EEEE"
        public static let twoDigitYear : String = "yy"
        public static let fourDigitYear : String = "yyyy"
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
            uuSharedFormatterCache[format] = df!
        }
        
        return df!
    }
}

public extension Date
{
    public func uuFormat(_ format : String, timeZone : TimeZone = TimeZone.current, locale : Locale = Locale.current) -> String
    {
        let df = DateFormatter.uuCachedFormatter(format)
        df.timeZone = timeZone
        df.locale = locale
        
        return df.string(from: self)
    }
    
    public func uuRfc3339String(timeZone : TimeZone = TimeZone.current, locale : Locale = Locale.current) -> String
    {
        return uuFormat(UUDate.Formats.rfc3339, timeZone: timeZone, locale: locale)
    }
    
    public func uuRfc3339StringUtc(locale : Locale = Locale.current) -> String
    {
        return uuFormat(UUDate.Formats.rfc3339, timeZone: TimeZone(abbreviation: "UTC")!, locale: locale)
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
}
