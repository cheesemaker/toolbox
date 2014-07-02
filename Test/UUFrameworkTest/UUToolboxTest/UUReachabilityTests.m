//
//  UUReachabilityTests.m
//  UUFrameworkTest
//
//  Created by Ryan DeVore on 7/1/14.
//
//

#import <XCTest/XCTest.h>
#import "UUReachability.h"

@interface UUReachabilityTests : XCTestCase

@end

@implementation UUReachabilityTests

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

- (void)testSuccess
{
    UUReachabilityResult* result = [[UUReachability sharedInstance] currentReachability];
    XCTAssertNotNil(result, @"Except current reachabity to be non nil");
    XCTAssertTrue(result.isReachable, @"Expect build machine to be able to reach internet");
    XCTAssertTrue(result.isReachableWithWiFi, @"Expect buid machine to be able to reach wifi");
    XCTAssertFalse(result.isReachableWithCell, @"Expect build machine to not have cell signal");
}

- (void) testBadHost
{
    UUReachability* r = [UUReachability reachabilityForHostName:@"www.hope-this-is-a-fake-hostname.com"];
    UUReachabilityResult* result = [r currentReachability];
    XCTAssertNotNil(result, @"Except reachabity to be non nil");
    XCTAssertFalse(result.isReachable, @"Expect fake dns to not be reachable at all");
    XCTAssertFalse(result.isReachableWithWiFi, @"Expect fake dns to not be reachable via wifi");
    XCTAssertFalse(result.isReachableWithCell, @"Expect fake dns to not be reachable via cell");
}

@end
