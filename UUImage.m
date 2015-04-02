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
#import <ImageIO/ImageIO.h>
#import <Accelerate/Accelerate.h>
#import <float.h>

/////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIImage+UUFramework
/////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation UIImage (UUFramework)

- (UIImage*) uuRemoveOrientation
{
	//If it's already oriented correctly, just do it...
    if (self.imageOrientation == UIImageOrientationUp)
		return self;
	
    CGAffineTransform transform = CGAffineTransformIdentity;

    switch (self.imageOrientation)
	{
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;

        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;

        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }

    switch (self.imageOrientation)
	{
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;

        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }

	CGImageRef cgImageRef = self.CGImage;
    CGContextRef contextRef = CGBitmapContextCreate(NULL, self.size.width, self.size.height, CGImageGetBitsPerComponent(cgImageRef), 0, CGImageGetColorSpace(cgImageRef), CGImageGetBitmapInfo(cgImageRef));
    CGContextConcatCTM(contextRef, transform);
    switch (self.imageOrientation)
	{
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(contextRef, CGRectMake(0,0,self.size.height,self.size.width), cgImageRef);
            break;

        default:
            CGContextDrawImage(contextRef, CGRectMake(0,0,self.size.width,self.size.height), cgImageRef);
            break;
    }

    cgImageRef = CGBitmapContextCreateImage(contextRef);
    UIImage* image = [UIImage imageWithCGImage:cgImageRef];
    CGContextRelease(contextRef);
    CGImageRelease(cgImageRef);
    return image;
}

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
    
    CGSize destSize = [self uuCalculateScaleToWidthDestSize:width];
    
    // this is actually the interesting part:
    UIGraphicsBeginImageContext(destSize);
    
    CGRect destRect = CGRectZero;
    destRect.size = destSize;
    
    [self drawInRect:destRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if(newImage == nil)
    {
        newImage = self;
    }
    
    return newImage;
}

- (UIImage*) uuScaleToHeight:(CGFloat)height
{
    UIImage *newImage = nil;
    
    CGSize destSize = [self uuCalculateScaleToHeightDestSize:height];
    
    // this is actually the interesting part:
    UIGraphicsBeginImageContext(destSize);
    
    CGRect destRect = CGRectZero;
    destRect.size = destSize;
    
    [self drawInRect:destRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if(newImage == nil)
    {
        newImage = self;
    }
    
    return newImage;
}

- (UIImage*) uuScaleSmallestDimensionToSize:(CGFloat)size
{
    if (self.size.width < self.size.height)
    {
        return [self uuScaleToWidth:size];
    }
    else
    {
        return [self uuScaleToHeight:size];
    }
}

- (CGSize) uuCalculateScaleToWidthDestSize:(CGFloat)width
{
    return [[self class] uuCalculateScaleToWidthDestSize:width fromSize:self.size];
}

- (CGSize) uuCalculateScaleToHeightDestSize:(CGFloat)height
{
    return [[self class] uuCalculateScaleToHeightDestSize:height fromSize:self.size];
}

+ (CGSize) uuCalculateScaleToWidthDestSize:(CGFloat)width fromSize:(CGSize)srcSize
{
    CGFloat srcWidth = srcSize.width;
    CGFloat srcHeight = srcSize.height;
    CGFloat srcAspectRatio = srcHeight / srcWidth;
    
    CGFloat targetWidth = width * ([[UIScreen mainScreen] scale]);
    CGFloat targetHeight = targetWidth * srcAspectRatio;
    
    CGSize destSize = CGSizeMake(targetWidth, targetHeight);
    return destSize;
}

+ (CGSize) uuCalculateScaleToHeightDestSize:(CGFloat)height fromSize:(CGSize)srcSize
{
    CGFloat srcWidth = srcSize.width;
    CGFloat srcHeight = srcSize.height;
    CGFloat srcAspectRatio = srcWidth / srcHeight;
    
    CGFloat targetHeight = height * ([[UIScreen mainScreen] scale]);
    CGFloat targetWidth = targetHeight * srcAspectRatio;
    
    CGSize destSize = CGSizeMake(targetWidth, targetHeight);
    return destSize;
}

- (CGSize) uuCalculateScaleToFitDestSize:(CGFloat)size
{
    if (self.size.width < self.size.height)
    {
        return [self uuCalculateScaleToWidthDestSize:size];
    }
    else
    {
        return [self uuCalculateScaleToHeightDestSize:size];
    }
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

+ (UIImage*) uuViewToImage:(UIView*)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    
    [view.layer renderInContext:outputContext];
    
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage*) uuSolidColorImage:(UIColor*)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage*) uuSolidColorImage:(UIColor*)color cornerRadius:(CGFloat)cornerRadius borderColor:(UIColor*)borderColor borderWidth:(CGFloat)borderWidth
{
    CGRect rect = CGRectMake(0, 0, (cornerRadius * 2) + 1, (cornerRadius * 2) + 1);
    rect = CGRectMake(0, 0, rect.size.width * 2, rect.size.height * 2);
    
    UIView* view = [[UIView alloc] initWithFrame:rect];
    view.backgroundColor = color;
    view.layer.borderColor = [borderColor CGColor];
    view.layer.cornerRadius = cornerRadius;
    view.layer.masksToBounds = YES;
    view.layer.borderWidth = borderWidth;
    UIImage* image = [self uuViewToImage:view];
    
    CGFloat r = cornerRadius;
    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(r, r, r, r)];
    return image;
}

