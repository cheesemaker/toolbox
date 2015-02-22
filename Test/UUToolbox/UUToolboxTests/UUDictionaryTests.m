//
//  UUDictionaryTests.m
//  UUFrameworkTest
//
//  Created by Ryan DeVore on 4/18/14.
//
//

#import <XCTest/XCTest.h>
#import "UUDictionary.h"
#import "UUDate.h"

@interface UUDictionaryTests : XCTestCase

@end

@implementation UUDictionaryTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testSafeGet
{
    NSDictionary* d = @{ @"foo" : @"bar", @"baz" : [NSNull null] };
    id expectBar = [d uuSafeGet:@"foo"];
    XCTAssertNotNil(expectBar, @"Expect value not to be nil");
    XCTAssertTrue([expectBar isKindOfClass:[NSString class]], @"Fetched object is wrong type");
    XCTAssertEqual(expectBar, @"bar", @"Fetched object is wrong value");
    
    id expectNil = [d uuSafeGet:@"whatever"];
    XCTAssertNil(expectNil, @"Expected non existent key to return nil");
    
    expectNil = [d uuSafeGet:nil];
    XCTAssertNil(expectNil, @"Expected nil key to return nil");
    
    expectNil = [d uuSafeGet:@"foo" forClass:[NSNumber class]];
    XCTAssertNil(expectNil, @"Expected wrong forClass to return nil");
    
    expectBar = [d uuSafeGet:@"foo" forClass:[NSString class]];
    XCTAssertEqual(expectBar, @"bar", @"Feched object by class is wrong value");
    
    expectNil = [d uuSafeGet:@"baz"];
    XCTAssertNil(expectNil, @"Expected NSNull value to return nil");
    
    id expectDefault = [d uuSafeGet:@"baz" forClass:nil defaultValue:@"test"];
    XCTAssertNotNil(expectDefault, @"Expect value not to be nil");
    XCTAssertTrue([expectDefault isKindOfClass:[NSString class]], @"Fetched object default is wrong type");
    XCTAssertEqual(expectDefault, @"test", @"Fetched object default is wrong value");
}

- (void) testSafeGetNumber
{
    NSDictionary* d = @{ @"a" : @(57), @"b" : @(-22), @"c": @"05", @"d" : @"FF", @"e" : @"garbage", @"f": @"-9509" };
    
    id val = [d uuSafeGetNumber:@"a"];
    XCTAssertNotNil(val, @"Expect value not to be nil");
    XCTAssertTrue([val isKindOfClass:[NSNumber class]], @"Fetched object is wrong type");
    XCTAssertEqualObjects(val, @(57), @"Fetched object is wrong value");
    
    val = [d uuSafeGetNumber:@"b"];
    XCTAssertNotNil(val, @"Expect value not to be nil");
    XCTAssertTrue([val isKindOfClass:[NSNumber class]], @"Fetched object is wrong type");
    XCTAssertEqualObjects(val, @(-22), @"Fetched object is wrong value");
    
    val = [d uuSafeGetNumber:@"c"];
    XCTAssertNotNil(val, @"Expect value not to be nil");
    XCTAssertTrue([val isKindOfClass:[NSNumber class]], @"Fetched string object is wrong type");
    XCTAssertEqualObjects(val, @(5), @"Fetched string object is wrong value");
    
    val = [d uuSafeGetNumber:@"d"];
    XCTAssertNil(val, @"Expected hex string value to return nil");
    
    val = [d uuSafeGetNumber:@"e"];
    XCTAssertNil(val, @"Expected string value to return nil");
    
    val = [d uuSafeGetNumber:@"f"];
    XCTAssertNotNil(val, @"Expect value not to be nil");
    XCTAssertTrue([val isKindOfClass:[NSNumber class]], @"Fetched object is wrong type");
    XCTAssertEqualObjects(val, @(-9509), @"Fetched negative string object is wrong value");
}

- (void) testSafeGetString
{
    NSDictionary* d = @{ @"foo" : @"bar", @"baz" : [NSNull null], @"blarfo" : @(99) };
    
    id val = [d uuSafeGetString:@"foo"];
    XCTAssertNotNil(val, @"Expect value not to be nil");
    XCTAssertTrue([val isKindOfClass:[NSString class]], @"Fetched object is wrong type");
    XCTAssertEqual(val, @"bar", @"Fetched object is wrong value");
    
    val = [d uuSafeGetString:@"baz"];
    XCTAssertNil(val, @"Expect NSNull to return nil");
    
    val = [d uuSafeGetString:@"blarfo"];
    XCTAssertNil(val, @"Expect number to return nil");
}

- (void) testSafeGetDate
{
    NSDictionary* d = @{ @"rfc3339" : @"1978-04-26T09:52:57-800", @"iso8601" : @"1978-04-26 09:52:57", @"foo" : @"bar"  };
    
    NSCalendar* cal = [NSCalendar currentCalendar];
    cal.timeZone = [NSTimeZone timeZoneWithName:@"PST"];
    NSCalendarUnit calUnits = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond);
    
    id val = [d uuSafeGetDate:@"rfc3339" formatter:[NSDateFormatter uuCachedDateFormatter:kUURFC3339DateTimeFormatter]];
    XCTAssertNotNil(val, @"Expect rfc3339 value not to be nil");
    NSLog(@"%@", val);
    
    NSDateComponents* dc = [cal components:calUnits fromDate:val];
    XCTAssertNotNil(val, @"Expect rfc3339 date components value not to be nil");
    XCTAssertEqual(dc.year, 1978, @"Wrong year");
    XCTAssertEqual(dc.month, 4, @"Wrong month");
    XCTAssertEqual(dc.day, 26, @"Wrong day");
    XCTAssertEqual(dc.hour, 9, @"Wrong hour");
    XCTAssertEqual(dc.minute, 52, @"Wrong minute");
    XCTAssertEqual(dc.second, 57, @"Wrong second");
    
    val = [d uuSafeGetDate:@"iso8601" formatter:[NSDateFormatter uuCachedDateFormatter:kUUISO8601DateTimeFormatter]];
    XCTAssertNotNil(val, @"Expect iso8601 value not to be nil");
    [cal setTimeZone:nil];
    dc = [cal components:calUnits fromDate:val];
    XCTAssertNotNil(val, @"Expect iso8601 date components value not to be nil");
    XCTAssertEqual(dc.year, 1978, @"Wrong year");
    XCTAssertEqual(dc.month, 4, @"Wrong month");
    XCTAssertEqual(dc.day, 26, @"Wrong day");
    XCTAssertEqual(dc.hour, 9, @"Wrong hour");
    XCTAssertEqual(dc.minute, 52, @"Wrong minute");
    XCTAssertEqual(dc.second, 57, @"Wrong second");
    
    val = [d uuSafeGetDate:@"foo" formatter:[NSDateFormatter uuCachedDateFormatter:kUUISO8601DateTimeFormatter]];
    XCTAssertNil(val, @"Expect non date string to be nil");
    
    [d uuSafeGetDate:@"iso8601" formatter:nil];
    XCTAssertNil(val, @"Expect nil formatter to return nil");
}


@end
