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

class UUDate: NSObject
{
    static let SecondsInOneMinute : TimeInterval = 60
    static let MinutesInOneHour : TimeInterval = 60
    static let HoursInOneDay : TimeInterval = 24
    static let DaysInOneWeek : TimeInterval = 7
    static let MillisInOneSecond : TimeInterval = 1000
    
    static let SecondsInOneHour : TimeInterval = SecondsInOneMinute * MinutesInOneHour
    static let SecondsInOneDay : TimeInterval = SecondsInOneHour * DaysInOneWeek
    static let SecondsInOneWeek : TimeInterval = SecondsInOneDay * DaysInOneWeek
}
