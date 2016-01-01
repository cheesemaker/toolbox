//
//  UUGradientView.m
//  Useful Utilities - Handy helpers for a custom gradient view
//
//  Created by Ryan DeVore on 12/31/15.
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//

#import "UUGradientView.h"

@interface UUGradientView ()

@end

@implementation UUGradientView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        self.leftColor = [UIColor clearColor];
        self.rightColor = [UIColor clearColor];
        self.midPoint = 0.5f;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.opaque = NO;
    }
    return self;
}

- (void) setLeftColor:(UIColor *)leftColor
{
    _leftColor = leftColor;
    [self setNeedsDisplay];
}

- (void) setRightColor:(UIColor *)rightColor
{
    _rightColor = rightColor;
    [self setNeedsDisplay];
}

- (void) setMidPoint:(CGFloat)midPoint
{
    _midPoint = midPoint;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat leftColors[4] = { 0.0f, 0.0f, 0.0f, 0.0f };
    [self.leftColor getRed:&leftColors[0] green:&leftColors[1] blue:&leftColors[2] alpha:&leftColors[3]];

    CGFloat rightColors[4] = { 0.0f, 0.0f, 0.0f, 0.0f };
    [self.rightColor getRed:&rightColors[0] green:&rightColors[1] blue:&rightColors[2] alpha:&rightColors[3]];

    CGFloat midRed = (leftColors[0] + rightColors[0]) / 2.0f;
    CGFloat midGreen = (leftColors[1] + rightColors[1]) / 2.0f;
    CGFloat midBlue = (leftColors[2] + rightColors[2]) / 2.0f;
    CGFloat midAlpha = (leftColors[3] + rightColors[3]) / 2.0f;

    UIColor* midColor = [UIColor colorWithRed:midRed green:midGreen blue:midBlue alpha:midAlpha];

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, self.midPoint, 1.0 };
    
    NSArray *colors = @[(__bridge id) self.leftColor.CGColor, (__bridge id) midColor.CGColor, (__bridge id) self.rightColor.CGColor];
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) colors, locations);
    
    CGPoint startPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMidY(rect));
    CGPoint endPoint = CGPointMake(CGRectGetMaxX(rect), CGRectGetMidY(rect));
    
    CGContextSaveGState(context);
    CGContextAddRect(context, rect);
    CGContextClip(context);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    CGContextRestoreGState(context);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}

@end