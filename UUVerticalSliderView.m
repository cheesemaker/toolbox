//
//  UUVerticalSliderView.h
//  Useful Utilities - Vertical slider view drop in replacement for OS horizontal slider
//
//  (c) 2014, Jonathan Hays. All Rights Reserved.
//
//	Smile License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@silverpinesoftware.com

#import "UUVerticalSliderView.h"

#ifndef UU_MEMORY_MANAGEMENT
#if !__has_feature(objc_arc)
#define UU_AUTORELEASE(x) [(x) autorelease]
#define UU_RELEASE(x)	  [(x) release]
#else
#define UU_AUTORELEASE(x) x
#define UU_RELEASE(x)     (void)(0)
#endif
#endif

@interface UUVerticalSliderView()
	@property (nonatomic, strong) UIImageView* background;
	@property (nonatomic, strong) UIImageView* sliderImage;
	@property (nonatomic, strong) UILongPressGestureRecognizer* gestureRecognizer;
@end

@implementation UUVerticalSliderView

@synthesize minimumValue = _minimumValue;
@synthesize maximumValue = _maximumValue;

+ (UIImage*) defaultSliderImage
{
	CGFloat borderWidth = 2;
	UIColor* color = [UIColor blueColor];
	UIColor* borderColor = [UIColor colorWithWhite:0.98 alpha:0.9];
	
    CGRect rect = CGRectMake(0, 0, 40, 40);
    
    UIView* view = [[UIView alloc] initWithFrame:rect];
    view.backgroundColor = color;
    view.layer.borderColor = [borderColor CGColor];
    view.layer.cornerRadius = rect.size.height / 2.0;
    view.layer.masksToBounds = YES;
    view.layer.borderWidth = borderWidth;
	view.layer.contentsScale = [[UIScreen mainScreen] scale];
	
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    
    [view.layer renderInContext:outputContext];
    
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (instancetype) initWithBackground:(UIImage*)background andSlider:(UIImage*)slider
{
	self = [super initWithFrame:CGRectMake(0, 0, background.size.width, background.size.height + (slider.size.height / 2.0))];
	if (self)
	{
		self.backgroundColor = [UIColor clearColor];
		self.background = UU_AUTORELEASE([[UIImageView alloc] initWithImage:background]);
		[self addSubview:self.background];
		
		self.userInteractionEnabled = YES;

		self.sliderImage = UU_AUTORELEASE([[UIImageView alloc] initWithImage:slider]);
		[self addSubview:self.sliderImage];
		self.sliderImage.center = self.center;
		
		_minimumValue = 0.0;
		_maximumValue = 100.0;
		[self updateSliders];
		
		self.gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(minimumLongPress:)];
		self.gestureRecognizer.delaysTouchesBegan = NO;
		self.gestureRecognizer.cancelsTouchesInView = YES;
		self.gestureRecognizer.minimumPressDuration = 0.0;
		
		[self.sliderImage addGestureRecognizer:self.gestureRecognizer];
		self.sliderImage.userInteractionEnabled = YES;
		UU_RELEASE(gestureRecognizer);
	}
	
	return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		self.backgroundColor = [UIColor clearColor];

		self.userInteractionEnabled = YES;
		UIImage* slider = [UUVerticalSliderView defaultSliderImage];

		self.sliderImage = UU_AUTORELEASE([[UIImageView alloc] initWithImage:slider]);
		[self addSubview:self.sliderImage];
		
		frame.origin.y -= (slider.size.height / 2.0);
		frame.size.height += (slider.size.height);
		self.frame = frame;
		
		_minimumValue = 0.0;
		_maximumValue = 100.0;
		[self updateSliders];
		
		UILongPressGestureRecognizer* gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(minimumLongPress:)];
		gestureRecognizer.delaysTouchesBegan = NO;
		gestureRecognizer.cancelsTouchesInView = YES;
		gestureRecognizer.minimumPressDuration = 0.0;
		[self.sliderImage addGestureRecognizer:gestureRecognizer];
		self.sliderImage.userInteractionEnabled = YES;
		UU_RELEASE(gestureRecognizer);
	}
	
	return self;
}

