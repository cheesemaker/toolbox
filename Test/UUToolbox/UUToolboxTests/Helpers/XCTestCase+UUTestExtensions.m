//
//  XCTestCase+UUTestExtensions.m
//  UUToolbox
//
//  Created by Ryan DeVore on 2/22/15.
//  Copyright (c) 2015 Silver Pine. All rights reserved.
//

#import "XCTestCase+UUTestExtensions.h"

@implementation XCTestCase (UUTestExtensions)

- (void) compareFloatWithPrecision:(float)left other:(float)other precision:(int)precision
{
    int precisionFactor = pow(10, precision);
    float leftAdjust = left / precisionFactor;
    float rightAdjust = other / precisionFactor;
    //XCTAssert(<#expression, ...#>)
    
    
}

@end
