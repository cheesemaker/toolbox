//
//  UUProgressView.h
//
//  Created by Jonathan on 3/19/13.
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com


#import "UUProgressView.h"
#import <QuartzCore/QuartzCore.h>

@interface UUProgressView ()

@property (nonatomic, retain) UIView* backgroundView;
@property (nonatomic, retain) UILabel* label;
@property (nonatomic, retain) UIActivityIndicatorView* spinner;

- (void) createLabelView;
- (void) createSpinnerView;
- (void) createBackgroundView;

- (void) showProgressViewWithBounceAnimation;
- (void) hideProgressViewWithBounceAnimation;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation UUProgressView

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Static Interface
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (UUProgressView*) globalProgressView
{
	static UUProgressView* theProgressView = nil;
    
	if (theProgressView == nil)
    {
        theProgressView = [[UUProgressView alloc] initWithMessage:@"Loading..."];
        
        UIView* parent = [[UIApplication sharedApplication] keyWindow];
        theProgressView.center = parent.center;
        [parent addSubview:theProgressView];
    }
    
    return theProgressView;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id) initWithMessage:(NSString*)message
{
    self = [super initWithFrame:CGRectMake(0, 0, 145, 44)];
    
    if (self != nil)
    {
		[self createBackgroundView];
		[self createSpinnerView];
        [self createLabelView];
        
		self.label.text = message;
        self.layer.cornerRadius = 10.0f;
        self.layer.masksToBounds = YES;
    }
    
    return self;
}

- (void) dealloc
{
    self.backgroundView = nil;
    self.label = nil;
    self.spinner = nil;
    
    [super dealloc];
}

- (void) createBackgroundView
{
	self.backgroundView = [[[UIView alloc] initWithFrame:self.frame] autorelease];
	self.backgroundView.backgroundColor = [UIColor blackColor];
	self.backgroundView.alpha = 0.75f;
	self.backgroundView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin  | UIViewAutoresizingFlexibleWidth |
											UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin |
											UIViewAutoresizingFlexibleHeight |  UIViewAutoresizingFlexibleBottomMargin);

	[self addSubview:self.backgroundView];
}

- (void) createSpinnerView
{
	CGFloat halfHeight = self.frame.size.height / 2.0f;
	self.spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
	self.spinner.center = CGPointMake(18, halfHeight);
	self.spinner.hidesWhenStopped = YES;
	[self.spinner startAnimating];
	[self addSubview:self.spinner];
}

- (void) createLabelView
{
	CGFloat halfHeight = self.frame.size.height / 2.0f;
	CGFloat quarterHeight = halfHeight / 2.0f;
	self.label = [[[UILabel alloc] initWithFrame:CGRectMake(42, quarterHeight, 103 , halfHeight)] autorelease];
	self.label.textAlignment = UITextAlignmentLeft;
	self.label.textColor = [UIColor whiteColor];
	self.label.backgroundColor = [UIColor clearColor];
	self.label.font = [UIFont boldSystemFontOfSize:14.0f];
	self.label.numberOfLines = 2;
	self.label.adjustsFontSizeToFitWidth = YES;
	[self addSubview:self.label];
}

- (void) updateMessage:(NSString*)message
{
    self.label.text = message;
	[self.label sizeToFit];
}

- (void) show:(BOOL)animated
{
    [self showProgressViewWithBounceAnimation];
}

- (void) hide:(BOOL)animated
{
	[self hideProgressViewWithBounceAnimation];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Show and Hide Animations
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) showProgressViewWithBounceAnimation
{
    self.transform = CGAffineTransformMakeScale(0.001, 0.001);
    self.hidden = NO;
	
	[UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^
	{
		self.transform = CGAffineTransformMakeScale(1.1, 1.1);
		
	}
	completion:^(BOOL finished)
	{
		[UIView animateWithDuration:0.1f delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^
		{
			self.transform = CGAffineTransformMakeScale(0.95, 0.95);
		}
		completion:^(BOOL finished)
		{
			[UIView animateWithDuration:0.1f delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^
			{
				self.transform = CGAffineTransformIdentity;
			}
			completion:nil];
		}];
	}];    
}

- (void) hideProgressViewWithBounceAnimation
{
	[UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^
	{
		self.transform = CGAffineTransformMakeScale(0.001, 0.001);
	}
	completion:^(BOOL finished)
	{
		self.hidden = YES;
	}];
}

@end