- (float) minimumValue
{
	return _minimumValue;
}

- (float) maximumValue
{
	return _maximumValue;
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

- (void) setValue:(float)val
{
	[self setSliderValue:val];
}

- (void) setThumbImage:(UIImage *)image forState:(UIControlState)state
{
	self.sliderImage.image = image;
	
}

- (void) setTrackImage:(UIImage *)image forState:(UIControlState)state
{
	if (!self.background)
	{
		self.background = UU_AUTORELEASE([[UIImageView alloc] initWithImage:image]);
		self.background.frame = self.bounds;
		[self addSubview:self.background];
				
		[self bringSubviewToFront:self.sliderImage];
	}
	else
	{
		self.background.image = image;
	}
}

- (float) sliderHeight
{
	return self.frame.size.height - self.sliderImage.frame.size.height;
}

- (float) sliderMinPosition
{
	return (self.sliderImage.frame.size.height / 2.0);
}

- (float) sliderMaxPosition
{
	return self.frame.size.height - (self.sliderImage.frame.size.height / 2.0);
}

- (float) valueForPosition:(float)position
{
	position -= [self sliderMinPosition];
	
	float percentage = position / [self sliderHeight];
	float range = self.maximumValue - self.minimumValue;
	float value = self.minimumValue + (percentage * range);
	return value;
}

- (float) positionForValue:(float)value
{
	float offset = (value - _minimumValue) / (_maximumValue - _minimumValue);
	float height = [self sliderHeight];
	float position = offset * height;
	return position + [self sliderMinPosition];
}

- (void) updateSliders
{
	float topPosition = [self positionForValue:self.value];
	if (topPosition < [self sliderMinPosition])
	{
		topPosition = [self sliderMinPosition];
	}
	if (topPosition > [self sliderMaxPosition])
	{
		topPosition = [self sliderMaxPosition];
	}
	
	CGPoint center = CGPointMake(self.frame.size.width / 2.0, topPosition);
	self.sliderImage.center = center;
}

- (void) setSliderValue:(float)min
{
	_value = min;
	
	if (self.snapToIntegerValues)
	{
		_value = (int)(_value + 0.5);
	}
	
	if (self.value < self.minimumValue)
		self.value = self.minimumValue;
	if (self.value > self.maximumValue)
		self.value = self.maximumValue;
    
	[self updateSliders];
	
	NSArray* allTargets = [[self allTargets] allObjects];
	for (id target in allTargets)
	{
		NSArray* actions = [self actionsForTarget:target forControlEvent:UIControlEventValueChanged];
		for (NSString* actionName in actions)
		{
			SEL selector = NSSelectorFromString(actionName);
			
			//Since we KNOW this doesn't cause a leak, we suppress the warning
			#pragma clang diagnostic push
			#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			[target performSelector:selector withObject:self];
			#pragma clang diagnostic pop
		}
	}
}

- (void) minimumLongPress:(UILongPressGestureRecognizer*)gesture
{
	CGPoint location = [gesture locationInView:self];
	CGPoint current = self.sliderImage.center;
	current.y = location.y;
	if (current.y < 0)
		current.y = 0;
	if (current.y > self.frame.size.height)
		current.y = self.frame.size.height;
		
	self.sliderImage.center = current;
	
	float value = [self valueForPosition:current.y];
	[self setSliderValue:value];
	
	if (gesture.state == UIGestureRecognizerStateBegan)
	{
		NSArray* allTargets = [[self allTargets] allObjects];
		for (id target in allTargets)
		{
			NSArray* actions = [self actionsForTarget:target forControlEvent:UIControlEventTouchDown];
			for (NSString* actionName in actions)
			{
				SEL selector = NSSelectorFromString(actionName);
			
				//Since we KNOW this doesn't cause a leak, we suppress the warning
				#pragma clang diagnostic push
				#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
				[target performSelector:selector withObject:self];
				#pragma clang diagnostic pop
			}
		}
	}
}

- (void) setEnabled:(BOOL)enabled
{
	self.gestureRecognizer.enabled = enabled;
}

@end
