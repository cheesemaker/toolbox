//
//  UUDate.m
//  Useful Utilities - Extensions for NSDate
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import "UUDate.h"

//If you want to impement your own UU_RELEASE and UU_AUTORELEASE mechanisms in your .pch, you may do so, just remember to define UU_MEMORY_MANAGEMENT
#ifndef UU_MEMORY_MANAGEMENT
#if !__has_feature(objc_arc)
#define UU_AUTORELEASE(x) [(x) autorelease]
#define UU_RELEASE(x)	  [(x) release]
#else
#define UU_AUTORELEASE(x) x
#define UU_RELEASE(x)     (void)(0)
#endif
#endif


// Localization Keys used by uuFormatAsDeltaFromNow

NSString * const kUUTimeDeltaJustNowFormat              = @"Just now";
NSString * const kUUTimeDeltaSecondsSingularFormat      = @"%d second ago";
NSString * const kUUTimeDeltaSecondsPluralFormat        = @"%d seconds ago";
NSString * const kUUTimeDeltaMinutesSingularFormat      = @"%d minute ago";
NSString * const kUUTimeDeltaMinutesPluralFormat        = @"%d minutes ago";
NSString * const kUUTimeDeltaHoursSingularFormat        = @"%d hour ago";
NSString * const kUUTimeDeltaHoursPluralFormat          = @"%d hours ago";
NSString * const kUUTimeDeltaDaysSingularFormat         = @"%d day ago";
NSString * const kUUTimeDeltaDaysPluralFormat           = @"%d days ago";

NSString * const kUUTimeDeltaJustNowFormatKey           = @"UUTimeDeltaJustNowFormatKey";
NSString * const kUUTimeDeltaSecondsSingularFormatKey   = @"UUTimeDeltaSecondsSingularFormatKey";
NSString * const kUUTimeDeltaSecondsPluralFormatKey     = @"UUTimeDeltaSecondsPluralFormatKey";
NSString * const kUUTimeDeltaMinutesSingularFormatKey   = @"UUTimeDeltaMinutesSingularFormatKey";
NSString * const kUUTimeDeltaMinutesPluralFormatKey     = @"UUTimeDeltaMinutesPluralFormatKey";
NSString * const kUUTimeDeltaHoursSingularFormatKey     = @"UUTimeDeltaHoursSingularFormatKey";
NSString * const kUUTimeDeltaHoursPluralFormatKey       = @"UUTimeDeltaHoursPluralFormatKey";
NSString * const kUUTimeDeltaDaysSingularFormatKey      = @"UUTimeDeltaDaysSingularFormatKey";
NSString * const kUUTimeDeltaDaysPluralFormatKey        = @"UUTimeDeltaDaysPluralFormatKey";

// Localization Keys used by uuDayOfMonthSuffix
NSString * const kUUDayOfMonthSuffixFirst               = @"st";
NSString * const kUUDayOfMonthSuffixSecond              = @"nd";
NSString * const kUUDayOfMonthSuffixThird               = @"rd";
NSString * const kUUDayOfMonthSuffixNth                 = @"th";

NSString * const kUUDayOfMonthSuffixFirstKey            = @"UUDayOfMonthSuffixFirstKey";
NSString * const kUUDayOfMonthSuffixSecondKey           = @"UUDayOfMonthSuffixSecondKey";
NSString * const kUUDayOfMonthSuffixThirdKey            = @"UUDayOfMonthSuffixThirdKey";
NSString * const kUUDayOfMonthSuffixNthKey              = @"UUDayOfMonthSuffixNthKey";

// Common Date Formats
NSString * const kUURFC3339DateTimeFormatter        = @"yyyy-MM-dd'T'HH:mm:ssZZ";
NSString * const kUUISO8601DateFormatter            = @"yyyy-MM-dd";
NSString * const kUUISO8601TimeFormatter            = @"HH:mm:ss";
NSString * const kUUISO8601DateTimeFormatter        = @"yyyy-MM-dd HH:mm:ss";
NSString * const kUUTimeOfDayDateformatter          = @"h:mm a";
NSString * const kUUDayOfMonthDateFormatter         = @"d";
NSString * const kUUShortMonthOfYearDateFormatter   = @"LLL";
NSString * const kUULongMonthOfYearDateFormatter    = @"LLLL";
NSString * const kUUDayOfWeekDateFormatter          = @"EEEE";


