//
//  UUDropbox.m
//
//  Created by Jonathan Hays on 2/3/14.
//  Copyright (c) 2014 Jonathan Hays. All rights reserved.
//

#import "UUDropbox.h"
#import <DropboxSDK/DropboxSDK.h>

NSString *const kUUDropBoxDestFileKey = @"UUDropBoxDestFileKey";
NSString *const kUUDropBoxDownloadProgressKey = @"UUDropBoxProgressKey";
NSString *const kUUDropBoxFileDownloadProgressNotification = @"UUFileDownloadProgressNotification";
NSString *const kUUDropBoxFileDownloadFinishedNotification = @"UUFileDownloadFinishedNotification";


@interface UUDropBox() <DBSessionDelegate, DBNetworkRequestDelegate, DBRestClientDelegate>
	@property (atomic, strong)		DBSession* session;
	@property (atomic, strong)		DBRestClient* restClient;

	@property (nonatomic, copy) void (^authorizationCompletionHandler)(BOOL authorized);
	@property (nonatomic, copy) void (^enumerateImagesCompletionHandler)(BOOL success, NSArray* imageURLs);
	@property (nonatomic, copy) void (^enumerateFoldersCompletionHandler)(BOOL success, NSArray* imageURLs);
	@property (nonatomic, copy) void (^enumerateMetaDataCompletionHandler)(BOOL success, DBMetadata* metaData);
	@property (nonatomic, strong) NSString* folderEnumerationPath;
	@property (nonatomic, strong) NSString* photoEnumerationPath;
	@property (nonatomic, strong) NSString* metaDataEnumerationPath;

	@property (nonatomic, strong) NSMutableDictionary* photoLoadCompletionHandlers;
	@property (nonatomic, strong) NSMutableDictionary* photoUploadCompletionHandlers;

	@property (nonatomic, strong) DBMetadata* cachedMetaData;
	@property (nonatomic, strong) DBAccountInfo* accountInfo;

	@property (nonatomic, strong) NSString* appKey;
	@property (nonatomic, strong) NSString* appSecret;
@end

@implementation UUDropBox

