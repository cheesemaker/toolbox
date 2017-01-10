//
//  UUDate
//  Useful Utilities - Handy helpers for working with Date's
//
//  Created by Ryan DeVore on 01/06/2017
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//
//  Contact: @ryandevore or ryan@silverpine.com
//

import UIKit

struct UUDate
{
    struct Constants
    {
        static let secondsInOneMinute : TimeInterval = 60
        static let minutesInOneHour : TimeInterval = 60
        static let hoursInOneDay : TimeInterval = 24
        static let daysInOneWeek : TimeInterval = 7
        static let millisInOneSecond : TimeInterval = 1000
        
        static let secondsInOneHour : TimeInterval = secondsInOneMinute * minutesInOneHour
        static let secondsInOneDay : TimeInterval = secondsInOneHour * hoursInOneDay
        static let secondsInOneWeek : TimeInterval = secondsInOneDay * daysInOneWeek
    }
    
    struct Formats
    {
        static let rfc3339 : String = "yyyy-MM-dd'T'HH:mm:ssZZ"
        static let iso8601DateOnly : String = "yyyy-MM-dd"
        static let iso8601TimeOnly : String = "HH:mm:ss"
        static let iso8601DateTime : String = "yyyy-MM-dd HH:mm:ss"
        static let timeOfDay : String = "h:mm a"
        static let dayOfMonth : String = "d"
        static let numericMonthOfYear : String = "L"
        static let shortMonthOfYear : String = "LLL"
        static let longMonthOfYear : String = "LLLL"
        static let shortDayOfWeek : String = "EE"
        static let longDayOfWeek : String = "EEEE"
    }
    
}
