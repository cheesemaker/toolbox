//
//  UUDateTests.m
//  UUFrameworkTest
//
//  Created by Ryan DeVore on 7/1/14.
//
//

#import <XCTest/XCTest.h>
#import "UUDate.h"

@interface UUDateTests : XCTestCase

@end

@implementation UUDateTests

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

- (void)testDateChecks
{
    NSDate* d = [NSDate date];
    BOOL result = [d uuIsToday];
    XCTAssertTrue(result, @"Expect current date to be today");
    
    result = [d uuIsYesterday];
    XCTAssertFalse(result, @"Today is not yesterday");
    
    result = [d uuIsTomorrow];
    XCTAssertFalse(result, @"Today is not tomorrow");
    
    d = [d uuAddDays:2];
    result = [d uuIsTomorrow];
    XCTAssertFalse(result, @"Two days from now is not tomorrow");
    
    d = [[NSDate date] uuAddDays:-2];
    result = [d uuIsTomorrow];
    XCTAssertFalse(result, @"Two days ago is not yesterday");
    
    
}

@end
