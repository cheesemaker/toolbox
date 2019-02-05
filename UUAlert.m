//
//  UUAlert.m
//  Useful Utilities - UIAlertView extensions
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import "UUAlert.h"
#import <objc/runtime.h>

@interface UIAlertController(UUToolbox)
@property (nonatomic, strong) UIWindow* displayWindow;
@end

@implementation UIAlertController(UUToolbox)
@dynamic displayWindow;

- (void)setDisplayWindow:(UIWindow *)displayWindow
{
	objc_setAssociatedObject(self, @selector(displayWindow), displayWindow, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIWindow*) displayWindow
{
	return objc_getAssociatedObject(self, @selector(displayWindow));
}

@end

@implementation UUAlertViewController

UIViewController* activeViewController = nil;

+ (void) setActiveViewController:(UIViewController*)viewController
{
	activeViewController = viewController;
}

+ (UIAlertController*) initWithTitle:(NSString *)alertTitle
							 message:(NSString *)alertMessage
				   completionHandler:(void (^)(NSInteger buttonIndex))completionHandler
						buttonTitles:(NSString *)defaultButtonTitle, ...
{
	NSMutableArray* argumentArray = [[NSMutableArray alloc] init];
	va_list argList;
	va_start(argList, defaultButtonTitle);
	NSString* otherButtonTitle = va_arg(argList, NSString*);
	if (otherButtonTitle)
	{
		[argumentArray addObject:[NSString stringWithString:otherButtonTitle]];
		
		NSString* buttonMessage = va_arg(argList, NSString*);
		while (buttonMessage)
		{
			[argumentArray addObject:[NSString stringWithString:buttonMessage]];
			buttonMessage = va_arg(argList, NSString*);
		}
	}
	va_end(argList);
	
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertActionStyle alertStyle = UIAlertActionStyleDefault;
	if ([defaultButtonTitle isEqualToString:@"Cancel"]) {
		alertStyle = UIAlertActionStyleCancel;
	}
	
	UIAlertAction* alertAction = [UIAlertAction actionWithTitle:defaultButtonTitle style:alertStyle handler:^(UIAlertAction * _Nonnull action)
								  {
									  if (completionHandler)
									  {
										  completionHandler(0);
									  }
									  
									  alertController.displayWindow.hidden = YES;
									  alertController.displayWindow = nil;
								  }];
	[alertController addAction:alertAction];
	
	for (NSInteger i = 0; i < argumentArray.count; i++)
	{
		NSString* buttonTitle = [argumentArray objectAtIndex:i];
		UIAlertActionStyle alertStyle = UIAlertActionStyleDefault;
		if ([buttonTitle isEqualToString:@"Delete"]) {
			alertStyle = UIAlertActionStyleDestructive;
		}
		
		UIAlertAction* alertAction = [UIAlertAction actionWithTitle:buttonTitle style:alertStyle handler:^(UIAlertAction * _Nonnull action)
									  {
										  if (completionHandler)
										  {
											  completionHandler(i + 1);
										  }
										  
										  alertController.displayWindow.hidden = YES;
										  alertController.displayWindow = nil;
									  }];
		
		[alertController addAction:alertAction];
	}
	
	return alertController;
}

//Convenience functions
+ (UIAlertController*) uuOKCancelAlert:(NSString *)title message:(NSString *)message completionHandler:(void (^)(NSInteger buttonIndex))completionHandler
{
	UIAlertController* controller = [UUAlertViewController initWithTitle:title message:message completionHandler:completionHandler buttonTitles:@"Cancel", @"OK", nil];
	return controller;
}

+ (UIAlertController*) uuOneButtonAlert:(NSString *)title message:(NSString *)message button:(NSString*)button completionHandler:(void (^)(NSInteger buttonIndex))completionHandler
{
	UIAlertController* controller = [UUAlertViewController initWithTitle:title message:message completionHandler:completionHandler buttonTitles:button, nil];
	return controller;
}

+ (UIAlertController*) uuTwoButtonAlert:(NSString *)title message:(NSString *)message buttonOne:(NSString*)buttonOne buttonTwo:(NSString*)buttonTwo completionHandler:(void (^)(NSInteger buttonIndex))completionHandler
{
	UIAlertController* controller = [UUAlertViewController initWithTitle:title message:message completionHandler:completionHandler buttonTitles:buttonOne, buttonTwo, nil];
	return controller;
}

+ (void) uuShowAlertWithTitle:(NSString*)alertTitle
					  message:(NSString*)alertMessage
				  buttonTitle:(NSString*)buttonTitle
			completionHandler:(void (^)(NSInteger buttonIndex))completionHandler
{
	UIAlertController* alertController = [UUAlertViewController initWithTitle:alertTitle message:alertMessage completionHandler:completionHandler buttonTitles:buttonTitle, nil];
	[UUAlertViewController displayAlertController:alertController];
}

+ (void) uuShowOKCancelAlert:(NSString *)title message:(NSString *)message completionHandler:(void (^)(NSInteger buttonIndex))completionHandler
{
	UIAlertController* alertController = [UUAlertViewController uuOKCancelAlert:title message:message completionHandler:completionHandler];
	[UUAlertViewController displayAlertController:alertController];
}

+ (void) uuShowOneButtonAlert:(NSString *)title message:(NSString *)message button:(NSString*)button completionHandler:(void (^)(NSInteger buttonIndex))completionHandler
{
	UIAlertController* alertController = [UUAlertViewController uuOneButtonAlert:title message:message button:button completionHandler:completionHandler];
	[UUAlertViewController displayAlertController:alertController];
}

+ (void) uuShowTwoButtonAlert:(NSString *)title message:(NSString *)message buttonOne:(NSString*)buttonOne buttonTwo:(NSString*)buttonTwo completionHandler:(void (^)(NSInteger buttonIndex))completionHandler
{
	UIAlertController* alertController = [UUAlertViewController uuTwoButtonAlert:title message:message buttonOne:buttonOne buttonTwo:buttonTwo completionHandler:completionHandler];
	[UUAlertViewController displayAlertController:alertController];
}

+ (void) displayAlertController:(UIAlertController*)alertController
{
	if (activeViewController)
	{
		[activeViewController presentViewController:alertController animated:NO completion:nil];
	}
	else
	{
		UIWindow* displayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
		alertController.displayWindow = displayWindow;
		
		displayWindow.rootViewController = [UIViewController new];
		displayWindow.tintColor = [UIColor colorWithWhite:0.25 alpha:0.8];
		//alertController.displayWindow.tintColor = [UIApplication sharedApplication].keyWindow.tintColor;
		
		displayWindow.windowLevel = UIWindowLevelAlert;
		[displayWindow makeKeyAndVisible];
		[displayWindow.rootViewController presentViewController:alertController animated:NO completion:nil];
	}
}


@end
