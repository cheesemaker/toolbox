//
//  UUColor.h
//  Useful Utilities - Extensions for conveniently creating colors
//
//  Created by Jonathan on 7/29/13.
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import <UIKit/UIKit.h>

@interface UIColor (UUColorCreation)

+ (UIColor*) uuColorFromHex:(NSString*)color;
+ (UIColor*) uuColorWithRed:(int)red Green:(int)green Blue:(int)blue;

@end