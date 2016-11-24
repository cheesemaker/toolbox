//
//  UUMacros
//  Useful Utilities - Handy macros
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only
//  requirement is that you smile everytime you use it.
//

#ifndef UUMacros_h
#define UUMacros_h

#define UUGCDMainQueue dispatch_get_main_queue()
#define UUGCDBackgroundQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

#define UUDispatchTimeInSeconds(seconds) dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC)

#define UUDispatchThread(block) \
    dispatch_async(UUGCDBackgroundQueue, block)

#define UUDispatchMain(block) \
    dispatch_async(UUGCDMainQueue, block)

#define UUDispatchSecondsMain(seconds, block) \
    dispatch_after(UUDispatchTimeInSeconds(seconds), UUGCDMainQueue, block)

#define UUDispatchSecondsThread(seconds, block) \
    dispatch_after(UUDispatchTimeInSeconds(seconds), UUGCDBackgroundQueue, block)


#endif /* UUMacros_h */
