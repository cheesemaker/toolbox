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

@implementation UIImageView (UURemoteLoading)

- (void) uuLoadImageFromURL:(NSURL*)url
               defaultImage:(UIImage*)defaultImage
        loadCompleteHandler:(void (^)(UIImageView* imageView))loadCompleteHandler
{
    UIImage* image = [UUDataCache imageForURL:url];
	if (image)
	{
        [self finishLoadFromUrl:image loadCompleteHandler:loadCompleteHandler];
	}
    else
    {
        self.image = defaultImage;
        
        [UUHttpClient get:url.absoluteString queryArguments:nil completionHandler:^(UUHttpClientResponse *response)
         {
             UIImage* image = defaultImage;
             
             if (response.parsedResponse && [response.parsedResponse isKindOfClass:[UIImage class]])
             {
                 image = (UIImage*)response.parsedResponse;
                 [UUDataCache cacheImage:image forURL:url];
             }
             
             [self finishLoadFromUrl:image loadCompleteHandler:loadCompleteHandler];
         }];
    }
}

- (void) finishLoadFromUrl:(UIImage*)image loadCompleteHandler:(void (^)(UIImageView* imageView))loadCompleteHandler
{
    self.image = image;
    
    if (loadCompleteHandler)
    {
        loadCompleteHandler(self);
    }
}

@end
