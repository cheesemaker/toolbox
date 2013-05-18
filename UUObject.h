//
//  UUObject.h
//  Useful Utilities - NSObject extensions for attaching arbitrary data to objects. Useful for when
//					   you have painted yourself into a design corner.
//
//  Created by Jonathan on 3/4/13.
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import <Foundation/Foundation.h>

@interface NSObject (UUFramework)

- (void) attachUserInfo:(id)userInfo; //Uses kUUDefaultUserKey
- (id)	 userInfo;

- (void) attachUserInfo:(id)userInfo forKey:(const void*)key;
- (id)	 userInfoForKey:(const void*)key;


//Here for convenience...
extern unsigned long const kUUDefaultUserKey;

@end