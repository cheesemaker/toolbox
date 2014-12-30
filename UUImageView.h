//
//  UUImageView.h
//  Useful Utilities - UIImageView extensions
//
//  (c) 2013, Jonathan Hays. All Rights Reserved.
//
//	Smile License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import <UIKit/UIKit.h>

@protocol UUImageCache
@required
	- (id)objectForKey:(id)key;
	- (void) setObject:(id)object forKey:(id)key;
@end

@interface UIImageView (UURemoteLoading)

- (void) uuLoadImageFromURL:(NSURL*)url defaultImage:(UIImage*)defaultImage loadCompleteHandler:(void (^)(UIImageView* imageView))loadCompleteHandler;

+ (void) uuSetImageCache:(NSObject*)cache;

@end
