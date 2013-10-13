//
//  UUView
//  Useful Utilities - UIView extensions to animate appearance and disappearance of views
// (c) Copyright Jonathan Hays, all rights reserved
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import <UIKit/UIKit.h>

@interface UIView (UUFramework)

// The animate functions assume that you have already added the view to whatever superview they will be part of.
// However, you do not need to set initial screen offsets for these to work. They will automatically adjust
// based on the size and location of the superview that it is added to.

- (void) uuAnimateAppearFromTop:(BOOL)bounce;
- (void) uuAnimateHideToTop:(BOOL)removeFromSuperview;

- (void) uuAnimateAppearFromBottom:(BOOL)bounce;
- (void) uuAnimateHideToBottom:(BOOL)removeFromSuperview;

- (void) uuAnimateZoomAppearFromCenter:(BOOL)bounce;
- (void) uuAnimateZoomDisappearFromCenter:(BOOL)removeFromSuperview;

- (void) uuAnimateFadeAppear;
- (void) uuAnimateFadeDisappear:(BOOL)removeFromSuperview;

@end
