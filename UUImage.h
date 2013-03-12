//
//  UUImage.h
//  Useful Utilities - UIImage extensions
//
//  Created by Jonathan on 3/11/13.
//  Copyright (c) 2013 Three Jacks Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIImage (UUFramework)

- (UIImage*) scaleToSize:(CGSize)targetSize;
- (UIImage*) scaleAndCropToSize:(CGSize)targetSize;
- (UIImage*) cropToSize:(CGSize)targetSize;

- (UIImage*) uuScaleToWidth:(CGFloat)width;

+ (UIImage*) uuMakeStretchableImage:(NSString*)imageName insets:(UIEdgeInsets)insets;

@end