@implementation NSDate (UUStringFormatters)

// Instance Methods

- (NSString*) uuRfc3339String
{
    return [self uuStringFromDate:kUURFC3339DateTimeFormatter timeZone:nil];
}

- (NSString*) uuIso8601DateString
{
    return [self uuStringFromDate:kUUISO8601DateFormatter timeZone:nil];
}

- (NSString*) uuIso8601TimeString
{
    return [self uuStringFromDate:kUUISO8601TimeFormatter timeZone:nil];
}

- (NSString*) uuIso8601DateTimeString
{
    return [self uuStringFromDate:kUUISO8601DateTimeFormatter timeZone:nil];
}

- (NSString*) uuDayOfWeek
{
    return [self uuStringFromDate:kUUDayOfWeekDateFormatter timeZone:nil];
}

- (NSString*) uuLongMonthOfYear
{
    return [self uuStringFromDate:kUULongMonthOfYearDateFormatter timeZone:nil];
}

- (NSString*) uuShortMonthOfYear
{
    return [[NSDateFormatter uuCachedDateFormatter:kUUShortMonthOfYearDateFormatter] stringFromDate:self];
}

- (NSString*) uuDayOfMonth
{
    NSString* str = [self uuStringFromDate:kUUDayOfMonthDateFormatter timeZone:nil];
    int dayValue = [str intValue];
    return [str stringByAppendingString:[NSDate uuDayOfMonthSuffix:dayValue]];
}

- (NSString*) uuTimeOfDay
{
    return [self uuStringFromDate:kUUTimeOfDayDateformatter timeZone:nil];
}

- (NSString*) uuFormatAsDeltaFromNow
{
    return [self uuFormatAsDeltaFromNow:YES];
}

- (NSString*) uuFormatAsDeltaFromNow:(BOOL)adjustTimeZone
{
    NSTimeInterval timeZoneDiff = 0;
    if (adjustTimeZone)
    {
        timeZoneDiff = [[NSTimeZone systemTimeZone] secondsFromGMT];
    }
    
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:self] - timeZoneDiff;
    return [NSDate uuFormatTimeDelta:interval];
}

// Private Instance Methods


- (NSString*) uuStringFromDate:(NSString*)formatter timeZone:(NSTimeZone*)timeZone
{
    NSDateFormatter* df = [NSDateFormatter uuCachedDateFormatter:formatter];
    df.timeZone = timeZone;
    return [df stringFromDate:self];
}

// Class Methods

const double kUUSecondsPerDay = (60 * 60 * 24);

+ (NSString*) uuFormatTimeDelta:(NSTimeInterval)interval
{
    double days = (interval / kUUSecondsPerDay);
    
    if (days < 1)
    {
        double hours = days * 24;
        
        if (hours < 1)
        {
            double minutes = hours * 60;
            
            if (minutes < 1)
            {
                double seconds = minutes * 60;
                
                if (seconds >= 1 && seconds < 2)
                {
                    return [self uuFormatDelta:kUUTimeDeltaSecondsSingularFormatKey defaultFormatter:kUUTimeDeltaSecondsSingularFormat value:seconds];
                }
                else if (seconds <= 0)
                {
                    return [[NSBundle mainBundle] localizedStringForKey:kUUTimeDeltaJustNowFormatKey value:kUUTimeDeltaJustNowFormat table:nil];
                }
                else
                {
                    return [self uuFormatDelta:kUUTimeDeltaSecondsPluralFormatKey defaultFormatter:kUUTimeDeltaSecondsPluralFormat value:seconds];
                }
            }
            else if (minutes >= 1 && minutes < 2)
            {
                return [self uuFormatDelta:kUUTimeDeltaMinutesSingularFormatKey defaultFormatter:kUUTimeDeltaMinutesSingularFormat value:minutes];
            }
            else
            {
                return [self uuFormatDelta:kUUTimeDeltaMinutesPluralFormatKey defaultFormatter:kUUTimeDeltaMinutesPluralFormat value:minutes];
            }
        }
        else if (hours >= 1 && hours < 2)
        {
            return [self uuFormatDelta:kUUTimeDeltaHoursSingularFormatKey defaultFormatter:kUUTimeDeltaHoursSingularFormat value:hours];
        }
        else
        {
            return [self uuFormatDelta:kUUTimeDeltaHoursPluralFormatKey defaultFormatter:kUUTimeDeltaHoursPluralFormat value:hours];
        }
    }
    else if (days >= 1 && days < 2)
    {
        return [self uuFormatDelta:kUUTimeDeltaDaysSingularFormatKey defaultFormatter:kUUTimeDeltaDaysSingularFormat value:days];
    }
    else
    {
        return [self uuFormatDelta:kUUTimeDeltaDaysPluralFormatKey defaultFormatter:kUUTimeDeltaDaysPluralFormat value:days];
    }
}

