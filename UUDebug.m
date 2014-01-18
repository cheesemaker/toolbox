//
//  UUDebug.h
//  Useful Utilities - UUDebug for displaying logging output to an external screen either via AirPlay or a cable
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//	Usage:
//		1.	To begin monitoring for attached secondary screens, make sure to first call [UUDebug uuEnableSecondScreenLogging];
//			All subsequent calls in UUDebug will not display until the second screen has been enabled.
//		2.	To continually display all NSLog calls to the second screen, use [UUDebug uuStartContinuousLogging];
//		3.	To display one time, the most recent calls to NSLog, call [UUDebug uuDisplayLogStatements];
//		4.	To display your own custom text output, call [UUDebug uuSetSecondScreenText:@"My output"];
//		5.	If you use uuDisplayLogStatement or uuSetSecondScreenText, make sure that you did not start the continuous debug logging
//			because they will end up getting overwritten by the continuous log monitoring
//
//	Questions/comments/complaints:
//		contact: @cheesemaker or jon@threejacks.com

#import "UUDebug.h"
#import <asl.h>


#if __has_feature(objc_arc)
	#define UU_RELEASE(x)		(void)(0)
	#define UU_RETAIN(x)		x
	#define UU_AUTORELEASE(x)	x
	#define UU_BLOCK_RELEASE(x) (void)(0)
	#define UU_BLOCK_COPY(x)    [x copy]
	#define UU_NATIVE_CAST(x)	(__bridge x)
#else
	#define UU_RELEASE(x)		[x release]
	#define UU_RETAIN(x)		[x retain]
	#define UU_AUTORELEASE(x)	[(x) autorelease]
	#define UU_BLOCK_RELEASE(x) Block_release(x)
	#define UU_BLOCK_COPY(x)    Block_copy(x)
	#define UU_NATIVE_CAST(x)	(x)
#endif

@interface UUExternalLogDisplay : UIViewController
	@property (retain) UITextView*		debugTextField;
	@property (retain) UIWindow*		debugWindow;
	@property (assign) NSTimeInterval	startTime;
	@property (atomic, assign) bool		isPolling;
	@property (atomic, assign) bool		isAttached;
@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UUExternalLogDisplay
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation UUExternalLogDisplay

UUExternalLogDisplay* theDebugger = nil;
		
+ (UUExternalLogDisplay*) debugger
{
	if (!theDebugger)
		theDebugger = [[UUExternalLogDisplay alloc] init];
	
	theDebugger.startTime = [[NSDate date] timeIntervalSince1970];
				
	return theDebugger;
}
		
- (void) uuSearchForSecondScreen
{
	UIScreen* secondScreen = nil;
	NSArray* screens = [UIScreen screens];
	for (int i = 0; i < screens.count; i++)
	{
		UIScreen* screen = [screens objectAtIndex:i];
		if (screen != [UIScreen mainScreen])
			secondScreen = screen;
	}

	//We shouldn't need this check here, but on the off chance we can pick up the second screen it doesn't hurt
	if (!secondScreen)
		secondScreen = [UIScreen mainScreen].mirroredScreen;

	if (secondScreen)
	{
		[self uuAttachDebugOutputToScreen:secondScreen];
	}
}

- (void)uuScreenDidConnect:(NSNotification *)notification
{
	UIScreen* newScreen = [notification object];
	[self uuAttachDebugOutputToScreen:newScreen];
}
		
- (void) uuScreenDidDisconnect:(NSNotification*)notification
{
	self.debugTextField = nil;
	self.debugWindow = nil;
}

- (void) uuBegin
{
	if (!self.debugWindow)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uuScreenDidConnect:) name:UIScreenDidConnectNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uuScreenDidDisconnect:) name:UIScreenDidDisconnectNotification object:nil];
			
		//Check to see if the screen is alread attached...
		[self uuSearchForSecondScreen];
	}
}

- (void) uuStop
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.isPolling = NO;
	
	[self uuDetachFromScreen];
}

- (void) uuAttachDebugOutputToScreen:(UIScreen*)newScreen
{
	if (!self.isAttached)
	{
		self.isAttached = YES;
		self.debugWindow = UU_AUTORELEASE([[UIWindow alloc] initWithFrame:newScreen.bounds]);
		[self.debugWindow setScreen:newScreen];
		self.debugWindow.backgroundColor = [UIColor whiteColor];
		self.debugWindow.hidden = false;
		[self.debugWindow setRootViewController:self];
			
		self.debugTextField = UU_AUTORELEASE([[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.debugWindow.frame.size.width, self.debugWindow.frame.size.height)]);
		self.debugTextField.backgroundColor = [UIColor whiteColor];
		self.debugTextField.textColor = [UIColor blackColor];
		[self.view addSubview:self.debugTextField];
	}
}

