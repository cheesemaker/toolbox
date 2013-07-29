//
//  UUImageView.h
//  Useful Utilities - UIImageView extensions
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import <Foundation/Foundation.h>

@interface UIImageView (UURemoteLoading)

- (void) uuLoadImageFromURL:(NSURL*)url
               defaultImage:(UIImage*)defaultImage
        loadCompleteHandler:(void (^)(UIImageView* imageView))loadCompleteHandler;

@end
