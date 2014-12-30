//
//  UITextField.h
//  Useful Utilities - UITextField and UITextView extensions
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import <UIKit/UIKit.h>

@interface UITextField (UUFramework)

	//Enable one finger swipe to move the text caret forward/backward one character and
	// two finger swipe to move the text caret forward/backward an entire word
	- (void) uuAddGestureNavigation;

@end


@interface UITextView (UUFramework)

	//Enable one finger swipe to move the text caret forward/backward one character and
	// two finger swipe to move the text caret forward/backward an entire word
	- (void) uuAddGestureNavigation;

@end
