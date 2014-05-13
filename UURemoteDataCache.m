//
//  UURemoteDataCache.m
//  Useful Utilities - An extension to Useful Utilities UUDataCache that fetches
//  data from a remote source
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//


#import "UURemoteDataCache.h"
#import "UUHttpClient.h"
#import "UUDataCache.h"

NSString * const kUUDataDownloadedNotification      = @"UUDataDownloadedNotification";
NSString * const kUUDataRemotePathKey               = @"UUDataRemotePathKey";
NSString * const kUUDataKey                         = @"UUDataKey";

@interface UURemoteDataCache ()

@property (nonatomic, strong) NSMutableDictionary* pendingDownloads;
@end

@implementation UURemoteDataCache

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
        if (response.rawResponse)
        {
            [[UUDataCache sharedCache] setObject:response.rawResponse forKey:path];
            
            NSMutableDictionary* md = [NSMutableDictionary dictionary];
            [md setValue:response.rawResponse forKeyPath:kUUDataKey];
            [md setValue:path forKeyPath:kUUDataRemotePathKey];
            [[NSNotificationCenter defaultCenter] postNotificationName:kUUDataDownloadedNotification object:nil userInfo:md];
            [self.pendingDownloads removeObjectForKey:path];
        }
    }];
    
    [self.pendingDownloads setValue:client forKey:path];
    
    return nil;
}

@end
