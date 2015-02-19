//
//  UUReachability.h
//  Useful Utilities - Simple block based reachibilty wrapper
//
//  Created by Ryan DeVore on 7/1/14.
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com
//
//  This class was adapted from the Apple sample on Reachability

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

extern NSString * const kUUReachabilityChangedNotification;

@interface UUReachabilityResult : NSObject

// Raw reachability flags
@property (assign) SCNetworkReachabilityFlags reachabilityFlags;

// Convenience methods to check reachability bit flags
@property (assign) BOOL isReachableWithWiFi;
@property (assign) BOOL isReachableWithCell;
@property (assign) BOOL isReachable; // Cell or WiFi

// For inspection of bit values
- (NSDictionary*) reachabilityFlagsAsDictionary;

@end

@interface UUReachability : NSObject

+ (instancetype) sharedInstance; // uses www.apple.com
+ (instancetype) reachabilityForHostName:(NSString*)hostName;

- (UUReachabilityResult*) currentReachability;

// Delay (in seconds) before firing a kUUReachabilityChangedNotification. Default is 1.0
// This delay is to buffer against rapid changes in reachability
@property (assign) NSTimeInterval reachabilityChangedDelay;

@end
