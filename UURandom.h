//
//  UURandom.h
//  Useful Utilities - Handy helpers for generating random numbers and picking random elements
//
//  Created by Ryan DeVore on 7/29/13.
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import <Foundation/Foundation.h>

@interface UURandom : NSObject 

+ (u_int32_t) uuRandomUInt32;
+ (u_int32_t) uuRandomUInt32BetweenLow:(u_int32_t)low high:(u_int32_t)high;
+ (u_int32_t) uuRandomUInt32BetweenLow:(u_int32_t)low high:(u_int32_t)high not:(u_int32_t)notIncluding;
+ (u_int32_t) uuRandomUInt32BetweenLow:(u_int32_t)low high:(u_int32_t)high atLeast:(u_int32_t)distance from:(u_int32_t)marker;

+ (BOOL) uuRandomBool;

+ (NSData*) uuRandomBytes:(NSUInteger)length;

@end

@interface NSArray (UURandom)

- (NSUInteger) uuRandomIndex;
- (id) uuRandomElement;

@end

@interface NSSet (UURandom)

- (id) uuRandomElement;

@end

@interface NSMutableArray (UURandom)

- (void) uuRandomize;

@end