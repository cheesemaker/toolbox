//
//  XCTestCase+UUTestExtensions.h
//  UUToolbox
//
//  Created by Ryan DeVore on 2/22/15.
//  Copyright (c) 2015 Silver Pine. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>

#define UUBeginAsyncTest() __block BOOL asyncTestDone = NO
#define UUEndAsyncTest() asyncTestDone = YES
#define UUWaitForAsyncTest() \
while (!asyncTestDone) \
{ \
[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]]; \
} \

@interface XCTestCase (UUTestExtensions)

@end