+ (UIImage*) uuSolidColorImage:(UIColor*)color
                  cornerRadius:(CGFloat)cornerRadius
                   borderColor:(UIColor*)borderColor
                   borderWidth:(CGFloat)borderWidth
                roundedCorners:(UIRectCorner)roundedCorners
{
    CGRect rect = CGRectMake(0, 0, (cornerRadius * 2) + 1, (cornerRadius * 2) + 1);
    rect = CGRectMake(0, 0, rect.size.width * 2, rect.size.height * 2);
    
    UIView* view = [[UIView alloc] initWithFrame:rect];
    view.backgroundColor = color;
    
    UIBezierPath* maskPath = [UIBezierPath bezierPathWithRoundedRect:rect
                                                   byRoundingCorners:roundedCorners
                                                         cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
    
    CAShapeLayer* maskLayer = [CAShapeLayer layer];
    maskLayer.frame = rect;
    maskLayer.path = maskPath.CGPath;
    
    view.layer.mask = maskLayer;
    
    CAShapeLayer* shapeLayer = [CAShapeLayer layer];
    shapeLayer.frame = rect;
    shapeLayer.path = maskPath.CGPath;
    shapeLayer.fillColor = [color CGColor];
    shapeLayer.strokeColor = [borderColor CGColor];
    shapeLayer.lineWidth = borderWidth;
    
    [view.layer addSublayer:shapeLayer];
    
    UIImage* image = [self uuViewToImage:view];
    
    CGFloat r = cornerRadius;
    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(r, r, r, r)];
    return image;
}

