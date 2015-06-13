//
//  XCTestCase+UUTestExtensions.h
//  UUToolbox
//
//  Created by Ryan DeVore on 2/22/15.
//  Copyright (c) 2015 Silver Pine. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import "UURandom.h"

#define UUBeginAsyncTest() __block BOOL asyncTestDone = NO
#define UUEndAsyncTest() asyncTestDone = YES
#define UUWaitForAsyncTest() \
while (!asyncTestDone) \
{ \
[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]]; \
} \

@interface XCTestCase (UUTestExtensions)

@end

@interface UURandom (ToolboxUnitTestHelpers)

+ (NSString*) uuRandomAsciiString:(NSUInteger)maxLength;
+ (NSNumber*) uuRandomNumber;
+ (NSNumber*) uuRandomDouble;
+ (id) uuRandomJsonSafeObject;

+ (NSMutableDictionary*) uuMakeRandomDictionary:(NSUInteger)maxChildCount;
+ (NSMutableArray*) uuMakeRandomArray:(NSUInteger)maxChildCount;

+ (NSString*) uuMakeRandomJsonString:(NSInteger)maxDepth childMax:(NSUInteger)childMax;
+ (NSMutableDictionary*) uuMakeRandomDictionary:(NSInteger)maxDepth childMax:(NSUInteger)childMax;

+ (NSMutableArray*) uuMakeRandomFakeObjectList:(NSUInteger)objectChildCount length:(NSUInteger)length;

@end

@interface NSData (ToolboxUnitTestHelpers)

- (NSData*) uuRemoveTrailingZeros;

@end

@interface NSDictionary (ToolboxUnitTestHelpers)

- (NSString*) toJsonString; // Defaults to zero and NSUTF8StringEncoding
- (NSString*) toJsonString:(NSJSONWritingOptions)options encoding:(NSStringEncoding)encoding;

@end
