//
//  UUGradientView.h
//  Useful Utilities - Handy helpers for a custom gradient view
//
//  Created by Ryan DeVore on 12/31/15.
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE @interface UUGradientView : UIView

@property (nonatomic, strong) IBInspectable UIColor* leftColor;
@property (nonatomic, strong) IBInspectable UIColor* rightColor;
@property (nonatomic, assign) IBInspectable CGFloat midPoint;

@end