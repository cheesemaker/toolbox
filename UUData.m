//
//  UUData.m
//  Useful Utilities - extensions for NSData and NSMutableData
//
//  Created by Ryan on 02/01/16
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//

#import "UUData.h"

@implementation NSData (UUToolbox)

- (UInt8) uuUInt8AtIndex:(NSUInteger)index
{
	UInt8 data = 0;
	[[self subdataWithRange:NSMakeRange(index, sizeof(data))] getBytes:&data length:sizeof(data)];
	return data;
}

- (UInt16) uuUInt16AtIndex:(NSUInteger)index
{
	UInt16 data = 0;
	[[self subdataWithRange:NSMakeRange(index, sizeof(data))] getBytes:&data length:sizeof(data)];
	return data;
}

- (UInt32) uuUInt32AtIndex:(NSUInteger)index
{
	UInt32 data = 0;
	[[self subdataWithRange:NSMakeRange(index, sizeof(data))] getBytes:&data length:sizeof(data)];
	return data;
}

- (UInt64) uuUInt64AtIndex:(NSUInteger)index
{
	UInt64 data = 0;
	[[self subdataWithRange:NSMakeRange(index, sizeof(data))] getBytes:&data length:sizeof(data)];
	return data;
}

- (SInt8) uuSInt8AtIndex:(NSUInteger)index
{
	SInt8 data = 0;
	[[self subdataWithRange:NSMakeRange(index, sizeof(data))] getBytes:&data length:sizeof(data)];
	return data;
}

- (SInt16) uuSInt16AtIndex:(NSUInteger)index
{
	SInt16 data = 0;
	[[self subdataWithRange:NSMakeRange(index, sizeof(data))] getBytes:&data length:sizeof(data)];
	return data;
}

- (SInt32) uuSInt32AtIndex:(NSUInteger)index
{
	SInt32 data = 0;
	[[self subdataWithRange:NSMakeRange(index, sizeof(data))] getBytes:&data length:sizeof(data)];
	return data;
}

- (SInt64) uuSInt64AtIndex:(NSUInteger)index
{
	SInt64 data = 0;
	[[self subdataWithRange:NSMakeRange(index, sizeof(data))] getBytes:&data length:sizeof(data)];
	return data;
}

- (NSData*) uuDataAtIndex:(NSUInteger)index count:(NSUInteger)count
{
	return [self subdataWithRange:NSMakeRange(index, count)];
}

- (NSString*) uuStringAtIndex:(NSUInteger)index count:(NSUInteger)count encoding:(NSStringEncoding)encoding
{
    NSData* subData = [self uuDataAtIndex:index count:count];
    return [[NSString alloc] initWithData:subData encoding:encoding];
}

- (NSString*) uuToHexString
{
    NSMutableString* sb = [NSMutableString string];
	
    const char* rawData = [self bytes];
    int count = (int)self.length;
    for (int i = 0; i < count; i++)
    {
        [sb appendFormat:@"%02X", (UInt8)rawData[i]];
    }
    
	return sb;
}

@end


@implementation NSMutableData (UUToolbox)

- (void) uuAppendUInt8:(UInt8)data
{
    [self appendBytes:&data length:sizeof(data)];
}

- (void) uuAppendUInt16:(UInt16)data
{
    [self appendBytes:&data length:sizeof(data)];
}

- (void) uuAppendUInt32:(UInt32)data
{
    [self appendBytes:&data length:sizeof(data)];
}

- (void) uuAppendUInt64:(UInt64)data
{
    [self appendBytes:&data length:sizeof(data)];
}

- (void) uuAppendSInt8:(SInt8)data
{
    [self appendBytes:&data length:sizeof(data)];
}

- (void) uuAppendSInt16:(SInt16)data
{
    [self appendBytes:&data length:sizeof(data)];
}

- (void) uuAppendSInt32:(SInt32)data
{
    [self appendBytes:&data length:sizeof(data)];
}

- (void) uuAppendSInt64:(SInt64)data
{
    [self appendBytes:&data length:sizeof(data)];
}

- (void) uuAppendString:(NSString*)data encoding:(NSStringEncoding)encoding
{
    if (data != nil)
    {
        [self appendData:[data dataUsingEncoding:encoding]];
    }
}

@end
