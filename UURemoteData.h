//
//  UURemoteData.h
//  Useful Utilities - An extension to Useful Utilities UUDataCache that fetches
//  data from a remote source
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
//  UUHttpClient
//  UUDataCache
//
//
//  NOTE NOTE:  This class is currently under development, so the interface and functionality
//              may be subject to change.
//

#import <Foundation/Foundation.h>

// Notification userInfo has two values:
//
// kUUDataRemotePathKey - NSString of the remote path
// kUUDataKey - UIImage
// kUUErrorKey - NSError (may be nil)
//
extern NSString * const kUUDataDownloadedNotification;
extern NSString * const kUUDataDownloadFailedNotification;
extern NSString * const kUUDataRemotePathKey;
extern NSString * const kUUDataKey;
extern NSString * const kUUErrorKey;

// Meta Data keys
extern NSString * const kUUMetaDataMimeTypeKey;
extern NSString * const kUUMetaDataDownloadTimestampKey;

@interface UURemoteData : NSObject

+ (instancetype) sharedInstance;

// Attempts to fetch remote data.  If the data exists locally in UUDataCache, it will return
// immediately.  If nil is returned, there is no local copy of the resource, and it indicates
// a remote request has either been started or is already in progress.
- (NSData*) dataForPath:(NSString*)path;

// Returns true if there is an active or queue'd download request for the remote resource
- (BOOL) hasPendingDownloadForPath:(NSString*)path;

// UURemoteData maintains an NSCache of NSDictionary's per remote object.
// UURemoteData will store the MIME type and download time of the object.
- (NSDictionary*) metaDataForPath:(NSString*)path;
- (void) updateMetaData:(NSDictionary*)metaData forPath:(NSString*)path;

// Fetches multiple remote data objects and calls the completion block only when all
// have completed.  The completion block is an NSDictionary of NSString->NSError objects. If
// empty it means all completed successfully.
- (void) fetchMultiple:(NSArray*)remotePaths completion:(void(^)(NSDictionary* results))completion;

@end
