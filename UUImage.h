//
//  UUImage.h
//  Useful Utilities - UIImage extensions
//
//  Created by Jonathan on 3/11/13.
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import <UIKit/UIKit.h>

@interface UIImage (UUFramework)

- (UIImage*) uuRemoveOrientation;
- (UIImage*) uuScaleToSize:(CGSize)targetSize;
- (UIImage*) uuScaleAndCropToSize:(CGSize)targetSize;
- (UIImage*) uuCropToSize:(CGSize)targetSize;
- (UIImage*) uuBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage *)maskImage;

+ (UIImage*) uuViewToImage:(UIView*)view;

- (UIImage*) uuScaleToWidth:(CGFloat)width;
- (UIImage*) uuScaleToHeight:(CGFloat)height;

// Picks the smaller of height or width and scales the image 
- (UIImage*) uuScaleSmallestDimensionToSize:(CGFloat)size;

- (CGSize) uuCalculateScaleToWidthDestSize:(CGFloat)width;
- (CGSize) uuCalculateScaleToHeightDestSize:(CGFloat)height;
- (CGSize) uuCalculateScaleToFitDestSize:(CGFloat)size;

// Pure math functions handy to use in layout methods
+ (CGSize) uuCalculateScaleToWidthDestSize:(CGFloat)width fromSize:(CGSize)srcSize;
+ (CGSize) uuCalculateScaleToHeightDestSize:(CGFloat)height fromSize:(CGSize)srcSize;

+ (UIImage*) uuMakeStretchableImage:(NSString*)imageName insets:(UIEdgeInsets)insets;

+ (UIImage*) uuSolidColorImage:(UIColor*)color;
+ (UIImage*) uuSolidColorImage:(UIColor*)color cornerRadius:(CGFloat)cornerRadius borderColor:(UIColor*)borderColor borderWidth:(CGFloat)borderWidth;

+ (UIImage*) uuSolidColorImage:(UIColor*)color
                  cornerRadius:(CGFloat)cornerRadius
                   borderColor:(UIColor*)borderColor
                   borderWidth:(CGFloat)borderWidth
                roundedCorners:(UIRectCorner)roundedCorners;

@end


@interface UIImage (UUAnimatedGIF)

+ (UIImage*) uuImageWithGIFData:(NSData*)data;

@end