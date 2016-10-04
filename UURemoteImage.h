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

#import <UIKit/UIKit.h>
#import "UURemoteData.h"

extern NSString * const kUUMetaDataImageSizeKey;

@interface UURemoteImage : UURemoteData

// Loads an image first from the NSCache, then from UURemoteData
- (UIImage*) imageForPath:(NSString*)path;

// Loads an image first from an NSCache of UIImage's, then from UUDataCache,
// and optionally from its remote source.
- (UIImage*) imageForPath:(NSString*)path skipDownload:(BOOL)skipDownload;

// Returns the cached image size, or nil if the image is not present in the local cache
- (NSValue*) imageSizeForPath:(NSString*)path;

@end
