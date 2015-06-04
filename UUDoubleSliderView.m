//
//  UUDoubleSliderView.h
//  Useful Utilities - A replacement for the UISliderView that can have both ends adjusted
//
//  Created by Jonathan Hays on 6/02/15.
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com
//

#import "UUDoubleSliderView.h"

@interface UUDoubleSliderView()
	@property (nonatomic, retain) UIView* selectedBackground;
	@property (nonatomic, retain) UIView* unselectedBackground;

	@property (nonatomic, retain) UIImageView* minimumSlider;
	@property (nonatomic, retain) UIImageView* maximumSlider;

	@property (nonatomic, assign) float heightOfSlider;

@end

@implementation UUDoubleSliderView

- (CGRect) frameForSlider
{
	CGRect frame = self.bounds;
	frame.origin.x += self.minimumSlider.frame.size.width / 2.0;
	frame.size.width -= self.minimumSlider.frame.size.width / 2.0;
	frame.size.width -= self.maximumSlider.frame.size.width / 2.0;
	frame.origin.y += (frame.size.height - self.heightOfSlider) / 2.0;
	frame.size.height = self.heightOfSlider;
	return frame;
}

- (id) initWithFrame:(CGRect)frame sliderColor:(UIColor*)sliderColor
							   backgroundColor:(UIColor*)backgroundColor
									leftSlider:(UIImage*)leftSlider
								   rightSlider:(UIImage*)rightSlider
{
	self = [super initWithFrame:frame];
	if (self)
	{
		self.backgroundColor = [UIColor clearColor];
		
		self.userInteractionEnabled = YES;

		//Construct the slider images
		self.minimumSlider = [[UIImageView alloc] initWithImage:leftSlider];
		self.maximumSlider = [[UIImageView alloc] initWithImage:rightSlider];

		//Default it to half the height...
		self.heightOfSlider = frame.size.height / 2.0;

		//Setup the background
		CGRect sliderFrame = [self frameForSlider];
		self.unselectedBackground = [[UIView alloc] initWithFrame:sliderFrame];
		self.unselectedBackground.backgroundColor = backgroundColor;

		//Setup the foreground
		self.selectedBackground = [[UIView alloc] initWithFrame:sliderFrame];
		self.selectedBackground.backgroundColor = sliderColor;

		//Add the views in order
		[self addSubview:self.unselectedBackground];
		[self addSubview:self.selectedBackground];
		[self addSubview:self.minimumSlider];
		[self addSubview:self.maximumSlider];
		
		//Set initial values
		_minimumValue = 0.0;
		_maximumValue = 100.0;
		self.minimumSliderValue = 0.0;
		self.maximumSliderValue = 100.0;
		
		//Gestures
		UILongPressGestureRecognizer* gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(minimumLongPress:)];
		gestureRecognizer.delaysTouchesBegan = NO;
		gestureRecognizer.cancelsTouchesInView = YES;
		gestureRecognizer.minimumPressDuration = 0.0;
		[self.minimumSlider addGestureRecognizer:gestureRecognizer];
		self.minimumSlider.userInteractionEnabled = YES;

		gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(maximumLongPress:)];
		gestureRecognizer.delaysTouchesBegan = NO;
		gestureRecognizer.cancelsTouchesInView = YES;
		gestureRecognizer.minimumPressDuration = 0.0;
		[self.maximumSlider addGestureRecognizer:gestureRecognizer];
		self.maximumSlider.userInteractionEnabled = YES;
		
		//Give it a chance to layout
		[self updateSliders];
	}
	
	return self;
}

- (void) layoutSubviews
{
	[super layoutSubviews];
	[self updateSliders];
}

- (UIColor*) sliderColor
{
	return self.selectedBackground.backgroundColor;
}

- (UIColor*) sliderBackgroundColor
{
	return self.unselectedBackground.backgroundColor;
}

- (float) sliderHeight
{
	return self.heightOfSlider;
}

- (void) setSliderHeight:(float)sliderHeight
{
	self.heightOfSlider = sliderHeight;
	[self updateSliders];
}

- (void) setSliderColor:(UIColor *)sliderColor
{
	self.selectedBackground.backgroundColor = sliderColor;
}

- (void) setSliderBackgroundColor:(UIColor *)sliderBackgroundColor
{
	self.unselectedBackground.backgroundColor = sliderBackgroundColor;
}