- (void) uuDetachFromScreen
{
	self.isAttached = NO;

	if (self.debugTextField)
		[self.debugTextField removeFromSuperview];
	self.debugTextField = nil;
	
	if (self.debugWindow)
	{
		self.debugWindow.screen = nil;
		[self.debugWindow setRootViewController:nil];
		self.debugWindow = nil;
	}
}

-(NSArray*) uuLogStatements
{
	NSString* processName = [[NSProcessInfo processInfo] processName];
	const char* processString = [processName UTF8String];
    NSMutableArray* consoleLog = [NSMutableArray array];

    aslclient client = asl_open(NULL, NULL, ASL_OPT_STDERR);

    aslmsg query = asl_new(ASL_TYPE_QUERY);
	asl_set_query(query, ASL_KEY_SENDER, processString, ASL_QUERY_OP_EQUAL);
    aslresponse response = asl_search(client, query);

    asl_free(query);

    aslmsg message;
    while((message = aslresponse_next(response)))
    {
		const char* timeStampString = asl_get(message, ASL_KEY_TIME);
		int timeStamp = [[NSString stringWithUTF8String:timeStampString] intValue];
		if (timeStamp > self.startTime)
		{
			const char* msg = asl_get(message, ASL_KEY_MSG);
			[consoleLog addObject:[NSString stringWithCString:msg encoding:NSUTF8StringEncoding]];
		}
    }

    aslresponse_free(response);
    asl_close(client);

    return consoleLog;
}

- (void) uuDisplayLogStatements
{
	//No need to pull the logs if there's no where to display it?
	if (self.isAttached)
	{
		NSArray* logs = [self uuLogStatements];
		NSString* output = @"";
		for (NSString* debugText in logs)
		{
			output = [NSString stringWithFormat:@"%@\r\n%@", debugText, output];
		}

		[self performSelectorOnMainThread:@selector(uuSetDebuggingText:) withObject:output waitUntilDone:YES];
	}
}

- (void) uuPollLogFile
{
	while (self.isPolling)
	{
		if (self.isAttached)
			[self uuDisplayLogStatements];
		else //If we're not attached, sleep for a second...
			[NSThread sleepForTimeInterval:1.0];
	}
}

- (void) uuSetDebuggingText:(NSString*)output
{
	if (!self.isAttached)
		return;
		
	self.debugTextField.text = output;
	NSRange range = NSMakeRange(output.length - 1, 1);
	[self.debugTextField scrollRangeToVisible:range];
}

- (void) uuBeginPollingLogFile
{
	if (!self.isPolling)
	{
		self.isPolling = YES;
		[NSThread detachNewThreadSelector:@selector(uuPollLogFile) toTarget:self withObject:nil];
	}
}

- (void) uuStopPollingLogFile
{
	self.isPolling = NO;
}
		
@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UUDebug
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation UUDebug

+ (void) uuEnableSecondScreenLogging
{
	UUExternalLogDisplay* debugger = [UUExternalLogDisplay debugger];
	[debugger uuBegin];
}

+ (void) uuDisableSecondScreenLogging
{
	UUExternalLogDisplay* debugger = [UUExternalLogDisplay debugger];
	[debugger uuStop];
}

+ (void) uuStartContinuousDebugLogging
{
	UUExternalLogDisplay* debugger = [UUExternalLogDisplay debugger];
	[debugger uuBeginPollingLogFile];
}

+ (void) uuStopContinuousDebugLogging
{
	UUExternalLogDisplay* debugger = [UUExternalLogDisplay debugger];
	[debugger uuStopPollingLogFile];
}

+ (void) uuDisplayLogStatements
{
	UUExternalLogDisplay* debugger = [UUExternalLogDisplay debugger];
	[debugger uuDisplayLogStatements];
}

+ (void) uuSetSecondScreenText:(NSString*)output
{
	UUExternalLogDisplay* debugger = [UUExternalLogDisplay debugger];
	[debugger uuSetDebuggingText:output];
}

@end