+ (UUDropBox*) sharedInstance
{
	static dispatch_once_t onceToken;
	static UUDropBox* dropBox = nil;

    dispatch_once (&onceToken, ^
	{
		dropBox = [[UUDropBox alloc] init];
    });

	return dropBox;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
//////////////////////////////////////////////////////////////////////////////////////////////////////

- (id) init
{
	self = [super init];
	if (self)
	{
		self.photoLoadCompletionHandlers = [NSMutableDictionary dictionary];
		self.photoUploadCompletionHandlers = [NSMutableDictionary dictionary];
	}
	
	return self;
}

- (void) initialize:(NSString*)appKey withSecret:(NSString*)appSecret
{
	self.appKey = appKey;
	self.appSecret = appSecret;

	[self configureAccount];
}

- (void) cancelAllRequests
{
	if (self.restClient)
		[self.restClient cancelAllRequests];
}

- (NSString*) userName
{
	if (self.accountInfo)
		return self.accountInfo.displayName;
		
	return @"Not signed in";
}

- (long long) bytesUsed
{
	if (self.accountInfo)
		return self.accountInfo.quota.totalConsumedBytes;
		
	return 0;
}

- (long long) bytesAvailable
{
	if (self.accountInfo)
		return self.accountInfo.quota.totalBytes;
		
	return 0;
}

- (void) configureAccount
{
	NSAssert(self.appKey != nil, @"You need to call initialize with valid key and secret values first!");
	NSAssert(self.appSecret != nil, @"You need to call initialize with valid key and secret values first!");

	// Set these variables before launching the app
    NSString* appKey = self.appKey;
	NSString* appSecret = self.appSecret;
	
	NSString *root = kDBRootDropbox; // Should be set to either kDBRootAppFolder or kDBRootDropbox
	
	self.session = [[DBSession alloc] initWithAppKey:appKey appSecret:appSecret root:root];
	self.session.delegate = self; // DBSessionDelegate methods allow you to handle re-authenticating
	[DBSession setSharedSession:self.session];
	
	[DBRequest setNetworkRequestDelegate:self];
	
	if ([[DBSession sharedSession] isLinked])
	{
		self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        self.restClient.delegate = self;
		[self.restClient loadAccountInfo];
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Linking Interface
//////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL) isLinked
{
	BOOL linked = [[DBSession sharedSession] isLinked];
	return linked;
}

- (void) link:(UIViewController*)parent completion:(void (^)(BOOL authorized))completionHandler
{
	NSAssert(self.appKey != nil, @"You need to call initialize with valid key and secret values first!");
	NSAssert(self.appSecret != nil, @"You need to call initialize with valid key and secret values first!");

	self.authorizationCompletionHandler = completionHandler;
    if (![[DBSession sharedSession] isLinked])
		[[DBSession sharedSession] linkFromController:parent];
}

- (void) unlink
{
	NSAssert(self.appKey != nil, @"You need to call initialize with valid key and secret values first!");
	NSAssert(self.appSecret != nil, @"You need to call initialize with valid key and secret values first!");

	if ([[DBSession sharedSession] isLinked])
	{
		[[DBSession sharedSession] unlinkAll];
		self.accountInfo = nil;
	}
}

- (BOOL) handleURL:(NSURL *)url
{
	NSAssert(self.appKey != nil, @"You need to call initialize with valid key and secret values first!");
	NSAssert(self.appSecret != nil, @"You need to call initialize with valid key and secret values first!");

	if ([[DBSession sharedSession] handleOpenURL:url])
	{
		BOOL isAuthorized = [[DBSession sharedSession] isLinked];

		if (isAuthorized)
		{
			self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
			self.restClient.delegate = self;
			[self.restClient loadAccountInfo];
		}
		else if (self.authorizationCompletionHandler)
		{
			self.authorizationCompletionHandler(isAuthorized);
		}
		return YES;
	}

	return NO;
}

- (void)restClient:(DBRestClient*)client loadedAccountInfo:(DBAccountInfo*)info
{
	self.accountInfo = info;
	if (self.authorizationCompletionHandler)
		self.authorizationCompletionHandler(YES);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - File uploading
//////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath metadata:(DBMetadata*)metadata
{
	void (^uploadImageCompletionHandler)(BOOL success, NSString* destination) = [self.photoUploadCompletionHandlers objectForKey:destPath];
	if (uploadImageCompletionHandler)
		uploadImageCompletionHandler(YES, destPath);
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress forFile:(NSString*)destPath from:(NSString*)srcPath
{
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error
{
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Thumbnail downloading
//////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) loadThumbnail:(NSString *)dropBoxPath to:(NSString*)destination completion:(void (^)(BOOL success, NSString* destinationPath, NSDate* lastModified))completionHandler
{
	NSAssert(self.appKey != nil, @"You need to call initialize with valid key and secret values first!");
	NSAssert(self.appSecret != nil, @"You need to call initialize with valid key and secret values first!");

	NSDate* fileModifiedDate = [self dateOfRemoteFile:dropBoxPath];
	NSDictionary* completionInfo = [NSDictionary dictionaryWithObjectsAndKeys:completionHandler, @"completionHandler",
																			  fileModifiedDate, @"modifiedDate", nil];
	[self.photoLoadCompletionHandlers setObject:completionInfo forKey:destination];
	[self.restClient loadThumbnail:dropBoxPath ofSize:@"200x200" intoPath:destination];
	//@"iphone_bestfit"
	//@"iphone_thumbnail_native"
	//@"m"
}

- (void)restClient:(DBRestClient*)client loadedThumbnail:(NSString*)destPath
{
	NSDictionary* completionInfo = [self.photoLoadCompletionHandlers objectForKey:destPath];
	void (^loadImageCompletionHandler)(BOOL success, NSString* destination, NSDate* lastModified) = [completionInfo objectForKey:@"completionHandler"];
	NSDate* fileModifiedDate = [completionInfo objectForKey:@"modifiedDate"];
	if (loadImageCompletionHandler)
		loadImageCompletionHandler(YES, destPath, fileModifiedDate);
}

- (void)restClient:(DBRestClient*)client loadThumbnailFailedWithError:(NSError*)error
{
	NSDictionary* userInfo = error.userInfo;
	if (userInfo)
	{
		NSString* serverPath = [userInfo objectForKey:@"path"];
		NSString* localPath = [userInfo objectForKey:@"destinationPath"];
		if (serverPath && localPath && error.code != 404)
		{
			NSDictionary* completionInfo = [self.photoLoadCompletionHandlers objectForKey:localPath];
			void (^loadImageCompletionHandler)(BOOL success, NSString* destination, NSDate* lastModified) = [completionInfo objectForKey:@"completionHandler"];
			[self loadThumbnail:serverPath to:localPath completion:loadImageCompletionHandler];
		}
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - File downloading
//////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) loadFile:(NSString*)dropBoxPath to:(NSString*)destination completion:(void (^)(BOOL success, NSString* destinationPath, NSDate* modifiedDate))completionHandler
{
	NSAssert(self.appKey != nil, @"You need to call initialize with valid key and secret values first!");
	NSAssert(self.appSecret != nil, @"You need to call initialize with valid key and secret values first!");

	[self.photoLoadCompletionHandlers setObject:completionHandler forKey:destination];
	[self.restClient loadFile:dropBoxPath intoPath:destination];
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath contentType:(NSString*)contentType metadata:(DBMetadata*)metadata
{
	NSDate* modifiedDate = metadata.lastModifiedDate;
	void (^loadImageCompletionHandler)(BOOL success, NSString* destination, NSDate* lastModified) = [self.photoLoadCompletionHandlers objectForKey:destPath];
	if (loadImageCompletionHandler)
		loadImageCompletionHandler(YES, destPath, modifiedDate);
	
	NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:destPath,	kUUDropBoxDestFileKey,
																		  @(1.0),	kUUDropBoxDownloadProgressKey,
																		  nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kUUDropBoxFileDownloadFinishedNotification object:dictionary];
}

- (void)restClient:(DBRestClient*)client loadProgress:(CGFloat)progress forFile:(NSString*)destPath
{
	NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:destPath,		kUUDropBoxDestFileKey,
																		  @(progress),	kUUDropBoxDownloadProgressKey,
																		  nil];

	[[NSNotificationCenter defaultCenter] postNotificationName:kUUDropBoxFileDownloadProgressNotification object:dictionary];
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error
{
	NSDictionary* userInfo = error.userInfo;
	if (userInfo)
	{
		NSString* serverPath = [userInfo objectForKey:@"path"];
		NSString* localPath = [userInfo objectForKey:@"destinationPath"];
		if (serverPath && localPath)
		{
			void (^loadImageCompletionHandler)(BOOL success, NSString* destination, NSDate* lastModified) = [self.photoLoadCompletionHandlers objectForKey:localPath];
			[self loadFile:serverPath to:localPath completion:loadImageCompletionHandler];
		}
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - DBSessionDelegate
//////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session userId:(NSString *)userId
{
	BOOL isAuthorized = [[DBSession sharedSession] isLinked];
	if (self.authorizationCompletionHandler)
		self.authorizationCompletionHandler(isAuthorized);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Metadata for a folder
//////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) loadMetaDataForFolder:(NSString*)path completionHandler:(void (^)(BOOL success, DBMetadata* subfolders))completionHandler
{
	NSAssert(self.appKey != nil, @"You need to call initialize with valid key and secret values first!");
	NSAssert(self.appSecret != nil, @"You need to call initialize with valid key and secret values first!");
	
	self.enumerateMetaDataCompletionHandler = completionHandler;
	self.metaDataEnumerationPath = path;
	
	NSString* hash = nil;
	if (self.cachedMetaData)
		hash = self.cachedMetaData.hash;
	
	[self.restClient loadMetadata:path withHash:hash];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Enumerate folders
//////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) enumerateFolders:(NSString*)path completionHandler:(void (^)(BOOL success, NSArray* subfolders))completionHandler
{
	NSAssert(self.appKey != nil, @"You need to call initialize with valid key and secret values first!");
	NSAssert(self.appSecret != nil, @"You need to call initialize with valid key and secret values first!");

	self.enumerateFoldersCompletionHandler = completionHandler;
	self.folderEnumerationPath = path;
	
	NSString* hash = nil;
	if (self.cachedMetaData)
		hash = self.cachedMetaData.hash;
	
	[self.restClient loadMetadata:path withHash:hash];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Enumerate images
//////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) enumerateImagesInFolder:(NSString*)path completionHandler:(void (^)(BOOL success, NSArray* imagePaths))completionHandler
{
	NSAssert(self.appKey != nil, @"You need to call initialize with valid key and secret values first!");
	NSAssert(self.appSecret != nil, @"You need to call initialize with valid key and secret values first!");

	self.enumerateImagesCompletionHandler = completionHandler;
	self.photoEnumerationPath = path;
	
    NSString* photosRoot = nil;
	photosRoot = path;//[SLDropBox remoteFolderPath];
	
	NSString* hash = nil;
	if (self.cachedMetaData)
		hash = self.cachedMetaData.hash;
		
    [self.restClient loadMetadata:photosRoot withHash:hash];
}

- (NSMutableArray*)createdSubpathArrayFromMetaData:(DBMetadata*)metadata
{
	NSMutableArray* subpathArray = [NSMutableArray array];
	for (DBMetadata* child in metadata.contents)
	{
		if (child.isDirectory)
		{
			[subpathArray addObject:child.path];
		}
	}
	
	return subpathArray;
}

- (NSMutableArray*) createdPhotoContentsArrayFromMetaData:(DBMetadata*)metadata
{
    NSArray* validExtensions = [NSArray arrayWithObjects:@"jpg", @"jpeg", @"png", nil];
	NSMutableArray* subpathArray = [NSMutableArray array];
	for (DBMetadata* child in metadata.contents)
	{
		if (child.thumbnailExists && !child.isDirectory)
		{
			NSString* extension = [[child.path pathExtension] lowercaseString];
			if ([validExtensions indexOfObject:extension] != NSNotFound)
			{
				[subpathArray addObject:child];
			}
		}
	}
	
	return subpathArray;
}

- (void) processMetaData:(DBMetadata*)metadata
{
	self.cachedMetaData = metadata;

	//Check to see if this is a request for folder enumeration
	if (self.enumerateFoldersCompletionHandler && [self.folderEnumerationPath isEqualToString:metadata.path])
	{
		NSArray* contents = [self createdSubpathArrayFromMetaData:metadata];
		self.enumerateFoldersCompletionHandler(YES, contents);
	}

	if (self.enumerateImagesCompletionHandler && [self.photoEnumerationPath isEqualToString:metadata.path])
	{
		NSArray* contents = [self createdPhotoContentsArrayFromMetaData:metadata];	
		self.enumerateImagesCompletionHandler(YES, contents);
	}
	
	if (self.enumerateMetaDataCompletionHandler && [self.metaDataEnumerationPath isEqualToString:metadata.path])
	{
		self.enumerateMetaDataCompletionHandler(YES, metadata);
	}
}

- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
	[self processMetaData:metadata];
}

- (void)restClient:(DBRestClient*)client metadataUnchangedAtPath:(NSString*)path
{
	[self processMetaData:self.cachedMetaData];
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error
{
	if (self.cachedMetaData)
	{
		[self processMetaData:self.cachedMetaData];
	}
	else
	{
		if (self.enumerateImagesCompletionHandler)
			self.enumerateImagesCompletionHandler(NO, nil);
			
		if (self.enumerateFoldersCompletionHandler)
			self.enumerateFoldersCompletionHandler(NO, nil);
			
		if (self.enumerateMetaDataCompletionHandler)
			self.enumerateMetaDataCompletionHandler(NO, nil);
	}
}

- (NSDate*) dateOfRemoteFile:(NSString*)dropBoxPath
{
	for (DBMetadata* child in self.cachedMetaData.contents)
	{
		if ([child.path isEqualToString:dropBoxPath])
			return child.clientMtime;
	}
	
	return nil;
}


//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Network request notifications
//////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)networkRequestStarted
{
}

- (void)networkRequestStopped
{
}


@end
