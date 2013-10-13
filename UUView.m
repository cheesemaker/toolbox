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
