//
//  UURemoteImage.h
//  Useful Utilities - An extension to UURemoteData that provides an NSCache of UIImage objects
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//
//  UURemoteData provides a centralized place where application components can request
//  data that may come from a remote source.  It utilizes existing UUDataCache functionality
//  to locally store files for later fetching.  It will intelligently handle multiple requests for the
//  same image so that extraneous network requests are not needed.
//
//
//  NOTE: This class depends on the following toolbox classes:
//
//  UURemoteData
//  UUDictionary
//
//  NOTE NOTE:  This class is currently under development, so the interface and functionality
//              may be subject to change.
//

#import "UURemoteImage.h"
#import "UUDataCache.h"
#import "UUDictionary.h"

//If you want to provide your own logging mechanism, define UUDebugLog in your .pch
#ifndef UUDebugLog
#ifdef DEBUG
#define UUDebugLog(fmt, ...) NSLog(fmt, ##__VA_ARGS__)
#else
#define UUDebugLog(fmt, ...)
#endif
#endif

NSString * const kUUMetaDataImageSizeKey            = @"UUMetaDataImageSize";

@interface UURemoteImage ()

@property (nonatomic, strong) NSCache* imageCache;

@end

@implementation UURemoteImage

+ (instancetype) sharedInstance
{
    static id theSharedObject = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once (&onceToken, ^
    {
        theSharedObject = [[[self class] alloc] init];
    });
    
    return theSharedObject;
}

- (id) init
{
    self = [super init];
    
    if (self)
    {
        self.imageCache = [[NSCache alloc] init];
        self.imageCache.name = [NSString stringWithFormat:@"%@Cache", NSStringFromClass([self class])];
    }
    
    return self;
}

- (UIImage*) imageForPath:(NSString*)path
{
    return [self imageForPath:path skipDownload:NO];
}

- (UIImage*) imageForPath:(NSString*)path skipDownload:(BOOL)skipDownload
{
    if (!path || path.length <= 0)
    {
        return nil;
    }
    
    id obj = [self.imageCache objectForKey:path];
    if (obj)
    {
        //NSLog(@"Returning NSCache'd image for %@", path);
        return obj;
    }
    
    NSData* data = nil;
    
    if (skipDownload)
    {
        data = [[UUDataCache sharedCache] objectForKey:path];
    }
    else
    {
        data = [[UURemoteData sharedInstance] dataForPath:path];
    }
    
    if (data)
    {
        UIImage* img = [[UIImage alloc] initWithData:data];
        if (img)
        {
            [self.imageCache setObject:img forKey:path];
            
            NSMutableDictionary* metaData = [[self metaDataForPath:path] mutableCopy];
            if (!metaData)
            {
                metaData = [NSMutableDictionary dictionary];
            }
            
            [metaData setValue:[NSValue valueWithCGSize:img.size] forKey:kUUMetaDataImageSizeKey];
            [self updateMetaData:[metaData copy] forPath:path];
            //UUDebugLog(@"Image at path %@ has size %f, %f, byteSize: %@", path, img.size.width, img.size.height, @(data.length));
        }
        return img;
    }
    
    return nil;
}

- (NSValue*) imageSizeForPath:(NSString*)path
{
    NSDictionary* metaData = [self metaDataForPath:path];
    NSValue* val = [metaData uuSafeGet:kUUMetaDataImageSizeKey forClass:[NSValue class]];
    return val;
}

@end
