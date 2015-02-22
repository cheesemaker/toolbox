//
//  UUPlayer+Extensions.m
//  UUToolbox
//
//  Created by Ryan DeVore on 2/22/15.
//  Copyright (c) 2015 Silver Pine. All rights reserved.
//

#import "UUPlayer+Extensions.h"
#import "UUCoreData.h"

@implementation UUPlayer (Extensions)

+ (void) addPlayer:(NSString*)first last:(NSString*)last team:(NSString*)team position:(NSString*)position number:(NSNumber*)number context:(NSManagedObjectContext*)context
{
    UUPlayer* p = [NSEntityDescription insertNewObjectForEntityForName:[self uuEntityName] inManagedObjectContext:context];
    p.firstName = first;
    p.lastName = last;
    p.team = team;
    p.position = position;
    p.number = number;
}

@end
