//
//  UUView
//  Useful Utilities - UIView extensions to animate appearance and disappearance of views
// (c) Copyright Jonathan Hays, all rights reserved
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import "UUView.h"
#import <objc/runtime.h>

/*

Disabling this until Xcode can stop crashing

@implementation UIView (UUInterfaceBuilder)

	- (BOOL) circular
	{
		return (self.layer.cornerRadius == self.frame.size.height / 2.0);
	}

	- (void) setCircular:(BOOL)circular
	{
		self.layer.cornerRadius = (self.frame.size.height / 2.0);
		self.clipsToBounds = YES;
	}

	- (CGFloat) cornerRadius
	{
		return self.layer.cornerRadius;
	}

	- (void) setCornerRadius:(CGFloat)cornerRadius
	{
		self.layer.cornerRadius = cornerRadius;
		self.clipsToBounds = YES;
	}

@end
*/

@implementation UIView (UUFramework)

- (void) uuAnimateAppearFromTop:(BOOL)bounce
{
	__block CGRect frame = self.frame;
	frame.origin.y = -frame.size.height;
	self.frame = frame;

	//If we bounce we will overshoot by 20 pixels
	frame.origin.y = (bounce) ? 20 : 0;
	
	[UIView animateWithDuration:0.25 animations:^
	{
		self.frame = frame;
	}
	completion:^(BOOL finished)
	{
		if (bounce)
		{
			[UIView animateWithDuration:0.10 animations:^
			{
				frame.origin.y = -15;
				self.frame = frame;
			}
			completion:^(BOOL finished)
			{
				[UIView animateWithDuration:0.10 animations:^
				{
					frame.origin.y = 0;
					self.frame = frame;
				}];
			}];
		}
	}];
}

- (void) uuAnimateHideToTop:(BOOL)removeFromSuperview
{
	__block CGRect frame = self.frame;
	frame.origin.y = -frame.size.height;
	
	[UIView animateWithDuration:0.25 animations:^
	{
		self.frame = frame;
	}
	completion:^(BOOL finished)
	{
		if (finished && removeFromSuperview)
		{
			[self removeFromSuperview];
		}
	}];
}


- (void) uuAnimateAppearFromBottom:(BOOL)bounce
{
	__block CGRect frame = self.frame;
	__block CGRect parentFrame = self.superview.frame;
	frame.origin.y = parentFrame.size.height;
	self.frame = frame;
	
	frame.origin.y = parentFrame.size.height - frame.size.height;
	if (bounce)
		frame.origin.y -= 20;
		
	[UIView animateWithDuration:0.25 animations:^
	{
		self.frame = frame;
	}
	completion:^(BOOL finished)
	{
		if (bounce)
		{
			[UIView animateWithDuration:0.10 animations:^
			{
				frame.origin.y = parentFrame.size.height - frame.size.height + 15;
				self.frame = frame;
			}
			completion:^(BOOL finished)
			{
				[UIView animateWithDuration:0.10 animations:^
				{
					frame.origin.y = parentFrame.size.height - frame.size.height;
					self.frame = frame;
				}];
			}];
		}
	}];
}

- (void) uuAnimateHideToBottom:(BOOL)removeFromSuperview
{
	CGRect frame = self.frame;
	CGRect parentFrame = self.superview.frame;
	frame.origin.y = parentFrame.size.height;
		
	[UIView animateWithDuration:0.25 animations:^
	{
		self.frame = frame;
	}
	completion:^(BOOL finished)
	{
		if (finished && removeFromSuperview)
		{
			[self removeFromSuperview];
		}
	}];
}

- (void) uuAnimateZoomAppearFromCenter:(BOOL)bounce
{
	self.transform = CGAffineTransformMakeScale(0.01, 0.01);
	CGAffineTransform transform = (bounce) ? CGAffineTransformMakeScale(1.1, 1.1) : CGAffineTransformMakeScale(1.0, 1.0);
	[UIView animateWithDuration:0.25 animations:^
	{
		self.transform = transform;
	}
	completion:^(BOOL finished)
	{
		if (bounce)
		{
			[UIView animateWithDuration:0.15 animations:^
			{
				self.transform = CGAffineTransformMakeScale(1.0, 1.0);
			}];
		}
	}];
}

