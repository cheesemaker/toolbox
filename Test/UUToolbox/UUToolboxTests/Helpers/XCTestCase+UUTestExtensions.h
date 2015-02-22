//
//  XCTestCase+UUTestExtensions.h
//  UUToolbox
//
//  Created by Ryan DeVore on 2/22/15.
//  Copyright (c) 2015 Silver Pine. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>



//#define UUAsertFloatWithPrecision(left, right, ...) \

// _XCTPrimitiveAssertTrue(self, expression, @#expression, __VA_ARGS__)

@interface XCTestCase (UUTestExtensions)


- (void) compareFloatWithPrecision:(float)left other:(float)other precision:(int)precision;

@end
