//
//  UUObject.m
//  Useful Utilities - NSObject extensions
//
//  Created by Jonathan on 3/4/13.
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import "UUObject.h"
#import <objc/runtime.h>

const unsigned long kUUDefaultUserKey = 0x04261978;

@implementation NSObject (UUFramework)

- (void) attachUserInfo:(id)userInfo
{
    objc_setAssociatedObject(self, (const void*)kUUDefaultUserKey, userInfo, OBJC_ASSOCIATION_RETAIN);
}

- (id) userInfo
{
    return objc_getAssociatedObject(self, (const void*)kUUDefaultUserKey);
}

- (void) attachUserInfo:(id)userInfo forKey:(const void*)key
{
    if (key != nil)
    {
        objc_setAssociatedObject(self, key, userInfo, OBJC_ASSOCIATION_RETAIN);
    }
}

- (id) userInfoForKey:(const void*)key
{
    if (key != nil)
    {
        return objc_getAssociatedObject(self, key);
    }
    else
    {
        return nil;
    }
}

@end