- (void) uuAnimateZoomDisappearFromCenter:(BOOL)removeFromSuperview
{
	[UIView animateWithDuration:0.35 animations:^
	{
		self.transform = CGAffineTransformMakeScale(0.01, 0.01);
	}
	completion:^(BOOL finished)
	{
		self.alpha = 0.0;
		
		if (finished && removeFromSuperview)
		{
			self.alpha = 1.0;
			self.transform = CGAffineTransformMakeScale(1.0, 1.0);
			[self removeFromSuperview];
		}
	}];
}


- (void) uuAnimateFadeAppear
{
	self.alpha = 0.0;
	
	[UIView animateWithDuration:0.35 animations:^
	{
		self.alpha = 1.0;
	}
	completion:^(BOOL finished)
	{
	}];
}

- (void) uuAnimateFadeDisappear:(BOOL)removeFromSuperview
{
	[UIView animateWithDuration:0.35 animations:^
	{
		self.alpha = 0.0;
	}
	completion:^(BOOL finished)
	{
		if (finished && removeFromSuperview)
		{
			self.alpha = 1.0;
			[self removeFromSuperview];
		}
	}];
}


@end










#define kUUUILabelOriginalFrameKey @"UUUILabelOriginalFrameKey"

@implementation UIView (UUViewPositioning)

- (CGRect) uuOriginalFrame
{
    NSValue* val = objc_getAssociatedObject(self, kUUUILabelOriginalFrameKey);
    if (!val)
    {
        val = [NSValue valueWithCGRect:self.frame];
        objc_setAssociatedObject(self, kUUUILabelOriginalFrameKey, val, OBJC_ASSOCIATION_RETAIN);
    }
    
    return [val CGRectValue];
}

- (void) uuPositionRightOf:(UIView*)anchorView withSpacing:(CGFloat)spacing
{
    CGRect f = self.frame;
    f.origin.x = anchorView.frame.origin.x + anchorView.frame.size.width + spacing;
    self.frame = f;
}

- (void) uuPositionLeftOf:(UIView*)anchorView withSpacing:(CGFloat)spacing
{
    CGRect f = self.frame;
    f.origin.x = anchorView.frame.origin.x - self.frame.size.width - spacing;
    self.frame = f;
}

- (void) uuPositionBelow:(UIView*)anchorView withSpacing:(CGFloat)spacing
{
    CGRect f = self.frame;
    f.origin.y = anchorView.frame.origin.y + anchorView.frame.size.height + spacing;
    self.frame = f;
}

- (void) uuPositionAbove:(UIView*)anchorView withSpacing:(CGFloat)spacing
{
    CGRect f = self.frame;
    f.origin.y = anchorView.frame.origin.y - self.frame.size.height - spacing;
    self.frame = f;
}

// Align view center points
- (void) uuAlignVerticalCenter:(UIView*)anchorView
{
    CGPoint p = self.center;
    p.y = anchorView.center.y;
    self.center = p;
}

- (void) uuAlignHorizontalCenter:(UIView*)anchorView
{
    CGPoint p = self.center;
    p.x = anchorView.center.x;
    self.center = p;
}

- (void) uuAlignLeft:(UIView*)anchorView margin:(CGFloat)margin
{
    CGRect f = self.frame;
    f.origin.x = anchorView.frame.origin.x + margin;
    self.frame = f;
}

- (void) uuAlignRight:(UIView*)anchorView margin:(CGFloat)margin
{
    CGRect f = self.frame;
    f.origin.x = anchorView.frame.origin.x + anchorView.frame.size.width - f.size.width - margin;
    self.frame = f;
}

- (void) uuAlignTop:(UIView*)anchorView margin:(CGFloat)margin
{
    CGRect f = self.frame;
    f.origin.y = anchorView.frame.origin.y + margin;
    self.frame = f;
}

