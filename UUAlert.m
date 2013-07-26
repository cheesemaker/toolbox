//
//  UUAlert.m
//  Useful Utilities - UIAlertView extensions
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import "UUAlert.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIAlertViewDelegateQueue
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface UIAlertViewDelegateQueue : NSObject
@property (nonatomic, retain) NSMutableArray* queue;
@end

static UIAlertViewDelegateQueue* theUIAlertViewDelegateQueue = nil;

@implementation UIAlertViewDelegateQueue

- (id) init
{
    self = [super init];
    if (self)
    {
        self.queue = [NSMutableArray array];
    }
    
    return self;
}

- (void) dealloc
{
    self.queue = nil;
    
    [super dealloc];
}

+ (UIAlertViewDelegateQueue*) sharedQueue
{
    if (theUIAlertViewDelegateQueue == nil)
    {
        theUIAlertViewDelegateQueue = [[UIAlertViewDelegateQueue alloc] init];
    }
    
    return theUIAlertViewDelegateQueue;
}

- (void) add:(NSObject<UIAlertViewDelegate>*)client
{
    @synchronized(self)
    {
        [self.queue addObject:client];
    }
}

- (void) remove:(NSObject<UIAlertViewDelegate>*)client
{
    @synchronized(self)
    {
        [self.queue removeObject:client];
    }
}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIAlertViewBlockDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface UIAlertViewBlockDelegate : NSObject<UIAlertViewDelegate>
- (id) initWithBlock:(void (^)(NSInteger buttonIndex))completionHandler;
@property (nonatomic, copy) void (^blocksCompletionHandler)(NSInteger buttonIndex);
@end


@implementation UIAlertViewBlockDelegate

- (instancetype) initWithBlock:(void (^)(NSInteger buttonIndex))completionHandler
{
    self = [super init];
    
    if (self)
    {
        if (completionHandler)
        {
            self.blocksCompletionHandler = Block_copy(completionHandler);
        }
    }
    
    [[UIAlertViewDelegateQueue sharedQueue] add:self];
    return self;
}

- (void) dealloc
{
    if (self.blocksCompletionHandler)
    {
        Block_release(self.blocksCompletionHandler);
    }
    
    [super dealloc];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (self.blocksCompletionHandler)
    {
        self.blocksCompletionHandler(buttonIndex);
    }
    
    [[UIAlertViewDelegateQueue sharedQueue] remove:self];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIAlertView (UUFramework)
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation UIAlertView (UUFramework)

+ (void) uuShowAlertWithTitle:(NSString *)alertTitle
                      message:(NSString *)alertMessage
                  buttonTitle:(NSString*)buttonTitle
            completionHandler:(void (^)(NSInteger buttonIndex))completionHandler
{
	UIAlertView* alert = [UIAlertView uuOneButtonAlert:alertTitle message:alertMessage button:buttonTitle completionHandler:completionHandler];
	[alert show];
}

- (instancetype) initWithTitle:(NSString *)title message:(NSString *)message completionHandler:(void (^)(NSInteger buttonIndex))completionHandler buttonTitles:(NSString *)defaultButtonTitle, ...
{
    UIAlertViewBlockDelegate* delegate = [[[UIAlertViewBlockDelegate alloc] initWithBlock:completionHandler] autorelease];
    
	NSMutableArray* argumentArray = [[[NSMutableArray alloc] init] autorelease];;
	va_list argList;
	va_start(argList, defaultButtonTitle);
	NSString* otherButtonTitle = va_arg(argList, NSString*);
	if (otherButtonTitle)
	{
		NSString* buttonMessage = va_arg(argList, NSString*);
		while (buttonMessage)
		{
			[argumentArray addObject:[NSString stringWithString:buttonMessage]];
			buttonMessage = va_arg(argList, NSString*);
		}
	}
	va_end(argList);
    
	self = [self initWithTitle:title message:message delegate:delegate cancelButtonTitle:defaultButtonTitle otherButtonTitles:(NSString*)otherButtonTitle,nil];
	for (int i = 0; i < [argumentArray count]; i++)
	{
		[self addButtonWithTitle:[argumentArray objectAtIndex:i]];
	}
    
	return self;
}

+ (instancetype) uuOKCancelAlert:(NSString *)title message:(NSString *)message completionHandler:(void (^)(NSInteger buttonIndex))completionHandler
{
	return [[[UIAlertView alloc] initWithTitle:title message:message completionHandler:completionHandler buttonTitles:NSLocalizedString(@"Cancel", @""), NSLocalizedString(@"OK", @""), nil] autorelease];
}

+ (instancetype) uuOneButtonAlert:(NSString *)title message:(NSString *)message button:(NSString*)button completionHandler:(void (^)(NSInteger buttonIndex))completionHandler
{
	return [[[UIAlertView alloc] initWithTitle:title message:message completionHandler:completionHandler buttonTitles:button, nil] autorelease];
}

+ (instancetype) uuTwoButtonAlert:(NSString *)title message:(NSString *)message buttonOne:(NSString*)buttonOne buttonTwo:(NSString*)buttonTwo completionHandler:(void (^)(NSInteger buttonIndex))completionHandler
{
	return [[[UIAlertView alloc] initWithTitle:title message:message completionHandler:completionHandler buttonTitles:buttonOne, buttonTwo, nil] autorelease];
}

+ (void) uuShowOKCancelAlert:(NSString *)title message:(NSString *)message completionHandler:(void (^)(NSInteger buttonIndex))completionHandler
{
    [[UIAlertView uuOKCancelAlert:title message:message completionHandler:completionHandler] show];
}

+ (void) uuShowOneButtonAlert:(NSString *)title message:(NSString *)message button:(NSString*)button completionHandler:(void (^)(NSInteger buttonIndex))completionHandler
{
    [[UIAlertView uuOneButtonAlert:title message:message button:button completionHandler:completionHandler] show];
}

+ (void) uuShowTwoButtonAlert:(NSString *)title message:(NSString *)message buttonOne:(NSString*)buttonOne buttonTwo:(NSString*)buttonTwo completionHandler:(void (^)(NSInteger buttonIndex))completionHandler
{
    [[UIAlertView uuTwoButtonAlert:title message:message buttonOne:buttonOne buttonTwo:buttonTwo completionHandler:completionHandler] show];
}


@end
