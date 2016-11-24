//
//  UUTimer.h
//  Useful Utilities - GCD based timer
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only
//  requirement is that you smile everytime you use it.
//

#import <Foundation/Foundation.h>

@class UUTimer;

typedef void (^UUTimerBlock)(UUTimer* _Nonnull timer);

@interface UUTimer : NSObject

@property (nonnull, nonatomic, copy, readonly) NSString* timerId;
@property (nullable, nonatomic, strong, readonly) id userInfo;

- (nonnull id) initWithInterval:(NSTimeInterval)interval
                       userInfo:(nullable id)userInfo
                         repeat:(BOOL)repeat
                          queue:(nonnull dispatch_queue_t)queue
                          block:(nonnull UUTimerBlock)block;

- (nonnull id) initWithId:(nonnull NSString*)timerId
                 interval:(NSTimeInterval)interval
                 userInfo:(nullable id)userInfo
                    repeat:(BOOL)repeat
                    queue:(nonnull dispatch_queue_t)queue
                    block:(nonnull UUTimerBlock)block;

- (void) start;
- (void) cancel;

// Returns a shared serial queue for executing timers on a background thread
+ (nonnull dispatch_queue_t) backgroundTimerQueue;

// Alias for dispatch_get_main_queue()
+ (nonnull dispatch_queue_t) mainThreadTimerQueue;

// Find an active timer by its ID
+ (nullable instancetype) findActiveTimer:(nonnull NSString*)timerId;

@end


@interface UUTimer (WatchdogTimers)

// Cancels any existing timer with this ID, and kicks off a new timer
// on the background timer queue. If the timeout value is negative, the
// new timer will not be started.
+ (void) startWatchdogTimer:(nonnull NSString*)timerId
                    timeout:(NSTimeInterval)timeout
                   userInfo:(nullable id)userInfo
                      block:(nonnull void (^)(id _Nullable userInfo))block;

+ (void) cancelWatchdogTimer:(nonnull NSString*)timerId;

@end


