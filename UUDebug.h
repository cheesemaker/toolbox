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

#import <Foundation/Foundation.h>

@interface UUDebug : NSObject
	+ (void) uuEnableSecondScreenLogging;
	+ (void) uuDisableSecondScreenLogging;


	+ (void) uuDisplayLogStatements;

	+ (void) uuStartContinuousDebugLogging;
	+ (void) uuStopContinuousDebugLogging;

	+ (void) uuSetSecondScreenText:(NSString*)output;
@end
