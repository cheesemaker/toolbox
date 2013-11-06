//
//  UUImageView.m
//  Useful Utilities - UIImageView extensions
//  (c) 2013, Jonathan Hays. All Rights Reserved.
//
//	Smile License:
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

typedef void (^UURemoteImageRequestCompletionHandler)(UIImage* imageView);

@implementation UIImageView (UURemoteLoading)

// The remote request queue is the mapping from url to completion block dictionary
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

// The remote requester list is an array of dictionaries in order to get the pending request url for a given image view
+ (NSMutableArray*) uuRemoteRequesterList
{
	static NSMutableArray* theRequestList = nil;
	static dispatch_once_t onceToken;

    dispatch_once (&onceToken, ^
	{
		theRequestList = [[NSMutableArray alloc] init];
    });
	
	return theRequestList;
}


+ (void) uuRemoteImageLoadCompleted:(NSURL*)url withImage:(UIImage*)image
{
	NSMutableDictionary* dictionary = [self uuRemoteRequestQueue];
	NSMutableArray* completionBlockArray = [dictionary objectForKey:[url absoluteString]];
	if (completionBlockArray)
	{
		for (NSDictionary* requestDictionary in completionBlockArray)
		{
			UURemoteImageRequestCompletionHandler completionBlock = [requestDictionary objectForKey:@"UURemoteRequestCompletionBlock"];
			completionBlock(image);
		}
	}
	
	[completionBlockArray removeAllObjects];
	[dictionary removeObjectForKey:[url absoluteString]];
}

+ (BOOL) uuAddRemoteImageLoadCompletionBlock:(NSURL*)url imageView:(UIImageView*)imageView block:(UURemoteImageRequestCompletionHandler)block
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
	
	[self uuAddRemoteRequestor:imageView for:url];
	
	NSDictionary* requestDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:imageView,			@"UURemoteRequestImageView",
																				   Block_copy(block),	@"UURemoteRequestCompletionBlock",
																				   nil];
	[array addObject:requestDictionary];
	
	return isLoadExisting;
}

+ (void) uuAddRemoteRequestor:(UIImageView*)imageView for:(NSURL*)url
{
	[self uuCancelExistingRemoteLoadRequestFor:imageView];
	NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:imageView, @"UURemoteRequestImageView",
																		  url,		 @"UURemoteRequestURL",
																		  nil];
	NSMutableArray* array = [self uuRemoteRequesterList];
	[array addObject:dictionary];
}

+ (void) uuRemoveCompletionBlockFor:(UIImageView*)imageView with:(NSURL*)url
{
	NSMutableDictionary* requestQueueDictionary = [self uuRemoteRequestQueue];
	NSMutableArray* requestList = [requestQueueDictionary objectForKey:url];
	for (NSDictionary* requestDictionary in requestList)
	{
		UIImageView* requestor = [requestDictionary objectForKey:@"UURemoteRequestImageView"];
		if (requestor == imageView)
		{
			[requestList removeObject:requestDictionary];
			return;
		}
	}
}

+ (void) uuCancelExistingRemoteLoadRequestFor:(UIImageView*)requestor
{
	NSMutableArray* array = [self uuRemoteRequesterList];
	for (NSDictionary* dictionary in array)
	{
		UIImageView* imageView = [dictionary objectForKey:@"UURemoteRequestImageView"];
		if (imageView == requestor)
		{
			NSURL* url = [dictionary objectForKey:@"UURemoteRequestURL"];
			[self uuRemoveCompletionBlockFor:imageView with:url];
			return;
		}
	}
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
		[UIImageView uuCancelExistingRemoteLoadRequestFor:self];
        [self finishLoadFromUrl:defaultImage loadCompleteHandler:loadCompleteHandler];
    }
    else
    {
        UIImage* image = [self uuImageFromCache:url];
        if (image)
        {
			[UIImageView uuCancelExistingRemoteLoadRequestFor:self];
            [self finishLoadFromUrl:image loadCompleteHandler:loadCompleteHandler];
        }
        else
        {
            self.image = defaultImage;
            
			BOOL alreadyRequested = [UIImageView uuAddRemoteImageLoadCompletionBlock:url imageView:self block:^(UIImage* image)
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
	//We will let this go async from the URL loading
	if ([[NSThread currentThread] isMainThread])
		self.image = image;
	else
		[self performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
	
    if (loadCompleteHandler)
    {
        loadCompleteHandler(self);
    }
}

@end
