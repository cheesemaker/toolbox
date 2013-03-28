//
//  UITextField.m
//  Useful Utilities - UITextField extensions
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import "UUTextField.h"

@implementation UITextField(UUFramework)

- (NSRange) uuSelectedRange
{
    UITextPosition* beginning = self.beginningOfDocument;

    UITextRange* selectedRange = self.selectedTextRange;
    UITextPosition* selectionStart = selectedRange.start;
    UITextPosition* selectionEnd = selectedRange.end;

    const NSInteger location = [self offsetFromPosition:beginning toPosition:selectionStart];
    const NSInteger length = [self offsetFromPosition:selectionStart toPosition:selectionEnd];

    return NSMakeRange(location, length);
}

- (void) uuSetSelectedRange:(NSRange)range
{
    UITextPosition* beginning = self.beginningOfDocument;

    UITextPosition* startPosition = [self positionFromPosition:beginning offset:range.location];
    UITextPosition* endPosition = [self positionFromPosition:beginning offset:range.location + range.length];
    UITextRange* selectionRange = [self textRangeFromPosition:startPosition toPosition:endPosition];

    [self setSelectedTextRange:selectionRange];
}

- (void) uuAdvanceOneLetter
{
	NSRange selection = [self uuSelectedRange];
	NSUInteger end = selection.location + selection.length;
	if (end < self.text.length)
	{
		end++;
		selection.location = end;
		selection.length = 0;
		[self uuSetSelectedRange:selection];
	}
}

- (void) uuBackOneLetter
{
	NSRange selection = [self uuSelectedRange];
	NSUInteger end = selection.location + selection.length;
	if (end > 0)
	{
		end--;
		selection.location = end;
		selection.length = 0;
		[self uuSetSelectedRange:selection];
	}
}

- (void) uuAdvanceOneWord
{
	NSCharacterSet* characterSet = [NSCharacterSet whitespaceCharacterSet];
	NSRange selection = [self uuSelectedRange];
	NSUInteger end = selection.location + selection.length;

	NSScanner* scanner = [NSScanner scannerWithString:self.text];
	[scanner setScanLocation:0];
	
	NSUInteger location = self.text.length;
	NSArray* words = [self.text componentsSeparatedByCharactersInSet:characterSet];
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
	[self uuSetSelectedRange:selection];
}

- (void) uuBackOneWord
{
	NSCharacterSet* characterSet = [NSCharacterSet whitespaceCharacterSet];
	NSRange selection = [self uuSelectedRange];
	NSUInteger end = selection.location + selection.length;

	NSScanner* scanner = [NSScanner scannerWithString:self.text];
	[scanner setScanLocation:0];
	NSUInteger begin = 0;
	NSArray* words = [self.text componentsSeparatedByCharactersInSet:characterSet];
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
	[self uuSetSelectedRange:selection];
}

- (void) uuAddGestureNavigation
{
	UISwipeGestureRecognizer* swipeHandler = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(uuBackOneLetter)];
	swipeHandler.direction = UISwipeGestureRecognizerDirectionLeft;
	[self.superview addGestureRecognizer:swipeHandler];
	[swipeHandler release];
	
	swipeHandler = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(uuAdvanceOneLetter)];
	swipeHandler.direction = UISwipeGestureRecognizerDirectionRight;
	[self.superview addGestureRecognizer:swipeHandler];
	[swipeHandler release];

	swipeHandler = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(uuBackOneWord)];
	swipeHandler.numberOfTouchesRequired = 2;
	swipeHandler.direction = UISwipeGestureRecognizerDirectionLeft;
	[self.superview addGestureRecognizer:swipeHandler];
	[swipeHandler release];
	
	swipeHandler = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(uuAdvanceOneWord)];
	swipeHandler.numberOfTouchesRequired = 2;
	swipeHandler.direction = UISwipeGestureRecognizerDirectionRight;
	[self.superview addGestureRecognizer:swipeHandler];
	[swipeHandler release];
}


@end