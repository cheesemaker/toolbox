//
//  UUDropbox.h
//  Photos+
//
//  Created by Jonathan Hays on 2/3/14.
//  Copyright (c) 2014 Second Gear. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DBMetadata;

extern NSString *const kUUDropBoxDestFileKey;
extern NSString *const kUUDropBoxDownloadProgressKey;
extern NSString *const kUUDropBoxFileDownloadProgressNotification;
extern NSString *const kUUDropBoxFileDownloadFinishedNotification;

@interface UUDropBox : NSObject

//Account setup
- (void)			initialize:(NSString*)appKey withSecret:(NSString*)appSecret;
- (NSString*)		userName;
- (long long)		bytesUsed;
- (long long)		bytesAvailable;
- (BOOL)			isLinked;
- (void)			link:(UIViewController*)parent completion:(void (^)(BOOL authorized))completionHandler;
- (void)			unlink;

//Load the full, raw DBMetadata for a folder
- (void) loadMetaDataForFolder:(NSString*)path
		completionHandler:(void (^)(BOOL success, DBMetadata* subfolders))completionHandler;

//Given a path, enumerate the folders - NOT recursive
- (void) enumerateFolders:(NSString*)path
		completionHandler:(void (^)(BOOL success, NSArray* subfolders))completionHandler;

//Given a path, enumerate the images - NOT recursive
- (void) enumerateImagesInFolder:(NSString*)path
			   completionHandler:(void (^)(BOOL success, NSArray* imagePaths))completionHandler;


//The destination path needs to exist, and the variable passed in needs to include the file name
- (void) loadThumbnail:(NSString*)dropBoxPath
					to:(NSString*)destinationPathAndFileName
			completion:(void (^)(BOOL success, NSString* destinationPath, NSDate* lastModified))completionHandler;


//The destination path needs to exist, and the variable passed in needs to include the file name
- (void)	loadFile:(NSString*)dropBoxPath
				  to:(NSString*)destination
		  completion:(void (^)(BOOL success, NSString* destinationPath, NSDate* lastModified))completionHandler;


//URL Callback support. Make sure to call appropriately for your AppDelegate
- (BOOL) handleURL:(NSURL*)url;

- (NSDate*) dateOfRemoteFile:(NSString*)dropBoxPath;

- (void) cancelAllRequests;

+ (UUDropBox*) sharedInstance;

@end
