//
//  UUColor.m
//  Useful Utilities - Extensions for conveniently creating colors
//
//  Created by Jonathan on 7/29/13.
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import "UUColor.h"

@implementation UIColor (UUColorCreation)

+ (UIColor*) uuColorFromHex:(NSString*)color
{
    CGFloat rgba[4] = {0, 0, 0, 1};
    
    if (color && (color.length == 6 || color.length == 8))
    {
        for (int i = 0; i < color.length; i += 2)
        {
            NSScanner* sc = [NSScanner scannerWithString:(NSString*)[color substringWithRange:NSMakeRange(i, 2)]];
            unsigned int hex = 0;
            [sc scanHexInt:&hex];
            rgba[i/2] = (hex / 255.0f);
        }
    }
    
    UIColor* c = [UIColor colorWithRed:rgba[0] green:rgba[1] blue:rgba[2] alpha:rgba[3]];
    return c;
}

+ (UIColor*) uuColorWithRed:(int)red Green:(int)green Blue:(int)blue
{
	return [UIColor colorWithRed:(float)red / 255.0 green:(float)green / 255.0 blue:(float)blue / 255.0 alpha:1.0];
}

@end
