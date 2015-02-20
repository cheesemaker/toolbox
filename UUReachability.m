
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

#define UUIsBitSet(a,b) ((a & b) == b)

NSString * const kUUReachabilityChangedNotification      = @"UUReachabilityChangedNotification";

@interface UUReachabilityResult ()

+ (instancetype) reachabilityResultWithFlags:(SCNetworkReachabilityFlags)reachabilityFlags;

@end

@interface UUReachability ()

@property (nonatomic, strong) NSTimer* reachabilityChangedTimer;

- (void) kickReachabilityChanged:(UUReachabilityResult*)result;

@end

static void UUReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
    #pragma unused (target, flags)
    NSCAssert(info != NULL, @"info was NULL in ReachabilityCallback");
    NSCAssert([(__bridge NSObject*) info isKindOfClass: [UUReachability class]], @"info was wrong class in UUReachabilityCallback");
    
    UUReachability* reachability = (__bridge UUReachability*)info;
    
    UUReachabilityResult* result = [UUReachabilityResult reachabilityResultWithFlags:flags];
    reachability.currentReachability = result;

    [reachability kickReachabilityChanged:result];
}

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
        self.reachabilityChangedDelay = 1.0f;
        _reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, [hostName UTF8String]);
        [self startNotifier];
    }
    
    return self;
}

- (void) dealloc
{
    [self stopNotifier];
    
    if (_reachabilityRef)
    {
        CFRelease(_reachabilityRef);
    }
}

- (void) checkReachability:(void (^)(UUReachabilityResult* result))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        UUReachabilityResult* result = [self syncrhonousCheckReachability];
        
        if (completion)
        {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                completion(result);
            });
        }
        
    });
}

- (UUReachabilityResult*) syncrhonousCheckReachability
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
    
    self.currentReachability = result;
    [self kickReachabilityChanged:result];
    return result;
}

- (BOOL) startNotifier
{
    BOOL returnValue = NO;
    SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    
    if (SCNetworkReachabilitySetCallback(_reachabilityRef, UUReachabilityCallback, &context))
    {
        if (SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode))
        {
            returnValue = YES;
        }
    }
    
    return returnValue;
}

- (void) stopNotifier
{
    if (_reachabilityRef != NULL)
    {
        SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
}

- (void) kickReachabilityChanged:(UUReachabilityResult*)result
{
    [self.reachabilityChangedTimer invalidate];
    self.reachabilityChangedTimer = [NSTimer scheduledTimerWithTimeInterval:self.reachabilityChangedDelay target:self selector:@selector(delayHandleReachabilityChanged:) userInfo:result repeats:NO];
}

- (void) delayHandleReachabilityChanged:(NSTimer*)timer
{
    UUReachabilityResult* result = timer.userInfo;
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kUUReachabilityChangedNotification object:result];
    });
}

- (BOOL) isReachable
{
    if (!self.currentReachability)
    {
        return YES;
    }
    
    return [self.currentReachability isReachable];
}

@end

@implementation UUReachabilityResult

+ (instancetype) reachabilityResultWithFlags:(SCNetworkReachabilityFlags)reachabilityFlags
{
    UUReachabilityResult* result = [UUReachabilityResult new];
    [result updateReachability:reachabilityFlags];
    return result;
}

+ (NSDictionary*) reachabilityFlagsToDictionary:(SCNetworkReachabilityFlags)flags
{
    NSMutableDictionary* md = [NSMutableDictionary dictionary];
    [md setValue:@(flags) forKey:@"RawFlags"];
    [md setValue:@(UUIsBitSet(flags, kSCNetworkReachabilityFlagsTransientConnection)) forKey:@"TransientConnection"];
    [md setValue:@(UUIsBitSet(flags, kSCNetworkReachabilityFlagsReachable)) forKey:@"Reachable"];
    [md setValue:@(UUIsBitSet(flags, kSCNetworkReachabilityFlagsConnectionRequired)) forKey:@"ConnectionRequired"];
    [md setValue:@(UUIsBitSet(flags, kSCNetworkReachabilityFlagsConnectionOnTraffic)) forKey:@"ConnectionOnTraffic"];
    [md setValue:@(UUIsBitSet(flags, kSCNetworkReachabilityFlagsInterventionRequired)) forKey:@"InterventionRequired"];
    [md setValue:@(UUIsBitSet(flags, kSCNetworkReachabilityFlagsConnectionOnDemand)) forKey:@"ConnectionOnDemand"];
    [md setValue:@(UUIsBitSet(flags, kSCNetworkReachabilityFlagsIsLocalAddress)) forKey:@"IsLocalAddress"];
    [md setValue:@(UUIsBitSet(flags, kSCNetworkReachabilityFlagsIsDirect)) forKey:@"IsDirect"];
    [md setValue:@(UUIsBitSet(flags, kSCNetworkReachabilityFlagsIsWWAN)) forKey:@"IsWWAN"];
    return md.copy;
}

- (NSDictionary*) reachabilityFlagsAsDictionary
{
    return [[self class] reachabilityFlagsToDictionary:self.reachabilityFlags];
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