- (void) uuAlignBottom:(UIView*)anchorView margin:(CGFloat)margin
{
    CGRect f = self.frame;
    f.origin.y = anchorView.frame.origin.y + anchorView.frame.size.height - f.size.height - margin;
    self.frame = f;
}

- (void) uuAlignToParentLeft:(CGFloat)margin
{
    CGRect f = self.frame;
    f.origin.x = margin;
    self.frame = f;
}

- (void) uuAlignToParentRight:(CGFloat)margin
{
    CGRect f = self.frame;
    f.origin.x = self.superview.bounds.size.width - f.size.width - margin;
    self.frame = f;
}

- (void) uuAlignToParentBottom:(CGFloat)margin
{
    CGRect f = self.frame;
    f.origin.y = self.superview.bounds.size.height - f.size.height - margin;
    self.frame = f;
}

- (void) uuAlignToParentTop:(CGFloat)margin
{
    CGRect f = self.frame;
    f.origin.y = margin;
    self.frame = f;
}

- (void) uuCenterHorizontallyInParent
{
    CGRect f = self.frame;
    f.origin.x = (self.superview.bounds.size.width - f.size.width) / 2.0f;
    self.frame = f;
}

- (void) uuCenterVerticallyInParent
{
    CGRect f = self.frame;
    f.origin.y = (self.superview.bounds.size.height - f.size.height) / 2.0f;
    self.frame = f;
}

- (void) uuCenterInParent
{
    CGRect f = self.frame;
    f.origin.x = (self.superview.bounds.size.width - f.size.width) / 2.0f;
    f.origin.y = (self.superview.bounds.size.height - f.size.height) / 2.0f;
    self.frame = f;
}


@end


#define kUUNoResizingConstraint -1

@implementation UIView (UUViewResizing)

- (void) uuResizeWidth
{
    [self uuResizeWidth:kUUNoResizingConstraint];
}

- (void) uuResizeWidth:(CGFloat)minimumWidth
{
    CGRect originalFrame = [self uuOriginalFrame];
    
    self.frame = originalFrame;
    [self sizeToFit];
    
    CGRect f = originalFrame;
    f.size.width = self.frame.size.width;
    if (minimumWidth > 0 && f.size.width < minimumWidth)
    {
        f.size.width = minimumWidth;
    }
    
    self.frame = f;
}

- (void) uuResizeWidthOriginalAsMin
{
    CGRect originalFrame = [self uuOriginalFrame];
    [self uuResizeWidth:originalFrame.size.width];
}

- (void) uuResizeHeight
{
    [self uuResizeHeight:kUUNoResizingConstraint];
}

- (void) uuResizeHeight:(CGFloat)minimumHeight
{
    CGRect originalFrame = [self uuOriginalFrame];
    
    self.frame = originalFrame;
    [self sizeToFit];
    
    CGRect f = originalFrame;
    f.size.height = self.frame.size.height;
    if (minimumHeight > 0 && f.size.height < minimumHeight)
    {
        f.size.height = minimumHeight;
    }
    
    self.frame = f;
}

- (void) uuResizeHeightOriginalAsMin
{
    CGRect originalFrame = [self uuOriginalFrame];
    [self uuResizeHeight:originalFrame.size.height];
}

- (void) uuResizeWidthAndHeight
{
    [self uuResizeWidthAndHeight:UIEdgeInsetsZero minSize:CGSizeMake(kUUNoResizingConstraint, kUUNoResizingConstraint)];
}

- (void) uuResizeWidthAndHeight:(UIEdgeInsets)padding minSize:(CGSize)minSize
{
    self.frame = [self uuOriginalFrame];
    [self sizeToFit];
    
    CGRect f = self.frame;
    
    if (minSize.width > 0 && f.size.width < minSize.width)
    {
        f.size.width = minSize.width;
    }
    
    if (minSize.height > 0 && f.size.height < minSize.height)
    {
        f.size.height = minSize.height;
    }
    
    f.origin.x -= padding.left;
    f.origin.y -= padding.top;
    f.size.height += (padding.top + padding.bottom);
    f.size.width += (padding.left + padding.right);
    self.frame = f;
}

@end
