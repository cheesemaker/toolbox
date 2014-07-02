//
//  UUReachability.m
//  Useful Utilities - Simple block based reachibilty wrapper
//
//  Created by Ryan DeVore on 7/1/14.
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com
//

#import "UUReachability.h"

@interface UUReachabilityResult ()

+ (instancetype) reachabilityResultWithFlags:(SCNetworkReachabilityFlags)reachabilityFlags;

@end

@implementation UUReachability
{
    SCNetworkReachabilityRef _reachabilityRef;
}

+ (instancetype) sharedInstance
{
	static id theSharedObject = nil;
	static dispatch_once_t onceToken;
    
    dispatch_once (&onceToken, ^
    {
        theSharedObject = [self reachabilityForHostName:@"www.apple.com"];
    });
	
	return theSharedObject;
}

+ (instancetype) reachabilityForHostName:(NSString*)hostName
{
    UUReachability* obj = [[[self class] alloc] initWithHostName:hostName];
    return obj;
}

- (id) initWithHostName:(NSString*)hostName
{
    self = [super init];
    
    if (self)
    {
        _reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, [hostName UTF8String]);
    }
    
    return self;
}

- (void) dealloc
{
    if (_reachabilityRef)
    {
        CFRelease(_reachabilityRef);
    }
}

- (UUReachabilityResult*) currentReachability
{
    UUReachabilityResult* result = nil;
    
    SCNetworkReachabilityFlags flags = 0;
    if (_reachabilityRef)
    {
        if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags))
        {
            result = [UUReachabilityResult reachabilityResultWithFlags:flags];
        }
    }
    
    return result;
}

@end

@implementation UUReachabilityResult

+ (instancetype) reachabilityResultWithFlags:(SCNetworkReachabilityFlags)reachabilityFlags
{
    UUReachabilityResult* result = [UUReachabilityResult new];
    [result updateReachability:reachabilityFlags];
    return result;
}

- (void) updateReachability:(SCNetworkReachabilityFlags)reachabilityFlags
{
    self.reachabilityFlags = reachabilityFlags;
    self.isReachableWithWiFi = NO;
    self.isReachableWithCell = NO;
    self.isReachable = NO;
    
    // This logic taken directly from the Apple samples
    
	if ((reachabilityFlags & kSCNetworkReachabilityFlagsReachable) == 0)
	{
		// The target host is not reachable.
		return;
	}
    
	if ((reachabilityFlags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
	{
		//
        // If the target host is reachable and no connection is required then we'll assume (for now) that you're on Wi-Fi...
        //
		self.isReachableWithWiFi = YES;
	}
    
	if ((((reachabilityFlags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
         (reachabilityFlags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
	{
        //
        // ... and the connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs...
        //
        
        if ((reachabilityFlags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
        {
            //
            // ... and no [user] intervention is needed...
            //
            self.isReachableWithWiFi = YES;
        }
    }
    
	if ((reachabilityFlags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
	{
		//
        // ... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
        //
        self.isReachableWithCell = YES;
	}
    
    self.isReachable = (self.isReachableWithWiFi || self.isReachableWithCell);
}

@end