//
//  UURandomTests.m
//  UUFrameworkTest
//
//  Created by Ryan DeVore on 6/20/14.
//
//

#import <XCTest/XCTest.h>
#import "UURandom.h"

@interface UURandomTests : XCTestCase

@end

@implementation UURandomTests

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

- (void) testRandomSingle
{
    int runs = 1000;
    
    for (int i = 0; i < runs; i++)
    {
        u_int32_t r = [UURandom uuRandomUInt32];
        //NSLog(@"%u", r);
        
        BOOL b = [UURandom uuRandomBool];
        //NSLog(@"%@", b ? @"YES" : @"NO");
    }
}

- (void) testRandomRange
{
    int runs = 1000;
    
    for (int i = 0; i < runs; i++)
    {
        u_int32_t min = [UURandom uuRandomUInt32];
        u_int32_t max = [UURandom uuRandomUInt32];
        
        u_int32_t r = [UURandom uuRandomUInt32BetweenLow:min high:max];
        XCTAssertTrue(r >= MIN(min,max), @"Expect val to be greater than min");
        XCTAssertTrue(r <= MAX(min,max), @"Expect val to be less than max");
        
        u_int32_t not = [UURandom uuRandomUInt32];
        r = [UURandom uuRandomUInt32BetweenLow:min high:max not:not];
        XCTAssertTrue(r >= MIN(min,max), @"Expect val to be greater than min");
        XCTAssertTrue(r <= MAX(min,max), @"Expect val to be less than max");
        XCTAssertTrue(r != not, @"Expect val not to be the not value");
        
        min = 0;
        max = 100;
        u_int32_t dist = 10;
        u_int32_t marker = 50;
        r = [UURandom uuRandomUInt32BetweenLow:min high:max atLeast:dist from:marker];
        XCTAssertTrue(r >= MIN(min,max), @"Expect val to be greater than min");
        XCTAssertTrue(r <= MAX(min,max), @"Expect val to be less than max");
        XCTAssertTrue(r != not, @"Expect val not to be the not value");
        
        u_int32_t diff = abs(marker - r);
        XCTAssertTrue(diff >= dist, @"Expect result to be at least %u away from marker %u", diff, marker);
    }
}

- (void) testRandomArray
{
    NSMutableArray* array = nil;
    NSUInteger index = [array uuRandomIndex];
    XCTAssertEqual(0, index, @"Expect random index from nil array to be zero");
    
    id obj = [array uuRandomElement];
    XCTAssertNil(obj, @"Expect random object from nil array to be nil");
    
    int size = 100;
    array = [NSMutableArray array];
    for (int i = 0; i < size; i++)
    {
        [array addObject:@(i)];
    }
    
    int runs = 1000;
    
    for (int i = 0; i < runs; i++)
    {
        NSUInteger index = [array uuRandomIndex];
        XCTAssertTrue(index < array.count, @"Expect random index to be in valid range");
        
        obj = [array uuRandomElement];
        XCTAssertNotNil(obj, @"Expect random object from array to be non-nil");
    }
}

@end
