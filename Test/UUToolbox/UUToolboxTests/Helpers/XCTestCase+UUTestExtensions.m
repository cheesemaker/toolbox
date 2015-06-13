//
//  XCTestCase+UUTestExtensions.m
//  UUToolbox
//
//  Created by Ryan DeVore on 2/22/15.
//  Copyright (c) 2015 Silver Pine. All rights reserved.
//

#import "XCTestCase+UUTestExtensions.h"
#import "UUDictionary.h"
#import "UURandom.h"
#import "UUString.h"
#import "UUDate.h"

@implementation XCTestCase (UUTestExtensions)



@end


typedef NS_ENUM(NSUInteger, UURandomDataType)
{
    UURandomDataTypeString,
    UURandomDataTypeNumber,
    UURandomDataTypeBool,
    UURandomDataTypeDate,
    UURandomDataTypeHexData,
    UURandomDataTypeDouble,
    
    UURandomDataTypeCount
};

typedef NS_ENUM(NSUInteger, UURandomNodeType)
{
    UURandomNodeTypePrimitive,
    UURandomNodeTypeArray,
    UURandomNodeTypeDictionary,
    
    UURandomNodeTypeCount
};

@implementation UURandom (ToolboxUnitTestHelpers)

+ (NSString*) uuRandomAsciiString:(NSUInteger)maxLength
{
    NSMutableString* sb = [NSMutableString string];
    
    NSUInteger count = (NSUInteger)[UURandom uuRandomUInt32BetweenLow:0 high:(u_int32_t)maxLength];
    
    for (NSUInteger i = 0; i < count; i++)
    {
        char c = (char)[UURandom uuRandomUInt32BetweenLow:32 high:126];
        [sb appendFormat:@"%c", c];
    }
    
    return [sb copy];
}

+ (NSNumber*) uuRandomNumber
{
    NSInteger result = 0;
    NSData* tmp = [UURandom uuRandomBytes:sizeof(result)];
    [tmp getBytes:&result length:sizeof(result)];
    return @(result);
}

+ (NSNumber*) uuRandomDouble
{
    UInt32 numerator = [self uuRandomUInt32];
    UInt32 divisor = [self uuRandomUInt32];
    
    double result = 0;
    if (divisor != 0)
    {
        result = (double)numerator / (double)divisor;
    }
    
    return @(result);
}

+ (id) uuRandomJsonSafeObject
{
    id val = nil;
    
    uint32_t type = [UURandom uuRandomUInt32BetweenLow:0 high:UURandomDataTypeCount];
    switch (type)
    {
        case UURandomDataTypeString:
        {
            val = [self uuRandomAsciiString:50];
            break;
        }
            
        case UURandomDataTypeNumber:
        {
            val = [self uuRandomNumber];
            break;
        }
            
        case UURandomDataTypeBool:
        {
            val = @([UURandom uuRandomBool]);
            break;
        }
            
        case UURandomDataTypeHexData:
        {
            NSUInteger max = (NSUInteger)[UURandom uuRandomUInt32BetweenLow:0 high:50];
            val = [NSString uuHexStringFromData:[UURandom uuRandomBytes:max]];
            break;
        }
            
        case UURandomDataTypeDate:
        {
            NSTimeInterval delta = (NSTimeInterval)[UURandom uuRandomUInt32BetweenLow:0 high:(60 * 60 * 24 * 365)];
            NSDate* d = [NSDate dateWithTimeIntervalSinceNow:delta];
            val = [d uuRfc3339String];
            break;
        }
            
        case UURandomDataTypeDouble:
        {
            val = [self uuRandomDouble];
            break;
        }
            
        default:
            break;
    }

    return val;
}

+ (NSString*) uuMakeRandomJsonString:(NSInteger)maxDepth childMax:(NSUInteger)childMax
{
    NSDictionary* d = [self uuMakeRandomDictionary:maxDepth childMax:childMax];
    return [d toJsonString];
}

