//
//  UUDictionary.m
//  UUFrameworkTest
//
//  Created by Ryan DeVore on 4/18/14.
//
//

#import "UUDictionary.h"
#import "UUDate.h"

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

@end
