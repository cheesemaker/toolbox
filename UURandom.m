//
//  UURandom.m
//  Useful Utilities - Handy helpers for generating random numbers and picking random elements
//
//  Created by Ryan DeVore on 7/29/13.
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import "UURandom.h"

#pragma mark - UURandom

@implementation UURandom

+ (u_int32_t) uuRandomUInt32
{
    return arc4random();
}

+ (u_int32_t) uuRandomUInt32BetweenLow:(u_int32_t)low high:(u_int32_t)high
{
    if (low > high)
	{
		u_int32_t temp = low;
		low = high;
		high = temp;
	}
	
	u_int32_t range = high - low + 1;
    u_int32_t rand = arc4random_uniform(range);
	return (low + rand);
}

+ (u_int32_t) uuRandomUInt32BetweenLow:(u_int32_t)low high:(u_int32_t)high not:(u_int32_t)notIncluding
{
    u_int32_t randomResult = [self uuRandomUInt32BetweenLow:low high:high];
    
    while (randomResult == notIncluding)
    {
        randomResult = [self uuRandomUInt32BetweenLow:low high:high];
    }
    
    return randomResult;
}

+ (u_int32_t) uuRandomUInt32BetweenLow:(u_int32_t)low high:(u_int32_t)high atLeast:(u_int32_t)distance from:(u_int32_t)marker
{
    u_int32_t randomResult = [self uuRandomUInt32BetweenLow:low high:high];
    
    while ( (randomResult >= (marker - distance)) && (randomResult <= (marker + distance)) )
    {
        randomResult = [self uuRandomUInt32BetweenLow:low high:high];
    }
    
    return randomResult;
}

+ (BOOL) uuRandomBool
{
    return (([self uuRandomUInt32] % 2) == 0);
}

+ (NSData*) uuRandomBytes:(NSUInteger)length
{
    NSMutableData* data = [NSMutableData dataWithLength:length];
    SecRandomCopyBytes(kSecRandomDefault, length, [data mutableBytes]);
    return [data copy];
}

@end

#pragma mark - NSArray+UURandom

@implementation NSArray (UURandom)

- (NSUInteger) uuRandomIndex
{
    return [UURandom uuRandomUInt32BetweenLow:0 high:(u_int32_t)(self.count - 1)];
}

- (id) uuRandomElement
{
    if (self.count <= 0)
    {
        return nil;
    }
    
    return [self objectAtIndex:[self uuRandomIndex]];
}

@end

#pragma mark - NSSet+UURandom

@implementation NSSet (UURandom)

- (id) uuRandomElement
{
    return [[self allObjects] uuRandomElement];
}

@end

#pragma mark - NSMutableArray+UURandom

@implementation NSMutableArray (UURandom)

#define UU_RANDOMIZE_ARRAY_FACTOR 100

- (void) uuRandomize
{
    if (self.count > 1)
    {
        for (int i = 0; i < (self.count * UU_RANDOMIZE_ARRAY_FACTOR); i++)
        {
            NSUInteger a = [self uuRandomIndex];
            NSUInteger b = [UURandom uuRandomUInt32BetweenLow:0 high:(u_int32_t)(self.count - 1) not:(u_int32_t)a];
            
            [self exchangeObjectAtIndex:a withObjectAtIndex:b];
        }
    }
}

@end