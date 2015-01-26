//
//  UUObjectFactory.m
//  Useful Utilities - Object parsing protocols and helpers
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com
//
//

#import "UUObjectFactory.h"
#import "UUHttpResponseHandler.h"

@implementation UUObjectFactory

+ (id) process:(Class)objectFactoryClass object:(id)object context:(id)context
{
    id processedResponse = object;
    
    if (objectFactoryClass && [objectFactoryClass conformsToProtocol:@protocol(UUObjectFactory)])
    {
        if ([object isKindOfClass:[NSDictionary class]])
        {
            id singleResponse = [objectFactoryClass uuObjectFromDictionary:object withContext:context];
            processedResponse = singleResponse;
        }
        else if ([object isKindOfClass:[NSArray class]])
        {
            NSMutableArray* list = [NSMutableArray array];
            
            for (id node in object)
            {
                if ([node isKindOfClass:[NSDictionary class]])
                {
                    id nodeObj = [objectFactoryClass uuObjectFromDictionary:node withContext:context];
                    if (nodeObj)
                    {
                        [list addObject:nodeObj];
                    }
                }
            }
            
            processedResponse = list;
        }
    }
    
    return processedResponse;
}

@end