- (void) setMinimumValue:(float)min
{
	_minimumValue = min;
	[self updateSliders];
}

- (void) setMaximumValue:(float)max
{
	_maximumValue = max;
	[self updateSliders];
}

- (void) setMinimumSliderValue:(float)min
{
	_minimumSliderValue = min;
	if (self.minimumSliderValue < self.minimumValue)
		self.minimumSliderValue = self.minimumValue;
    
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(minSliderValuesChanged:value:)])
    {
        [self.delegate minSliderValuesChanged:self value:self.minimumSliderValue];
    }
    
	[self updateSliders];
}

- (void) setMaximumSliderValue:(float)max
{
	_maximumSliderValue = max;
	if (self.maximumSliderValue > self.maximumValue)
		self.maximumSliderValue = self.maximumValue;
    
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(maxSliderValuesChanged:value:)])
    {
        [self.delegate maxSliderValuesChanged:self value:self.maximumSliderValue];
    }
		
	[self updateSliders];
}

- (float) valueForPosition:(float)position
{
	CGRect frameForSlider = [self frameForSlider];

	float percentage = (position - frameForSlider.origin.x) / frameForSlider.size.width;
	float range = self.maximumValue - self.minimumValue;
	float value = self.minimumValue + (percentage * range);
	return value;
}

- (float) positionForValue:(float)value
{
	CGRect frameForSlider = [self frameForSlider];

	float offset = (value - _minimumValue) / (_maximumValue - _minimumValue);
	float position = frameForSlider.origin.x + (offset * frameForSlider.size.width);
	return position;
}

- (void) updateSliders
{
	CGRect frameForSlider = [self frameForSlider];
	self.unselectedBackground.frame = frameForSlider;
	
	float leftPosition = [self positionForValue:self.minimumSliderValue];
	float rightPosition = [self positionForValue:self.maximumSliderValue];
	
	CGRect frame = frameForSlider;
	frame.origin.x = leftPosition;
	frame.size.width = rightPosition - frame.origin.x;
	self.selectedBackground.frame = frame;
	
	CGPoint center = self.selectedBackground.center;	
	center.x = leftPosition;
	self.minimumSlider.center = center;
	
	center.x = rightPosition;
	self.maximumSlider.center = center;
}

- (void) minimumLongPress:(UILongPressGestureRecognizer*)gesture
{
	CGRect frameForSlider = [self frameForSlider];
	NSInteger left = frameForSlider.origin.x;
	NSInteger right = left + frameForSlider.size.width;

	CGPoint location = [gesture locationInView:self];
	CGPoint current = self.minimumSlider.center;


	current.x = location.x;
	if (current.x < left)
	{
		current.x = left;
	}
	if (current.x > right)
	{
		current.x = right;
	}
	
	self.minimumSlider.center = current;

	if (self.minimumSlider.center.x >= self.maximumSlider.center.x || CGRectIntersectsRect(self.minimumSlider.frame, self.maximumSlider.frame))
	{
		CGRect frame = self.maximumSlider.frame;
		frame.origin.x -= frame.size.width;
		self.minimumSlider.frame = frame;
		current = self.minimumSlider.center;
	}
	
	float value = [self valueForPosition:current.x];
	[self setMinimumSliderValue:value];
}

- (void) maximumLongPress:(UILongPressGestureRecognizer*)gesture
{
	CGRect frameForSlider = [self frameForSlider];
	NSInteger left = frameForSlider.origin.x;
	NSInteger right = left + frameForSlider.size.width;
	
	CGPoint location = [gesture locationInView:self];
	CGPoint current = self.maximumSlider.center;
	current.x = location.x;
	if (current.x < left)
	{
		current.x = left;
	}
	if (current.x > right)
	{
		current.x = right;
	}
	
	self.maximumSlider.center = current;
	
	if (self.minimumSlider.center.x >= self.maximumSlider.center.x ||CGRectIntersectsRect(self.minimumSlider.frame, self.maximumSlider.frame))
	{
		CGRect frame = self.maximumSlider.frame;
		frame.origin.x = self.minimumSlider.frame.origin.x + self.minimumSlider.frame.size.width;
		self.maximumSlider.frame = frame;
		current = self.maximumSlider.center;
	}
	
	float value = [self valueForPosition:current.x];
	[self setMaximumSliderValue:value];
}


@end
