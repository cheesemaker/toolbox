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

#import <UIKit/UIKit.h>

@interface UUVerticalSliderView : UIControl

- (instancetype) initWithFrame:(CGRect)frame;
- (instancetype) initWithBackground:(UIImage*)background andSlider:(UIImage*)slider; //Uses the background image as the frame

@property (nonatomic, assign) float value;          // default 0.0. this value will be pinned to min/max
@property (nonatomic, assign) float minimumValue;
@property (nonatomic, assign) float maximumValue;

@property (nonatomic, assign) BOOL snapToIntegerValues;

- (void) setThumbImage:(UIImage *)image forState:(UIControlState)state;
- (void) setTrackImage:(UIImage *)image forState:(UIControlState)state;

@end

