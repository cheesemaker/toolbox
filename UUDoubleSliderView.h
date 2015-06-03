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

#import <UIKit/UIKit.h>

@class UUDoubleSliderView;

@protocol UUDoubleSliderViewDelegate <NSObject>
@optional
	- (void) minSliderValuesChanged:(UUDoubleSliderView*)slider value:(float)value;
	- (void) maxSliderValuesChanged:(UUDoubleSliderView*)slider value:(float)value;
@end

@interface UUDoubleSliderView : UIView

- (id) initWithFrame:(CGRect)frame sliderColor:(UIColor*)sliderColor
							   backgroundColor:(UIColor*)backgroundColor
									leftSlider:(UIImage*)leftSlider
								   rightSlider:(UIImage*)rightSlider;

// Default values are 0.0 and 100.0
@property (nonatomic, assign) float minimumValue;
@property (nonatomic, assign) float maximumValue;
@property (nonatomic, assign) float minimumSliderValue;
@property (nonatomic, assign) float maximumSliderValue;

//Customization of the slider bar
@property (nonatomic, assign) float sliderHeight;
@property (nonatomic, assign) UIColor* sliderColor;
@property (nonatomic, assign) UIColor* sliderBackgroundColor;

// Delegate for slider notifications
@property (nonatomic, retain) NSObject<UUDoubleSliderViewDelegate>* delegate;

@end
