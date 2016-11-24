//
//  UUDictionary.m
//  UUFrameworkTest
//
//  Created by Ryan DeVore on 4/18/14.
//
//

#import "UUDictionary.h"
#import "UUDate.h"
#import "UUString.h"

@implementation NSDictionary (UUDictionary)

- (id) uuSafeGet:(NSString*)key
{
    return [self uuSafeGet:key forClass:nil defaultValue:nil];
}

- (id) uuSafeGet:(NSString*)key forClass:(Class)forClass
{
    return [self uuSafeGet:key forClass:forClass defaultValue:nil];
}

- (id) uuSafeGet:(NSString*)key forClass:(Class)forClass defaultValue:(id)defaultValue
{
    id obj = [self valueForKey:key];
    if (obj && ![obj isKindOfClass:[NSNull class]])
    {
        if (forClass == nil || [obj isKindOfClass:forClass])
        {
            return obj;
        }
    }
    
    return defaultValue;
}

- (NSNumber*) uuSafeGetNumber:(NSString*)key
{
    return [self uuSafeGetNumber:key defaultValue:nil];
}

- (NSNumber*) uuSafeGetNumber:(NSString*)key defaultValue:(NSNumber*)defaultValue
{
    id node = [self uuSafeGet:key];
    
    if (node)
    {
        if ([node isKindOfClass:[NSNumber class]])
        {
            return node;
        }
        else if ([node isKindOfClass:[NSString class]])
        {
            NSNumberFormatter* f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            id val = [f numberFromString:node];
            if (val)
            {
                return val;
            }
        }
    }
    
    return defaultValue;
}

- (NSString*) uuSafeGetString:(NSString*)key
{
    return [self uuSafeGetString:key defaultValue:nil];
}

- (NSString*) uuSafeGetString:(NSString*)key defaultValue:(NSString*)defaultValue
{
    return [self uuSafeGet:key forClass:[NSString class] defaultValue:defaultValue];
}

- (NSDate*) uuSafeGetDate:(NSString*)key formatter:(NSDateFormatter*)formatter
{
    id node = [self uuSafeGetString:key];
    if (node && formatter)
    {
        return [formatter dateFromString:node];
    }
    else
    {
        return nil;
    }
}

- (NSDictionary*) uuSafeGetDictionary:(NSString*)key
{
    return [self uuSafeGet:key forClass:[NSDictionary class]];
}

- (NSArray*) uuSafeGetArray:(NSString*)key
{
    return [self uuSafeGet:key forClass:[NSArray class]];
}

- (NSData*) uuSafeGetData:(NSString*)key
{
    return [self uuSafeGetData:key defaultValue:nil];
}

- (NSData*) uuSafeGetData:(NSString*)key defaultValue:(NSData*)defaultValue
{
    return [self uuSafeGet:key forClass:[NSData class] defaultValue:defaultValue];
}

- (NSData*) uuSafeGetDataFromBase64String:(NSString*)key
{
    NSString* base64String = [self uuSafeGetString:key];
    if (base64String)
    {
        return [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    }
    else
    {
        return nil;
    }
}

@end

@implementation NSDictionary (UUHttpDictionary)

- (NSString*) uuBuildQueryString
{
    NSDictionary* dictionary = self;
    
    NSMutableString* queryStringArgs = [NSMutableString string];
    
    if (dictionary && dictionary.count > 0)
    {
        [queryStringArgs appendString:@"?"];
        
        // Append query string args
        int count = 0;
        NSArray* keys = [dictionary allKeys];
        for (int i = 0; i < dictionary.count; i++)
        {
            NSString* key = [keys objectAtIndex:i];
            id rawVal = [dictionary objectForKey:key];
            
            NSString* val = nil;
            if ([rawVal isKindOfClass:[NSString class]])
            {
                val = (NSString*)rawVal;
            }
            else if ([rawVal isKindOfClass:[NSNumber class]])
            {
                val = [rawVal stringValue];
            }
            
            if (val != nil)
            {
                if (count > 0)
                {
                    [queryStringArgs appendString:@"&"];
                }
                
				NSString* formattedKey = [key uuUrlEncoded];
				NSString* formattedValue = [val uuUrlEncoded];
                
                [queryStringArgs appendFormat:@"%@=%@", formattedKey, formattedValue];
                ++count;
            }
        }
    }
    
    return queryStringArgs;
}

- (NSString*) uuToJsonString
{
    NSString* str = nil;
    
    @try
    {
        NSError* err = nil;
        NSData* data = [NSJSONSerialization dataWithJSONObject:self options:0 error:&err];
        if (err != nil)
        {
            return nil;
        }
        
        str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
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

- (NSData*) uuToJson
{
    NSData* data = nil;
    
    @try
    {
        NSError* err = nil;
        data = [NSJSONSerialization dataWithJSONObject:self options:0 error:&err];
    }
    @catch (NSException *exception)
    {
        data = nil;
    }
    @finally
    {
        return data;
    }
}

@end

@implementation NSMutableDictionary (UUMutableDictionary)

- (void) uuSafeSetValue:(nullable id)value forKey:(nonnull NSString*)key
{
    if (key)
    {
        [self setValue:value forKey:key];
    }
}

- (void) uuSafeRemove:(id)key
{
    if (key)
    {
        [self removeObjectForKey:key];
    }
}

@end