- (UIImage*) uuBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage *)maskImage
{
    if (self.size.width < 1 || self.size.height < 1)
	{
        //invalid size: Both dimensions must be >= 1
        return nil;
    }
	
    if (!self.CGImage)
	{
        //image must be backed by a CGImage;
        return nil;
    }
	
    if (maskImage && !maskImage.CGImage)
	{
        //maskImage must be backed by a CGImage
        return nil;
    }
    
    CGRect imageRect = { CGPointZero, self.size };
    UIImage *effectImage = self;
    
    BOOL hasBlur = blurRadius > __FLT_EPSILON__;
    BOOL hasSaturationChange = fabs(saturationDeltaFactor - 1.) > __FLT_EPSILON__;
    if (hasBlur || hasSaturationChange)
	{
        UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectInContext = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(effectInContext, 1.0, -1.0);
        CGContextTranslateCTM(effectInContext, 0, -self.size.height);
        CGContextDrawImage(effectInContext, imageRect, self.CGImage);
        
        vImage_Buffer effectInBuffer;
        effectInBuffer.data     = CGBitmapContextGetData(effectInContext);
        effectInBuffer.width    = CGBitmapContextGetWidth(effectInContext);
        effectInBuffer.height   = CGBitmapContextGetHeight(effectInContext);
        effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);
        
        UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectOutContext = UIGraphicsGetCurrentContext();
        vImage_Buffer effectOutBuffer;
        effectOutBuffer.data     = CGBitmapContextGetData(effectOutContext);
        effectOutBuffer.width    = CGBitmapContextGetWidth(effectOutContext);
        effectOutBuffer.height   = CGBitmapContextGetHeight(effectOutContext);
        effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);
        
        if (hasBlur)
		{
            // A description of how to compute the box kernel width from the Gaussian
            // radius (aka standard deviation) appears in the SVG spec:
            // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
            //
            // For larger values of 's' (s >= 2.0), an approximation can be used: Three
            // successive box-blurs build a piece-wise quadratic convolution kernel, which
            // approximates the Gaussian kernel to within roughly 3%.
            //
            // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
            //
            // ... if d is odd, use three box-blurs of size 'd', centered on the output pixel.
            //
            CGFloat inputRadius = blurRadius * [[UIScreen mainScreen] scale];
            NSUInteger radius = floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5);
            if (radius % 2 != 1)
			{
                radius += 1; // force radius to be odd so that the three box-blur methodology works.
            }
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, (uint32_t)radius, (uint32_t)radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, (uint32_t)radius, (uint32_t)radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, (uint32_t)radius, (uint32_t)radius, 0, kvImageEdgeExtend);
        }
        BOOL effectImageBuffersAreSwapped = NO;
        if (hasSaturationChange)
		{
            CGFloat s = saturationDeltaFactor;
            CGFloat floatingPointSaturationMatrix[] = {
                0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                0,                    0,                    0,  1,
            };
            const int32_t divisor = 256;
            NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix)/sizeof(floatingPointSaturationMatrix[0]);
            int16_t saturationMatrix[matrixSize];
            for (NSUInteger i = 0; i < matrixSize; ++i)
			{
                saturationMatrix[i] = (int16_t)roundf(floatingPointSaturationMatrix[i] * divisor);
            }
            if (hasBlur)
			{
                vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
                effectImageBuffersAreSwapped = YES;
            }
            else
			{
                vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
            }
        }
        if (!effectImageBuffersAreSwapped)
		{
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
		}
		
        UIGraphicsEndImageContext();
        
        if (effectImageBuffersAreSwapped)
		{
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        }
		UIGraphicsEndImageContext();
    }
    
    // Set up output context.
    UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -self.size.height);
    
    // Draw base image.
    CGContextDrawImage(outputContext, imageRect, self.CGImage);
    
    // Draw effect image.
    if (hasBlur)
	{
        CGContextSaveGState(outputContext);
        if (maskImage)
		{
            CGContextClipToMask(outputContext, imageRect, maskImage.CGImage);
        }
        CGContextDrawImage(outputContext, imageRect, effectImage.CGImage);
        CGContextRestoreGState(outputContext);
    }
    
    // Add in color tint.
    if (tintColor)
	{
        CGContextSaveGState(outputContext);
        CGContextSetFillColorWithColor(outputContext, tintColor.CGColor);
        CGContextFillRect(outputContext, imageRect);
        CGContextRestoreGState(outputContext);
    }
    
    // Output image is ready.
    UIImage* outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return outputImage;
}

@end

@implementation UIImage (UUAnimatedGIF)

#if __has_feature(objc_arc)
    #define UU_BRIDGE(x) (__bridge x)
#else
    #define UU_BRIDGE(x) (x)
#endif

+ (NSArray*) uuGIFCreateFrames:(CGImageSourceRef)source count:(int)count
{
    NSMutableArray* array = [NSMutableArray array];
    for (int i = 0; i < count; i++)
    {
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, i, nil);
        UIImage* image = [UIImage imageWithCGImage:imageRef];
        [array addObject:image];
        CGImageRelease(imageRef);
    }
    
    return array;
}

+ (NSTimeInterval) uuGIFDuration:(CGImageSourceRef)source frameCount:(int)frameCount
{
    NSTimeInterval duration = 0.0;
    
    for (int i = 0; i < frameCount; i++)
    {
        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(source, i, NULL);
        NSDictionary* dictionary = UU_BRIDGE(NSDictionary*)properties;
        NSDictionary* gifProperties = [dictionary objectForKey:UU_BRIDGE(NSString*)kCGImagePropertyGIFDictionary];
        NSNumber* number = [gifProperties objectForKey:UU_BRIDGE(NSString*)kCGImagePropertyGIFDelayTime];
        CFRelease(properties);
                
        duration += number.doubleValue;
    }
    
    return duration;
}

+ (UIImage*) uuImageWithGIFData:(NSData*)data
{
    CGImageSourceRef imageRef = CGImageSourceCreateWithData(UU_BRIDGE(CFDataRef)data, NULL);
    int frameCount = (int)CGImageSourceGetCount(imageRef);
    NSTimeInterval duration = [UIImage uuGIFDuration:imageRef frameCount:frameCount];
    NSArray* frames = [UIImage uuGIFCreateFrames:imageRef count:frameCount];
    UIImage* image = [UIImage animatedImageWithImages:frames duration:duration];
    CFRelease(imageRef);
    
    return image;
}

@end