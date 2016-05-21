//
//  UUView
//  Useful Utilities - UIView extensions to animate appearance and disappearance of views
// (c) Copyright Jonathan Hays, all rights reserved
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@silverpine.com

#import <UIKit/UIKit.h>

/*

Disabling this until Xcode can be fixed and stop crashing

// These extensions allow you to set commonly set layer properties directly in Interface Builder
// Have suggestions for others? Let me know or submit a pull request!
IB_DESIGNABLE @interface UIView (UUInterfaceBuilder)
	@property (nonatomic) IBInspectable CGFloat cornerRadius;
	@property (nonatomic) IBInspectable BOOL	circular;
@end
*/

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

@interface UIView (UUViewPositioning)

// The original frame of this view, as defined in either a XIB or an initWithFrame
- (CGRect) uuOriginalFrame;

// Positioning helpers to move the frame relative to an anchor view
- (void) uuPositionRightOf:(UIView*)anchorView withSpacing:(CGFloat)spacing;
- (void) uuPositionLeftOf:(UIView*)anchorView withSpacing:(CGFloat)spacing;
- (void) uuPositionBelow:(UIView*)anchorView withSpacing:(CGFloat)spacing;
- (void) uuPositionAbove:(UIView*)anchorView withSpacing:(CGFloat)spacing;

// Align view center points
- (void) uuAlignVerticalCenter:(UIView*)anchorView;
- (void) uuAlignHorizontalCenter:(UIView*)anchorView;

// Alignment helpers to move the frame to align with an anchor view
- (void) uuAlignLeft:(UIView*)anchorView margin:(CGFloat)margin;
- (void) uuAlignRight:(UIView*)anchorView margin:(CGFloat)margin;
- (void) uuAlignTop:(UIView*)anchorView margin:(CGFloat)margin;
- (void) uuAlignBottom:(UIView*)anchorView margin:(CGFloat)margin;

// Convenience alignment methods
- (void) uuAlignToParentLeft:(CGFloat)margin;
- (void) uuAlignToParentRight:(CGFloat)margin;
- (void) uuAlignToParentBottom:(CGFloat)margin;
- (void) uuAlignToParentTop:(CGFloat)margin;

// Centering methods
- (void) uuCenterHorizontallyInParent;
- (void) uuCenterVerticallyInParent;
- (void) uuCenterInParent;

@end

@interface UIView (UUViewResizing)

// Resizes only a view's width to fit its contents
- (void) uuResizeWidth;

// Resizes width with a minimum constraint. Passing a negative value will not
// enforce a minimum
- (void) uuResizeWidth:(CGFloat)minimumWidth;

// Convenience method to resize the width while passing the original height as
// the minimum constraint.
- (void) uuResizeWidthOriginalAsMin;

// Resizes only a view's height to fit its contents
- (void) uuResizeHeight;

// Resizes height with a minimum constraint. Passing a negative value will not
// enforce a minimum
- (void) uuResizeHeight:(CGFloat)minimumHeight;

// Convenience method to resize the height while passing the original height as
// the minimum constraint.
- (void) uuResizeHeightOriginalAsMin;

// Resizes both width and height.  This is equivalent to sizeToFit with the
// exception that the original frame is restored prior to calling sizeToFit.
// This is useful when dynamically resizing text views inside of table cells
// where the text view frame might shrink from one cell to the next.
- (void) uuResizeWidthAndHeight;

// Resizes both width and height with a fixed amount of padding and optional
// minimum sizes
- (void) uuResizeWidthAndHeight:(UIEdgeInsets)padding minSize:(CGSize)minSize;

@end