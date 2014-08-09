//
//  UURemoteData.m
//  Useful Utilities - An extension to Useful Utilities UUDataCache that fetches
//  data from a remote source
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//

#import "UURemoteData.h"
#import "UUHttpClient.h"
#import "UUDataCache.h"

//If you want to provide your own logging mechanism, define UUDebugLog in your .pch
#ifndef UUDebugLog
#ifdef DEBUG
#define UUDebugLog(fmt, ...) NSLog(fmt, ##__VA_ARGS__)
#else
#define UUDebugLog(fmt, ...)
#endif
#endif

NSString * const kUUDataDownloadedNotification      = @"UUDataDownloadedNotification";
NSString * const kUUDataDownloadFailedNotification  = @"UUDataDownloadFailedNotification";
NSString * const kUUDataRemotePathKey               = @"UUDataRemotePathKey";
NSString * const kUUDataKey                         = @"UUDataKey";
NSString * const kUUErrorKey                        = @"UUErrorKey";

@interface UURemoteData ()

@property (nonatomic, strong) NSMutableDictionary* pendingDownloads;
@end

@implementation UURemoteData

+ (instancetype) sharedInstance
{
	static id theSharedObject = nil;
	static dispatch_once_t onceToken;
    
    dispatch_once (&onceToken, ^
    {
        theSharedObject = [[[self class] alloc] init];
    });
	
	return theSharedObject;
}

- (id) init
{
    self = [super init];
    
    if (self)
    {
        self.pendingDownloads = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (NSData*) dataForPath:(NSString*)path
{
    if (!path || path.length <= 0)
    {
        return nil;
    }
    
    NSData* data = [[UUDataCache sharedCache] objectForKey:path];
    if (data)
    {
        return data;
    }
    
    UUHttpClient* pendingDownload = [self.pendingDownloads valueForKey:path];
    if (pendingDownload)
    {
        // An active UUHttpClient means a request is currently fetching the resource, so
        // no need to re-fetch
        UUDebugLog(@"Download pending for %@", path);
        return nil;
    }
    
    UUHttpClientRequest* request = [UUHttpClientRequest getRequest:path queryArguments:nil];
	request.processMimeTypes = NO;
    UUHttpClient* client = [UUHttpClient executeRequest:request completionHandler:^(UUHttpClientResponse *response)
    {
        [self handleDownloadResponse:response forPath:path];
    }];
    
    [self.pendingDownloads setValue:client forKey:path];
    
    return nil;
}

- (void) handleDownloadResponse:(UUHttpClientResponse*)response forPath:(NSString*)path
{
    NSMutableDictionary* md = [NSMutableDictionary dictionary];
    [md setValue:path forKeyPath:kUUDataRemotePathKey];
    
    if (response.rawResponse)
    {
        [[UUDataCache sharedCache] setObject:response.rawResponse forKey:path];
        
        [md setValue:response.rawResponse forKeyPath:kUUDataKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:kUUDataDownloadedNotification object:nil userInfo:md];
    }
    else
    {
        UUDebugLog(@"Image Download Failed!\n\nPath: %@\nStatusCode: %d\nError: %@\n", path, response.httpResponse.statusCode, response.httpError);
        
        [md setValue:response.httpError forKeyPath:kUUErrorKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:kUUDataDownloadFailedNotification object:nil userInfo:md];
    }
    
    [self.pendingDownloads removeObjectForKey:path];
}

- (void) fetchMultiple:(NSArray*)remotePaths completion:(void(^)(NSDictionary* results))completion
{
    __block int processedCount = 0;
    __block int totalToProcess = remotePaths.count;
    __block NSMutableDictionary* md = [NSMutableDictionary dictionary];
    
    void (^block)(NSString* remotePath, UUHttpClientResponse* response) = ^(NSString* remotePath, UUHttpClientResponse* response)
    {
        ++processedCount;
        
        if (response.httpError)
        {
            [md setValue:response.httpError forKey:remotePath];
        }
        
        UUDebugLog(@"Processed %d of %d", processedCount, totalToProcess);
        
        if (processedCount >= totalToProcess)
        {
            if (completion)
            {
                completion(md);
            }
        }
    };
    
    for (NSString* path in remotePaths)
    {
        UUHttpClientRequest* request = [UUHttpClientRequest getRequest:path queryArguments:nil];
        request.processMimeTypes = NO;
        UUHttpClient* client = [UUHttpClient executeRequest:request completionHandler:^(UUHttpClientResponse *response)
        {
            [self handleDownloadResponse:response forPath:path];
            block(path, response);
        }];
        
        [self.pendingDownloads setValue:client forKey:path];
    }
}

@end
