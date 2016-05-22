//
//  UUActionSheet.m
//  Useful Utilities - UIActionSheet extensions
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com


#import "UUActionSheet.h"

@interface UUActionSheet()
	@property (nonatomic, strong) UIAlertController* alertController;
	@property (nonatomic, strong) UIWindow* displayWindow;
@end


@implementation UUActionSheet

- (instancetype) initWithTitle:(NSString*)title
                    completion:(UUActionSheetDelegateBlock)completion
                  cancelButton:(NSString*)cancelButton
             destructiveButton:(NSString*)destructiveButton
                  otherButtons:(NSString*)button, ...
{
	NSMutableArray* argumentArray = [[NSMutableArray alloc] init];
	
	if (button)
	{
		[argumentArray addObject:[NSString stringWithString:button]];
		va_list argList;
		va_start(argList, button);
		NSString* buttonString = va_arg(argList, NSString*);
		while (buttonString)
		{
			[argumentArray addObject:[NSString stringWithString:buttonString]];
			buttonString = va_arg(argList, NSString*);
		}
		va_end(argList);
	}
	
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	
	if (cancelButton)
	{
		UIAlertAction* alertAction = [UIAlertAction actionWithTitle:cancelButton style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action)
		{
			if (completion)
			{
				completion(self, 0);
			}

			[self hide];			
		}];
		[alertController addAction:alertAction];
	}

	if (destructiveButton)
	{
		UIAlertAction* alertAction = [UIAlertAction actionWithTitle:destructiveButton style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action)
		{
			NSInteger buttonIndex = 0;
			if (cancelButton)
			{
				buttonIndex++;
			}
			
			if (completion)
			{
				completion(self, buttonIndex);
			}

			[self hide];
		}];
		[alertController addAction:alertAction];
	}

	NSInteger startingButtonOffset = 0;
	if (cancelButton)
		startingButtonOffset++;
	if (destructiveButton)
		startingButtonOffset++;
	
	for (NSInteger i = 0; i < argumentArray.count; i++)
	{
		NSString* buttonTitle = [argumentArray objectAtIndex:i];

		UIAlertAction* alertAction = [UIAlertAction actionWithTitle:buttonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
		{
			if (completion)
			{
				completion(self, i + startingButtonOffset);
			}
			
			[self hide];
		}];
		
		[alertController addAction:alertAction];
	}
	
	self.alertController = alertController;
	
	return self;
}

// Convenience method
+ (instancetype) uuTwoButtonSheet:(NSString*)title
                     cancelButton:(NSString*)cancelButton
                destructiveButton:(NSString*)destructiveButton
                       completion:(UUActionSheetDelegateBlock)completion
{
	return [[UUActionSheet alloc] initWithTitle:title completion:completion cancelButton:cancelButton destructiveButton:destructiveButton otherButtons:nil];
}


- (void) show
{
    UIWindow *topWindow = [UIApplication sharedApplication].windows.lastObject;
	self.displayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.displayWindow.rootViewController = [UIViewController new];
	self.displayWindow.tintColor = [UIApplication sharedApplication].keyWindow.tintColor;
	self.displayWindow.windowLevel = topWindow.windowLevel + 1;
	[self.displayWindow makeKeyAndVisible];
	[self.displayWindow.rootViewController presentViewController:self.alertController animated:NO completion:nil];
}

- (void) hide
{
	[self.displayWindow resignKeyWindow];
	self.displayWindow = nil;
}

@end
