//
//  UUImageCache.m
//  Useful Utilities - An easy to use UIImage cache
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com
//

#import "UUImageCache.h"
#import "UUDataCache.h"
#import "UUDictionary.h"
#import "UURemoteData.h"

NSString * const kUUImageCacheMetaDataSizeKey = @"UUImageCacheMetaDataSize";
NSString * const kUUImageCacheMetaDataImageKey = @"UUImageCacheMetaDataImage";

@interface UUImageCache ()

@end

@implementation UUImageCache

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
        self.remoteFetchEnabled = YES;
    }
    
    return self;
}

- (NSValue*) imageSizeForPath:(NSString*)path
{
    NSValue* imageSize = nil;
    
    NSDictionary* metaData = [[UURemoteData sharedInstance] metaDataForPath:path];
    if (metaData)
    {
        imageSize = [metaData uuSafeGet:path forClass:[NSValue class]];
    }
    
    if (!imageSize)
    {
        // imageForPath will update the image size cache if needed
        UIImage* img = [self imageForPath:path remoteDownloadIfNeeded:NO];
        if (img)
        {
            imageSize = [NSValue valueWithCGSize:img.size];
        }
    }
    
    return imageSize;
}

- (UIImage*) cachedImageForPath:(NSString*)path
{
    UIImage* image = nil;
    
    NSDictionary* metaData = [[UURemoteData sharedInstance] metaDataForPath:path];
    if (metaData)
    {
        image = [metaData uuSafeGet:kUUImageCacheMetaDataImageKey forClass:[UIImage class]];
    }
    
    return image;
}

- (void) updateCache:(UIImage*)image forPath:(NSString*)path
{
    NSMutableDictionary* md = nil;
    
    NSDictionary* metaData = [[UURemoteData sharedInstance] metaDataForPath:path];
    if (metaData)
    {
        md = [NSMutableDictionary dictionaryWithDictionary:metaData];
    }
    else
    {
        md = [NSMutableDictionary dictionary];
    }
    
    NSValue* imageSize = [NSValue valueWithCGSize:image.size];
    [md setValue:imageSize forKey:kUUImageCacheMetaDataSizeKey];
    [md setValue:image forKey:kUUImageCacheMetaDataImageKey];
    [[UURemoteData sharedInstance] updateMetaData:md.copy forPath:path];
}

- (UIImage*) imageForPath:(NSString*)path
{
    return [self imageForPath:path remoteDownloadIfNeeded:self.remoteFetchEnabled];
}

- (UIImage*) imageForPath:(NSString*)path remoteDownloadIfNeeded:(BOOL)remoteDownloadIfNeeded
{
    if (!path || path.length <= 0)
    {
        return nil;
    }
    
    id obj = [self cachedImageForPath:path];
    if (obj)
    {
        return obj;
    }
    
    NSData* data = nil;
    
    if (remoteDownloadIfNeeded)
    {
        data = [[UURemoteData sharedInstance] dataForPath:path];
    }
    else
    {
        data = [[UUDataCache sharedCache] objectForKey:path];
    }
    
    if (data)
    {
        UIImage* img = [[UIImage alloc] initWithData:data];
        if (img)
        {
            [self updateCache:img forPath:path];
        }
        
        return img;
    }
    
    return nil;
}

@end
