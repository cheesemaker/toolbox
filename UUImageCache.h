//
//  UUImageCache.h
//  Useful Utilities - An easy to use UIImage cache
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com
//
//  UUImageCache is an extension of UURemoteData that saves a UIImage
//  and CGSize in the UURemoteData meta data cache.

@import UIKit;

@interface UUImageCache  : NSObject

+ (instancetype) sharedInstance;

// Controls whether UURemoteData will fetch the image from its remote location or
// just look locally in UUDataCache. Defaults to YES
@property (assign) BOOL remoteFetchEnabled;

- (NSValue*) imageSizeForPath:(NSString*)path;
- (UIImage*) imageForPath:(NSString*)path;

@end
