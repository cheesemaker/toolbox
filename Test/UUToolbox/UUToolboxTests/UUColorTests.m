//
//  UUColorTests.m
//  UUFrameworkTest
//
//  Created by Ryan DeVore on 5/6/14.
//
//

#import <XCTest/XCTest.h>
#import "UUColor.h"

@interface UUColorTests : XCTestCase

@end

@implementation UUColorTests

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

- (void)testHexColor
{
    //BG #a7a9ac
    //Text #d8d8d8
    
    // 167, 169, 172
    
    UIColor* fromHex = [UIColor uuColorFromHex:@"A7A9AC"];
    
    CGFloat r = 0;
    CGFloat g = 0;
    CGFloat b = 0;
    CGFloat a = 0;
    [fromHex getRed:&r green:&g blue:&b alpha:&a];
    
    UIColor* fromRGB = [UIColor uuColorWithRed:167 Green:169 Blue:172];

    CGFloat r2 = 0;
    CGFloat g2 = 0;
    CGFloat b2 = 0;
    CGFloat a2 = 0;
    [fromRGB getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    
    //XCTAssertEqual(r, r2, @"Red not equal");
    //XCTAssertEqual(g, g2, @"Green not equal");
    //XCTAssertEqual(b, b2, @"Blue not equal");
    //XCTAssertEqual(a, a2, @"Alpha not equal");
    
    
    
    
//    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

@end
