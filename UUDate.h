//
//  UUDate.h
//  Useful Utilities - Extensions for NSDate
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import <Foundation/Foundation.h>

// Date Format Helpers
@interface NSDate (UUStringFormatters)

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Instance Methods

// Returns an RFC 3339 Formatted string, ie - "yyyy-MM-dd'T'HH:mm:ssZZ"
- (NSString*) uuRfc3339String;

// Returns an ISO 8601 Formatted date, ie - "yyyy-MM-dd"
- (NSString*) uuIso8601DateString;

// Returns an ISO 8601 Formatted time, ie - "HH:mm:ss"
- (NSString*) uuIso8601TimeString;

// Returns an ISO 8601 Formatted date/time, ie - "yyyy-MM-dd"
- (NSString*) uuIso8601DateTimeString;

// Returns a string day of week, ie - 'Monday' thru 'Sunday'
- (NSString*) uuDayOfWeek;

// Returns a string month of year, the full month, ie - July or September
- (NSString*) uuLongMonthOfYear;

// Returns an abbreviated three letter string for a month of the year, ie - JAN or APR
- (NSString*) uuShortMonthOfYear;

// Returns day of month plus suffix, ie - 26th
- (NSString*) uuDayOfMonth;

// Returns time of day with am/pm, ie - "9:52 am"
- (NSString*) uuTimeOfDay;

// Returns a relative time, such as "22 minutes ago" or "1 day ago", or "now"
- (NSString*) uuFormatAsDeltaFromNow; // Passes YES for adjustTimeZone
- (NSString*) uuFormatAsDeltaFromNow:(BOOL)adjustTimeZone;

// Returns a relative time, such as "22 minutes ago" or "1 day ago", or "now"
+ (NSString*) uuFormatTimeDelta:(NSTimeInterval)interval;

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Class Methods

// Returns Day of Month Suffix
+ (NSString*) uuDayOfMonthSuffix:(int)dayOfMonth;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Date Parsing
@interface NSDate (UUDateParsing)

// Uses kUURFC3339DateTimeFormatter
//
// Example:
//
// NSDate* d = [NSDate uuDateFromRfc3339String:@"1776-07-04T12:30:00Z"];
//
// or
//
// NSDate* d = [NSDate uuDateFromRfc3339String:@"1776-07-04T12:30:00-700"];
//
+ (NSDate*) uuDateFromRfc3339String:(NSString*)string;

// Uses kUUISO8601DateTimeFormatter
//
// Example:
//
// NSDate* d = [NSDate uuDateFromIso8601String:@"1776-07-04 12:30:00"];
+ (NSDate*) uuDateFromIso8601String:(NSString*)string;


+ (NSDate*) uuDateFromString:(NSString*)string withFormat:(NSString*)format;

@end


///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Date Format Caching
@interface NSDateFormatter (UUDateFormatterCache)

+ (NSDateFormatter*) uuCachedDateFormatter:(NSString*)dateFormat;
+ (void) uuSetDefaultTimeZone:(NSTimeZone*)timeZone;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Localization Keys used by uuFormatAsDelta

// This is just a simple string used if the delta is under a
// second, with no format specifier
extern NSString * const kUUTimeDeltaJustNowFormatKey;           // @"UUTimeDeltaJustNowFormatKey"

// The following are all format specifiers where a single
// integer number will be inserted, ie - "%d seconds ago"
extern NSString * const kUUTimeDeltaSecondsSingularFormatKey;   // @"UUTimeDeltaSecondsSingularFormatKey"
extern NSString * const kUUTimeDeltaSecondsPluralFormatKey;     // @"UUTimeDeltaSecondsPluralFormatKey"
extern NSString * const kUUTimeDeltaMinutesSingularFormatKey;   // @"UUTimeDeltaMinutesSingularFormatKey"
extern NSString * const kUUTimeDeltaMinutesPluralFormatKey;     // @"UUTimeDeltaMinutesPluralFormatKey"
extern NSString * const kUUTimeDeltaHoursSingularFormatKey;     // @"UUTimeDeltaHoursSingularFormatKey"
extern NSString * const kUUTimeDeltaHoursPluralFormatKey;       // @"UUTimeDeltaHoursPluralFormatKey"
extern NSString * const kUUTimeDeltaDaysSingularFormatKey;      // @"UUTimeDeltaDaysSingularFormatKey"
extern NSString * const kUUTimeDeltaDaysPluralFormatKey;        // @"UUTimeDeltaDaysPluralFormatKey"

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Localization Keys used by uuDayOfMonthSuffix
extern NSString * const kUUDayOfMonthSuffixFirstKey;            // @"UUDayOfMonthSuffixFirstKey"
extern NSString * const kUUDayOfMonthSuffixSecondKey;           // @"UUDayOfMonthSuffixSecondKey"
extern NSString * const kUUDayOfMonthSuffixThirdKey;            // @"UUDayOfMonthSuffixThirdKey"
extern NSString * const kUUDayOfMonthSuffixNthKey;              // @"UUDayOfMonthSuffixNthKey"

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Common Date Format Constants
extern NSString * const kUURFC3339DateTimeFormatter;        // @"yyyy-MM-dd'T'HH:mm:ssZZ"
extern NSString * const kUUISO8601DateFormatter;            // @"yyyy-MM-dd"
extern NSString * const kUUISO8601TimeFormatter;            // @"HH:mm:ss"
extern NSString * const kUUISO8601DateTimeFormatter;        // @"yyyy-MM-dd HH:mm:ss"
extern NSString * const kUUTimeOfDayDateformatter;          // @"h:mm a"
extern NSString * const kUUDayOfMonthDateFormatter;         // @"d"
extern NSString * const kUUShortMonthOfYearDateFormatter;   // @"LLL"
extern NSString * const kUULongMonthOfYearDateFormatter;    // @"LLLL"
extern NSString * const kUUDayOfWeekDateFormatter;          // @"EEEE"

