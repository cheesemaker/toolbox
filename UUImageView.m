//
//  UUImageView.m
//  Useful Utilities - UIImageView extensions
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import "UUImageView.h"
#import "UUHttpClient.h"
#import "UUDataCache.h"

#if __has_feature(objc_arc)
	#define UU_RELEASE(x) (void)(0)
	#define UU_RETAIN(x)  (void)(0)
#else
	#define UU_RELEASE(x) [x release]
	#define UU_RETAIN(x) [x retain]
#endif


@implementation UIImageView (UURemoteLoading)

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

typedef void (^UURemoteImageRequestCompletionHandler)(UIImage* imageView);

+ (NSMutableDictionary*) uuRemoteRequestQueue
{
	static NSMutableDictionary* theRequestQueue = nil;
	static dispatch_once_t onceToken;

    dispatch_once (&onceToken, ^
	{
		theRequestQueue = [[NSMutableDictionary alloc] init];
    });
	
	return theRequestQueue;
}

+ (void) uuRemoteImageLoadCompleted:(NSURL*)url withImage:(UIImage*)image
{
	NSMutableDictionary* dictionary = [self uuRemoteRequestQueue];
	NSMutableArray* completionBlockArray = [dictionary objectForKey:[url absoluteString]];
	if (completionBlockArray)
	{
		for (UURemoteImageRequestCompletionHandler completionBlock in completionBlockArray)
		{
			completionBlock(image);
		}
	}
	
	[completionBlockArray removeAllObjects];
	[dictionary removeObjectForKey:[url absoluteString]];
}

+ (BOOL) uuAddRemoteImageLoadCompletionBlock:(NSURL*)url block:(UURemoteImageRequestCompletionHandler)block
{
	BOOL isLoadExisting = YES;
	NSMutableDictionary* dictionary = [self uuRemoteRequestQueue];
	NSMutableArray* array = [dictionary objectForKey:[url absoluteString]];
	if (!array)
	{
		array = [NSMutableArray array];
		[dictionary setObject:array forKey:[url absoluteString]];
		isLoadExisting = NO;
	}
	
	[array addObject:Block_copy(block)];
	
	return isLoadExisting;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

NSObject<UUImageCache>* theImageCache = nil;

+ (NSObject<UUImageCache>*) uuImageCache
{
	static dispatch_once_t onceToken;

    dispatch_once (&onceToken, ^
	{
		theImageCache = (NSObject<UUImageCache>*)[UUDataCache sharedCache];
		UU_RETAIN(theImageCache);
    });
	
	return theImageCache;
}

+ (void) uuSetImageCache:(NSObject*)cache
{
	if (theImageCache)
		UU_RELEASE(theImageCache);
	theImageCache = (NSObject<UUImageCache>*)cache;
	UU_RETAIN(theImageCache);
}

- (UIImage*) uuImageFromBundle:(NSURL*)url
{
	if (url)
	{
		NSString* fileName = [url absoluteString];
		NSArray* parts = [fileName componentsSeparatedByString:@"/"];
		if (parts.count)
			fileName = [parts objectAtIndex:[parts count] - 1];
        
        return [UIImage imageNamed:fileName];
	}
	
	return nil;
}

- (UIImage*) uuImageFromCache:(NSURL*)url
{
	NSObject<UUImageCache>* imageCache = [UIImageView uuImageCache];
	
	//First look the image up in the bundle
	UIImage* image = [self uuImageFromBundle:url];

	//If it's not in the bundle, look in the cache
	if (!image && [imageCache respondsToSelector:@selector(objectForKey:)])
	{
		NSData* data = [imageCache objectForKey:[url absoluteString]];
		return [UIImage imageWithData:data];
	}
	
	return image;
}

- (void) uuCacheImage:(UIImage*)image forURL:(NSURL*)url
{
	NSObject<UUImageCache>* imageCache = [UIImageView uuImageCache];
	if ([imageCache respondsToSelector:@selector(setObject:forKey:)])
	{
		NSData* data = UIImagePNGRepresentation(image);
		[imageCache setObject:data forKey:[url absoluteString]];
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark-
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) uuLoadImageFromURL:(NSURL*)url defaultImage:(UIImage*)defaultImage loadCompleteHandler:(void (^)(UIImageView* imageView))loadCompleteHandler
{
    if (!url  || url.absoluteString.length <= 0)
    {
        [self finishLoadFromUrl:defaultImage loadCompleteHandler:loadCompleteHandler];
    }
    else
    {
        UIImage* image = [self uuImageFromCache:url];
        if (image)
        {
            [self finishLoadFromUrl:image loadCompleteHandler:loadCompleteHandler];
        }
        else
        {
            self.image = defaultImage;
            
			BOOL alreadyRequested = [UIImageView uuAddRemoteImageLoadCompletionBlock:url block:^(UIImage* image)
			{
                 [self finishLoadFromUrl:image loadCompleteHandler:loadCompleteHandler];
			}];
			
			if (!alreadyRequested)
			{
				[UUHttpClient get:url.absoluteString queryArguments:nil completionHandler:^(UUHttpClientResponse *response)
				{
					UIImage* image = defaultImage;
                 
					if (response.parsedResponse && [response.parsedResponse isKindOfClass:[UIImage class]])
					{
						image = (UIImage*)response.parsedResponse;
						[self uuCacheImage:image forURL:url];
					}
                 
					[UIImageView uuRemoteImageLoadCompleted:url withImage:image];
				}];
			}
		}
    }
}

- (void) finishLoadFromUrl:(UIImage*)image loadCompleteHandler:(void (^)(UIImageView* imageView))loadCompleteHandler
{
	[self performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
    
    if (loadCompleteHandler)
    {
        loadCompleteHandler(self);
    }
}

@end