+ (NSMutableDictionary*) uuMakeRandomDictionary:(NSInteger)maxDepth childMax:(NSUInteger)childMax
{
    //NSLog(@"uuMakeRandomDictionary, maxDepth: %d, childMax: %d", (int)maxDepth, (int)childMax);
    
    if (maxDepth < 0)
        return nil;
    
    NSMutableDictionary* md = [NSMutableDictionary dictionary];
    
    NSUInteger childCount = (NSUInteger)[UURandom uuRandomUInt32BetweenLow:1 high:(u_int32_t)childMax];
    for (NSUInteger i = 0; i < childCount; i++)
    {
        NSString* key = [self uuRandomAsciiString:[self uuRandomUInt32BetweenLow:1 high:50]];
        id val = nil;
        
        uint32_t type = [UURandom uuRandomUInt32BetweenLow:0 high:UURandomNodeTypeCount];
        switch (type)
        {
            case UURandomNodeTypePrimitive:
            {
                val = [self uuRandomJsonSafeObject];
                break;
            }
                
            case UURandomNodeTypeArray:
            {
                val = [self uuMakeRandomArray:childMax];
                break;
            }
                
            case UURandomNodeTypeDictionary:
            {
                val = [self uuMakeRandomDictionary:(maxDepth - 1) childMax:childMax];
                break;
            }
        }
        
        if (val)
        {
            //NSLog(@"uuMakeRandomDictionary, i: %d, key: %@, val: %@", (int)i, key, val);
            [md setValue:val forKey:key];
        }
    }
    
    return md;
}

+ (NSMutableDictionary*) uuMakeRandomDictionary:(NSUInteger)maxChildCount
{
    NSMutableDictionary* md = [NSMutableDictionary dictionary];
    
    NSUInteger childCount = (NSUInteger)[UURandom uuRandomUInt32BetweenLow:1 high:(u_int32_t)maxChildCount];
    for (NSUInteger i = 0; i < childCount; i++)
    {
        NSString* key = [self uuRandomAsciiString:[self uuRandomUInt32BetweenLow:1 high:50]];
        id val = [self uuRandomJsonSafeObject];
        [md setValue:val forKey:key];
    }
    
    return md;
}

+ (NSMutableArray*) uuMakeRandomArray:(NSUInteger)maxChildCount
{
    NSMutableArray* ma = [NSMutableArray array];
    
    NSUInteger childCount = (NSUInteger)[UURandom uuRandomUInt32BetweenLow:1 high:(u_int32_t)maxChildCount];
    for (NSUInteger i = 0; i < childCount; i++)
    {
        id val = [self uuRandomJsonSafeObject];
        if (val)
        {
            [ma addObject:val];
        }
    }
    
    return ma;
}

+ (NSMutableArray*) uuMakeRandomFakeObjectList:(NSUInteger)objectChildCount length:(NSUInteger)length
{
    NSMutableArray* arr = [NSMutableArray array];
    NSMutableArray* keys = [NSMutableArray array];
    NSUInteger keyCount = (NSUInteger)[UURandom uuRandomUInt32BetweenLow:1 high:(u_int32_t)objectChildCount];
    for (NSUInteger i = 0; i < keyCount; i++)
    {
        NSUInteger keyLength = (NSUInteger)[UURandom uuRandomUInt32BetweenLow:1 high:30];
        NSString* key = [self uuRandomAsciiString:keyLength];
        [keys addObject:key];
    }
    
    NSUInteger childCount = (NSUInteger)[UURandom uuRandomUInt32BetweenLow:1 high:(u_int32_t)length];
    for (NSUInteger i = 0; i < childCount; i++)
    {
        NSMutableDictionary* md = [NSMutableDictionary dictionary];
        
        for (NSString* key in keys)
        {
            NSUInteger dataLength = (NSUInteger)[UURandom uuRandomUInt32BetweenLow:1 high:30];
            NSData* data = [self uuRandomBytes:dataLength];
            NSString* base64 = [data base64EncodedStringWithOptions:0];
            [md setValue:base64 forKey:key];
        }
        
        [arr addObject:md];
    }
    
    return arr;
}

@end

@implementation NSData (ToolboxUnitTestHelpers)

- (NSData*) uuRemoveTrailingZeros
{
    NSInteger index = -1;
    
    const char* bytes = self.bytes;
    for (index = self.length - 1; index >= 0; index--)
    {
        if (bytes[index] != 0)
            break;
    }
    
    if (index != -1 && index < self.length)
    {
        return [self subdataWithRange:NSMakeRange(0, index + 1)];
    }
    else
    {
        return self;
    }
}

@end


@implementation NSDictionary (ToolboxUnitTestHelpers)

- (NSString*) toJsonString
{
    return [self toJsonString:0 encoding:NSUTF8StringEncoding];
}

- (NSString*) toJsonString:(NSJSONWritingOptions)options encoding:(NSStringEncoding)encoding
{
    NSString* str = nil;
    
    @try
    {
        NSError* err = nil;
        NSData* data = [NSJSONSerialization dataWithJSONObject:self options:options error:&err];
        if (err != nil)
        {
            return nil;
        }
        
        str = [[NSString alloc] initWithData:data encoding:encoding];
    }
    @catch (NSException *exception)
    {
        str = nil;
    }
    @finally
    {
        return str;
    }
}

@end