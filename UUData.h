//
//  UUData.h
//  Useful Utilities - extensions for NSData and NSMutableData
//
//  Created by Ryan on 02/01/16
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//

#import <Foundation/Foundation.h>

@interface NSData (UUToolbox)

- (UInt8)  uuUInt8AtIndex:(NSUInteger)index;
- (UInt16) uuUInt16AtIndex:(NSUInteger)index;
- (UInt32) uuUInt32AtIndex:(NSUInteger)index;
- (UInt64) uuUInt64AtIndex:(NSUInteger)index;

- (SInt8)  uuSInt8AtIndex:(NSUInteger)index;
- (SInt16) uuSInt16AtIndex:(NSUInteger)index;
- (SInt32) uuSInt32AtIndex:(NSUInteger)index;
- (SInt64) uuSInt64AtIndex:(NSUInteger)index;

- (NSData*) uuDataAtIndex:(NSUInteger)index count:(NSUInteger)count;

- (NSString*) uuStringAtIndex:(NSUInteger)index count:(NSUInteger)count encoding:(NSStringEncoding)encoding;

- (NSString*) uuToHexString;

@end

@interface NSMutableData (UUToolbox)

- (void) uuAppendUInt8:(UInt8)data;
- (void) uuAppendUInt16:(UInt16)data;
- (void) uuAppendUInt32:(UInt32)data;
- (void) uuAppendUInt64:(UInt64)data;

- (void) uuAppendSInt8:(SInt8)data;
- (void) uuAppendSInt16:(SInt16)data;
- (void) uuAppendSInt32:(SInt32)data;
- (void) uuAppendSInt64:(SInt64)data;

- (void) uuAppendString:(NSString*)data encoding:(NSStringEncoding)encoding;

@end
