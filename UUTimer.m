//
//  UUTimer.m
//  Useful Utilities - GCD based timer
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only
//  requirement is that you smile everytime you use it.
//

#import "UUTimer.h"
#import "UUDictionary.h"
#import "UUMacros.h"

#ifndef UUTimerLog
#ifdef DEBUG
#define UUTimerLog(fmt, ...) UUDebugLog(fmt, ##__VA_ARGS__)
#else
#define UUTimerLog(fmt, ...)
#endif
#endif

// Force UUTimerLog to be disabled all the time. Comment these two lines to
// enable debug logging again
#undef UUTimerLog
#define UUTimerLog(fmt, ...)

@interface UUTimer ()

@property (nonnull, nonatomic, copy, readwrite) NSString* timerId;
@property (nullable, nonatomic, strong, readwrite) id userInfo;
@property (assign, readwrite) NSTimeInterval interval;
@property (assign, readwrite) BOOL repeat;

@property (atomic, strong) dispatch_source_t dispatchSource;

@end

@implementation UUTimer

+ (nonnull dispatch_queue_t) backgroundTimerQueue
{
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
}

+ (nonnull dispatch_queue_t) mainThreadTimerQueue
{
    return dispatch_get_main_queue();
}

+ (nonnull NSMutableDictionary<NSString*, UUTimer*>*) activeTimers
{
    static NSMutableDictionary<NSString*, UUTimer*>* theActiveTimers = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once (&onceToken, ^
    {
        theActiveTimers = [NSMutableDictionary dictionary];
    });
    
    return theActiveTimers;
}

+ (nullable instancetype) findActiveTimer:(nonnull NSString*)timerId
{
    return [[self activeTimers] uuSafeGet:timerId forClass:[UUTimer class]];
}

+ (nonnull NSArray<UUTimer*>*) listActiveTimers
{
    return [[self activeTimers] allValues];
}

+ (void) addTimer:(nonnull UUTimer*)timer
{
    NSMutableDictionary* d = [self activeTimers];
    
    @synchronized (d)
    {
        [d setValue:timer forKey:timer.timerId];
    }
}

+ (void) removeTimer:(nonnull UUTimer*)timer
{
    NSMutableDictionary* d = [self activeTimers];
    
    @synchronized (d)
    {
        [d uuSafeRemove:timer.timerId];
    }
}

- (nonnull id) initWithInterval:(NSTimeInterval)interval
                       userInfo:(nullable id)userInfo
                          repeat:(BOOL)repeat
                          queue:(nonnull dispatch_queue_t)queue
                          block:(nonnull UUTimerBlock)block
{
    return [self initWithId:[[NSUUID UUID] UUIDString]
                   interval:interval
                   userInfo:userInfo
                      repeat:repeat
                      queue:queue
                      block:block];
}

- (nonnull id) initWithId:(nonnull NSString*)timerId
                 interval:(NSTimeInterval)interval
                 userInfo:(nullable id)userInfo
                    repeat:(BOOL)repeat
                    queue:(nonnull dispatch_queue_t)queue
                    block:(nonnull UUTimerBlock)block
{
    self = [super init];
    
    if (self)
    {
        self.timerId = timerId;
        self.userInfo = userInfo;
        self.interval = interval;
        self.repeat = repeat;
        
        dispatch_source_t src = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        
        if (src)
        {
            uint64_t nanoInterval = (interval * NSEC_PER_SEC);
            if (!repeat)
            {
                nanoInterval = DISPATCH_TIME_FOREVER;
            }
            
            dispatch_source_set_timer(src, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), nanoInterval, (1ull * NSEC_PER_SEC) / 10);
            dispatch_source_set_event_handler(src, ^
            {
                UUTimerLog(@"Invoking timer block for timer %@, userInfo: %@", self.timerId, self.userInfo);
                
                block(self);
                
                if (!repeat)
                {
                    [self cancel];
                }
            });
            
            self.dispatchSource = src;
        }
    }
    
    return self;
}

- (void) start
{
    @synchronized (self)
    {
        UUTimerLog(@"Starting timer %@, interval: %@, repeat: %@, dispatchSource: %@, userInfo: %@",
                   self.timerId, @(self.interval), @(self.repeat), self.dispatchSource, self.userInfo);
        
        if (self.dispatchSource)
        {
            [[self class] addTimer:self];
            
            dispatch_resume(self.dispatchSource);
        }
        else
        {
            UUTimerLog(@"Cannot start timer %@ because dispatch source is nil", self.timerId);
        }
    }
}

- (void) cancel
{
    @synchronized (self)
    {
        UUTimerLog(@"Cancelling timer %@, dispatchSource: %@, userInfo: %@", self.timerId, self.dispatchSource, self.userInfo);
        
        if (self.dispatchSource)
        {
            dispatch_source_cancel(self.dispatchSource);
            
            self.dispatchSource = nil;
        }
        
        [[self class] removeTimer:self];
    }
}

@end


@implementation UUTimer (WatchdogTimers)

+ (void) startWatchdogTimer:(nonnull NSString*)timerId
                    timeout:(NSTimeInterval)timeout
                   userInfo:(nullable id)userInfo
                      block:(nonnull void (^)(id _Nullable userInfo))block
{
    [self cancelWatchdogTimer:timerId];
    
    if (timeout > 0)
    {
        UUTimer* t = [[UUTimer alloc] initWithId:timerId
                                        interval:timeout
                                        userInfo:userInfo
                                          repeat:NO
                                           queue:[self backgroundTimerQueue]
                                           block:^(UUTimer * _Nonnull timer)
        {
            if (block)
            {
                block(timer.userInfo);
            }
        }];
        
        [t start];
    }
}

+ (void) cancelWatchdogTimer:(nonnull NSString*)timerId
{
    UUTimer* t = [self findActiveTimer:timerId];
    [t cancel];
}

@end
