//
//  UITextField.m
//  Useful Utilities - UITextField extensions
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import "UUTextField.h"

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

//Implementaiont Comment:
//Unfortunately, while both UITextField and UITextView implement the UITextInput protocol the nearest shared base class they have
//is UIView so we create a private category extension for UIView that is only for use with UITextField and UITextView.
@interface UIView (UUFramework_TextNavigation_Private)
@end

@implementation UIView (UUFramework_TextNavigation_Private)

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Range manipulation on a UITextInput
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) uuBackOneLetter
{
}

- (void) uuAdvanceOneLetter
{
}

- (void) uuBackOneWord
{
}

- (void) uuAdvanceOneWord
{
}

- (void) uuAddGestureNavigation
{
}


+ (NSRange) uuSelectedRange:(UIView<UITextInput>*)object
{
    UITextPosition* beginning = object.beginningOfDocument;

    UITextRange* selectedRange = object.selectedTextRange;
    UITextPosition* selectionStart = selectedRange.start;
    UITextPosition* selectionEnd = selectedRange.end;

    const NSInteger location = [object offsetFromPosition:beginning toPosition:selectionStart];
    const NSInteger length = [object offsetFromPosition:selectionStart toPosition:selectionEnd];

    return NSMakeRange(location, length);
}

+ (void) uuSetSelectedRange:(NSRange)range onTextInput:(UIView<UITextInput>*)object
{
    UITextPosition* beginning = object.beginningOfDocument;

    UITextPosition* startPosition = [object positionFromPosition:beginning offset:range.location];
    UITextPosition* endPosition = [object positionFromPosition:beginning offset:range.location + range.length];
    UITextRange* selectionRange = [object textRangeFromPosition:startPosition toPosition:endPosition];

    [object setSelectedTextRange:selectionRange];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UITextInput manipulation
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (void) uuTextInputAdvanceOneLetter:(UIView<UITextInput>*)object
{
	NSRange selection = [UIView uuSelectedRange:object];
	NSUInteger end = selection.location + selection.length;

	//If there is a selection, just go to the right side of the selection
	if (selection.length)
	{
		selection.location = end;
		selection.length = 0;
		[UIView uuSetSelectedRange:selection onTextInput:object];
		return;
	}	
	
	NSString* text = nil;
	if ([object respondsToSelector:@selector(text)])
		text = [object performSelector:@selector(text)];
		
	if (end < text.length)
	{
		end++;
		selection.location = end;
		selection.length = 0;
		[UIView uuSetSelectedRange:selection onTextInput:object];
	}
}

+ (void) uuTextInputBackOneLetter:(UIView<UITextInput>*)object
{
	NSRange selection = [UIView uuSelectedRange:object];
	NSUInteger end = selection.location + selection.length;
	if (selection.length > 0)
	{
		selection.length = 0;
		[UIView uuSetSelectedRange:selection onTextInput:object];
	}
	else if (end > 0)
	{
		end--;
		selection.location = end;
		selection.length = 0;
		[UIView uuSetSelectedRange:selection onTextInput:object];
	}
}

+ (void) uuTextInputAdvanceOneWord:(UIView<UITextInput>*)object
{
	NSCharacterSet* characterSet = [NSCharacterSet whitespaceCharacterSet];
	NSRange selection = [UIView uuSelectedRange:object];
	NSUInteger end = selection.location + selection.length;
	
	//If there is a selection, just go to the right side of the selection
	if (selection.length)
	{
		selection.location = end;
		selection.length = 0;
		[UIView uuSetSelectedRange:selection onTextInput:object];
		return;
	}

	NSString* text = nil;
	if ([object respondsToSelector:@selector(text)])
		text = [object performSelector:@selector(text)];

	NSScanner* scanner = [NSScanner scannerWithString:text];
	[scanner setScanLocation:0];
	
	NSUInteger location = text.length;
	NSArray* words = [text componentsSeparatedByCharactersInSet:characterSet];
	for (NSString* word in words)
	{
		if ([scanner scanUpToString:word intoString:nil])
		{
			NSUInteger scanLocation = [scanner scanLocation];
			if ( scanLocation > end)
			{
				location = scanLocation;
				break;
			}
		}
	}
	
	selection.location = location;
	selection.length = 0;
	[UIView uuSetSelectedRange:selection onTextInput:object];
}

+ (void) uuTextInputBackOneWord:(UIView<UITextInput>*)object
{
	NSCharacterSet* characterSet = [NSCharacterSet whitespaceCharacterSet];
	NSRange selection = [UIView uuSelectedRange:object];
	
	//If there is a selection, just go to the left side of the selection
	if (selection.length)
	{
		selection.length = 0;
		[UIView uuSetSelectedRange:selection onTextInput:object];
		return;
	}
	
	NSUInteger end = selection.location + selection.length;

	NSString* text = nil;
	if ([object respondsToSelector:@selector(text)])
		text = [object performSelector:@selector(text)];

	NSScanner* scanner = [NSScanner scannerWithString:text];
	[scanner setScanLocation:0];
	NSUInteger begin = 0;
	NSArray* words = [text componentsSeparatedByCharactersInSet:characterSet];
	for (NSString* word in words)
	{
		if ([scanner scanUpToString:word intoString:nil])
		{
			NSUInteger scanLocation = [scanner scanLocation];
			if (scanLocation < end)
				begin = scanLocation;
		}
	}
	
	selection.location = begin;
	selection.length = 0;
	[UIView uuSetSelectedRange:selection onTextInput:object];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UITextInput gesture creation
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (void) uuAddGestureNavigationToTextInput:(UIView<UITextInput>*)object
{
	UISwipeGestureRecognizer* swipeHandler = UU_AUTORELEASE([[UISwipeGestureRecognizer alloc] initWithTarget:object action:@selector(uuBackOneLetter)]);
	swipeHandler.direction = UISwipeGestureRecognizerDirectionLeft;
	[object.superview addGestureRecognizer:swipeHandler];
	
	swipeHandler = UU_AUTORELEASE([[UISwipeGestureRecognizer alloc] initWithTarget:object action:@selector(uuAdvanceOneLetter)]);
	swipeHandler.direction = UISwipeGestureRecognizerDirectionRight;
	[object.superview addGestureRecognizer:swipeHandler];

	swipeHandler = UU_AUTORELEASE([[UISwipeGestureRecognizer alloc] initWithTarget:object action:@selector(uuBackOneWord)]);
	swipeHandler.numberOfTouchesRequired = 2;
	swipeHandler.direction = UISwipeGestureRecognizerDirectionLeft;
	[object.superview addGestureRecognizer:swipeHandler];
	
	swipeHandler = UU_AUTORELEASE([[UISwipeGestureRecognizer alloc] initWithTarget:object action:@selector(uuAdvanceOneWord)]);
	swipeHandler.numberOfTouchesRequired = 2;
	swipeHandler.direction = UISwipeGestureRecognizerDirectionRight;
	[object.superview addGestureRecognizer:swipeHandler];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UITextField implementation
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation UITextField (UUFramework)

- (void) uuBackOneLetter
{
	[UIView uuTextInputBackOneLetter:self];
}

- (void) uuAdvanceOneLetter
{
	[UIView uuTextInputAdvanceOneLetter:self];
}

- (void) uuBackOneWord
{
	[UIView uuTextInputBackOneWord:self];
}

- (void) uuAdvanceOneWord
{
	[UIView uuTextInputAdvanceOneWord:self];
}

- (void) uuAddGestureNavigation
{
	[UIView uuAddGestureNavigationToTextInput:self];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UITextView implementation
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation UITextView (UUFramework)

- (void) uuBackOneLetter
{
	[UIView uuTextInputBackOneLetter:self];
	[self scrollRangeToVisible:self.selectedRange];
}

- (void) uuAdvanceOneLetter
{
	[UIView uuTextInputAdvanceOneLetter:self];
	[self scrollRangeToVisible:self.selectedRange];
}

- (void) uuBackOneWord
{
	[UIView uuTextInputBackOneWord:self];
	[self scrollRangeToVisible:self.selectedRange];
}

- (void) uuAdvanceOneWord
{
	[UIView uuTextInputAdvanceOneWord:self];
	[self scrollRangeToVisible:self.selectedRange];
}

- (void) uuAddGestureNavigation
{
	[UIView uuAddGestureNavigationToTextInput:self];
	[self scrollRangeToVisible:self.selectedRange];
}

@end