+ (NSString*) uuFormatDelta:(NSString*)key defaultFormatter:(NSString*)defaultFormatter value:(int)value
{
    NSString* formatter = [[NSBundle mainBundle] localizedStringForKey:key value:defaultFormatter table:nil];
    return [NSString stringWithFormat:formatter, value];
}


+ (NSString*) uuDayOfMonthSuffix:(int)dayOfMonth
{
    switch (dayOfMonth)
    {
        case 1:
        case 21:
        case 31:
            return [[NSBundle mainBundle] localizedStringForKey:kUUDayOfMonthSuffixFirstKey value:kUUDayOfMonthSuffixFirst table:nil];
            
        case 2:
        case 22:
            return [[NSBundle mainBundle] localizedStringForKey:kUUDayOfMonthSuffixSecondKey value:kUUDayOfMonthSuffixSecond table:nil];
            
        case 3:
        case 23:
            return [[NSBundle mainBundle] localizedStringForKey:kUUDayOfMonthSuffixThirdKey value:kUUDayOfMonthSuffixThird table:nil];
            
        case 4:
        case 5:
        case 6:
        case 7:
        case 8:
        case 9:
        case 10:
        case 11:
        case 12:
        case 13:
        case 14:
        case 15:
        case 16:
        case 17:
        case 18:
        case 19:
        case 20:
        case 24:
        case 25:
        case 26:
        case 27:
        case 28:
        case 29:
        case 30:
            return [[NSBundle mainBundle] localizedStringForKey:kUUDayOfMonthSuffixNthKey value:kUUDayOfMonthSuffixNth table:nil];
            
        default:
            return @"";
    }
}


@end


///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Date Parsing
@implementation NSDate (UUDateParsing)

+ (NSDate*) uuDateFromRfc3339String:(NSString*)string
{
    return [self uuDateFromString:string withFormat:kUURFC3339DateTimeFormatter];
}

+ (NSDate*) uuDateFromIso8601String:(NSString*)string
{
    return [self uuDateFromString:string withFormat:kUUISO8601DateTimeFormatter];
}

+ (NSDate*) uuDateFromString:(NSString*)string withFormat:(NSString*)format
{
    NSDateFormatter* df = [NSDateFormatter uuCachedDateFormatter:format];
    return [df dateFromString:string];
}

@end


///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Date Format Caching
static NSMutableDictionary* theSharedDateFormatterCache = nil;

@implementation NSDateFormatter (UUDateFormatterCache)

+ (NSMutableDictionary*) uuSharedDateFormatterCache
{
    if (theSharedDateFormatterCache == nil)
    {
        theSharedDateFormatterCache = [[NSMutableDictionary alloc] init];
    }
    
    return theSharedDateFormatterCache;
}

+ (NSDateFormatter*) uuCachedDateFormatter:(NSString*)dateFormat
{
    NSMutableDictionary* cache = [self uuSharedDateFormatterCache];
    NSDateFormatter* df = [cache valueForKey:dateFormat];
    if (df == nil)
    {
        df = UU_AUTORELEASE([[NSDateFormatter alloc] init]);
        [df setDateFormat:dateFormat];
        [cache setValue:df forKey:dateFormat];
    }
    
    return df;
    
}

@end








