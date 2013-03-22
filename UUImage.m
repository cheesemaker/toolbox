//
//  UUImage.m
//  Useful Utilities - UIImage extensions
//
//  Created by Jonathan on 3/11/13.
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import "UUImage.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIImage+UUFramework
/////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation UIImage (UUFramework)

- (UIImage*) uuCropToSize:(CGSize)targetSize
{
    UIGraphicsBeginImageContext(targetSize); // this will crop

    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = CGPointMake(0, 0);
    thumbnailRect.size.width  = self.size.width;
    thumbnailRect.size.height = self.size.height;

    [self drawInRect:thumbnailRect];

    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();

    //pop the context to get back to the default
    UIGraphicsEndImageContext();

    return newImage;
}

- (UIImage*) uuScaleToSize:(CGSize)targetSize
{
    UIImage *newImage = nil;
    
    CGSize imageSize = self.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) 
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor < heightFactor) 
            scaleFactor = widthFactor;
        else
            scaleFactor = heightFactor;
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        
        if (widthFactor < heightFactor) 
        {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5; 
        } 
        else if (widthFactor > heightFactor) 
        {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    
    // this is actually the interesting part:
    
    UIGraphicsBeginImageContext(targetSize);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [self drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if(newImage == nil) 
    {
        //NSLog(@"could not scale image");
        newImage = self;
    }
    
    return newImage;
}

- (UIImage*) uuScaleToWidth:(CGFloat)width
{
    UIImage *newImage = nil;
    
    CGSize srcSize = self.size;
    CGFloat srcWidth = srcSize.width;
    CGFloat srcHeight = srcSize.height;
    CGFloat srcAspectRatio = srcHeight / srcWidth;
    
    CGFloat targetWidth = width * ([[UIScreen mainScreen] scale]);
    CGFloat targetHeight = targetWidth * srcAspectRatio;
    
    CGSize destSize = CGSizeMake(targetWidth, targetHeight);
    
    // this is actually the interesting part:
    UIGraphicsBeginImageContext(destSize);
    
    CGRect destRect = CGRectZero;
    //destRect.origin = thumbnailPoint;
    destRect.size.width  = targetWidth;
    destRect.size.height = targetHeight;
    
    [self drawInRect:destRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if(newImage == nil)
    {
        //NSLog(@"could not scale image");
        newImage = self;
    }
    
    return newImage;
}

-(UIImage*) uuScaleAndCropToSize:(CGSize)targetSize
{
    CGFloat deviceScale = [[UIScreen mainScreen] scale];
    UIImage *sourceImage = self;
    UIImage *newImage = nil;    
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width * deviceScale;
    CGFloat targetHeight = targetSize.height * deviceScale;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);

    if (CGSizeEqualToSize(imageSize, targetSize) == NO) 
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;

        if (widthFactor > heightFactor) 
        {
            scaleFactor = widthFactor; // scale to fit height
        }
        else
        {
            scaleFactor = heightFactor; // scale to fit width
        }

        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;

        // center the image
        if (widthFactor > heightFactor)
        {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5; 
        }
        else
        {
            if (widthFactor < heightFactor)
            {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            }
        }
    }   

    // Adjust for scaling
    targetSize = CGSizeMake(targetWidth, targetHeight);
    UIGraphicsBeginImageContext(targetSize); // this will crop

    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;

    [sourceImage drawInRect:thumbnailRect];

    newImage = UIGraphicsGetImageFromCurrentImageContext();

    //pop the context to get back to the default
    UIGraphicsEndImageContext();

    return newImage;
}

+ (UIImage*) uuMakeStretchableImage:(NSString*)imageName insets:(UIEdgeInsets)insets
{
    return [[UIImage imageNamed:imageName] resizableImageWithCapInsets:insets];
}

@end