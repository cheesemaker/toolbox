//
//  UUPlayer+Extensions.h
//  UUToolbox
//
//  Created by Ryan DeVore on 2/22/15.
//  Copyright (c) 2015 Silver Pine. All rights reserved.
//

#import "UUPlayer.h"

@interface UUPlayer (Extensions)

+ (void) addPlayer:(NSString*)first last:(NSString*)last team:(NSString*)team position:(NSString*)position number:(NSNumber*)number context:(NSManagedObjectContext*)context;

@end
