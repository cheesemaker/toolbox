//
//  UUActionSheet.m
//  Useful Utilities - UIActionSheet extensions
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com


#import "UUActionSheet.h"


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIActionSheetDelegateQueue
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface UIActionSheetDelegateQueue : NSObject
@property (nonatomic, retain) NSMutableArray* queue;
@end

@implementation UIActionSheetDelegateQueue

- (id) init
{
    self = [super init];
    
    if (self)
    {
        self.queue = [NSMutableArray array];
    }
    
    return self;
}

+ (instancetype) sharedInstance
{
	static id theSharedObject = nil;
	static dispatch_once_t onceToken;
    
    dispatch_once (&onceToken, ^
    {
        theSharedObject = [[[self class] alloc] init];
    });
	
	return theSharedObject;
}

- (void) add:(NSObject<UIActionSheetDelegate>*)client
{
    @synchronized(self)
    {
        [self.queue addObject:client];
    }
}

- (void) remove:(NSObject<UIActionSheetDelegate>*)client
{
    @synchronized(self)
    {
        [self.queue removeObject:client];
    }
}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIActionSheetBlockDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface UIActionSheetBlockDelegate : NSObject<UIActionSheetDelegate>

- (id) initWithBlock:(void (^)(UIActionSheet* sheet, NSInteger buttonIndex))completionHandler;
@property (nonatomic, copy) void (^blocksCompletionHandler)(UIActionSheet* sheet, NSInteger buttonIndex);

@end

@implementation UIActionSheetBlockDelegate

- (instancetype) initWithBlock:(void (^)(UIActionSheet* sheet, NSInteger buttonIndex))completionHandler
{
    self = [super init];
    
    if (self)
    {
        if (completionHandler)
        {
            self.blocksCompletionHandler = completionHandler;
        }
    }
    
    [[UIActionSheetDelegateQueue sharedInstance] add:self];
    return self;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (self.blocksCompletionHandler)
    {
        self.blocksCompletionHandler(actionSheet, buttonIndex);
    }
    
    self.blocksCompletionHandler = nil;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [[UIActionSheetDelegateQueue sharedInstance] remove:self];
}

@end


@implementation UIActionSheet (UUFramework)

- (instancetype) initWithTitle:(NSString *)title
                    completion:(UUActionSheetDelegateBlock)completion
                  cancelButton:(NSString*)cancelButton
             destructiveButton:(NSString*)destructiveButton
                  otherButtons:(NSString *)otherButtons, ...
{
    UIActionSheetBlockDelegate* delegate = [[UIActionSheetBlockDelegate alloc] initWithBlock:completion];
    
	self = [self initWithTitle:title delegate:delegate cancelButtonTitle:cancelButton destructiveButtonTitle:destructiveButton otherButtonTitles:nil];
    
    va_list args;
    va_start(args, otherButtons);
    for (NSString *arg = otherButtons; arg != nil; arg = va_arg(args, NSString*))
    {
        [self addButtonWithTitle:arg];
    }
    va_end(args);
    
	return self;
}

+ (instancetype) uuTwoButtonSheet:(NSString*)title
                     cancelButton:(NSString*)cancelButton
                destructiveButton:(NSString*)destructiveButton
                       completion:(UUActionSheetDelegateBlock)completion
{
    return [[[self class] alloc] initWithTitle:title completion:completion cancelButton:cancelButton destructiveButton:destructiveButton otherButtons:nil];
}


@end
