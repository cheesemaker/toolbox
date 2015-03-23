//
//  UUDataCache.m
//  Useful Utilities - UUDataCache for commonly fetched data from URL's
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import "UUDataCache.h"

//If you want to provide your own logging mechanism, define UUDebugLog in your .pch
#ifndef UUDebugLog
	#ifdef DEBUG
		#define UUDebugLog(fmt, ...) NSLog(fmt, ##__VA_ARGS__)
	#else
		#define UUDebugLog(fmt, ...)
	#endif
#endif

@implementation UUDataCache

NSTimeInterval uuDataCacheExpirationLength = (60 * 60 * 24 * 30); //30 days

+ (void) uuSetCacheExpirationLength:(NSTimeInterval)seconds
{
	uuDataCacheExpirationLength = seconds;
}

+ (NSString*) uuCacheLocation
{
	NSString* cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
	cachePath = [cachePath stringByAppendingPathComponent:@"UUDataCache"];
	NSFileManager* fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:cachePath])
		[fm createDirectoryAtPath:cachePath withIntermediateDirectories:TRUE attributes:nil error:nil];

	return cachePath;
}

+ (void) uuClearCacheContents
{
	NSString* cacheLocation = [UUDataCache uuCacheLocation];
	NSFileManager* fm = [NSFileManager defaultManager];
	[fm removeItemAtPath:cacheLocation error:nil];
	[fm createDirectoryAtPath:cacheLocation withIntermediateDirectories:YES attributes:nil error:nil];
}

+ (bool) uuIsCacheExpiredForUrl:(NSString*)path
{
	if (path)
	{
		NSDate* cachedDate = [[NSUserDefaults standardUserDefaults] objectForKey:path];
		if (cachedDate)
		{
			NSTimeInterval elapsed = -[cachedDate timeIntervalSinceNow];
			return (elapsed > uuDataCacheExpirationLength);
		}
	}
	
	return false;
}

+ (NSData*) uuBundleDataForUrl:(NSURL*)url
{
    if (url != nil)
	{
		NSString* fileName = [url absoluteString];
		NSArray* parts = [fileName componentsSeparatedByString:@"/"];
		if (parts.count)
			fileName = [parts objectAtIndex:[parts count] - 1];
			
		fileName = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
		if (fileName)
		{
			return [NSData dataWithContentsOfFile:fileName];
		}
    }
    
    return nil;
}

+ (void) uuClearCacheForURL:(NSURL*)url
{
    NSString* path = [UUDataCache uuCachePathForURL:url];
    NSFileManager* fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:path])
    {
        NSError* err = nil;
        if (![fm removeItemAtPath:path error:&err])
        {
            UUDebugLog(@"Failed to delete data at cache path: %@", path);
        }
    }
	
	//Zero out the last date...
	[[NSUserDefaults standardUserDefaults] setObject:nil forKey:path];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void) uuPurgeContentAboveSize:(unsigned long long)purgeFileSize
{
    NSString* cacheLocation = [self uuCacheLocation];
	NSFileManager* fm = [NSFileManager defaultManager];
    
    NSError* err = nil;
    NSArray* contents = [fm contentsOfDirectoryAtPath:cacheLocation error:&err];
    if (!err && contents)
    {
        for (NSString* item in contents)
        {
            NSString* path = [cacheLocation stringByAppendingPathComponent:item];
            
            err = nil;
            NSDictionary* attrs = [fm attributesOfItemAtPath:path error:&err];
            if (!err && attrs)
            {
                NSNumber* fileSize = [attrs valueForKey:NSFileSize];
                if (fileSize)
                {
                    if (fileSize.unsignedLongLongValue > purgeFileSize)
                    {
                        [self uuClearCacheForURL:[NSURL URLWithString:item]];
                    }
                }
            }
        }
    }
}

+ (void) uuPurgeExpiredContent
{
    NSString* cacheLocation = [self uuCacheLocation];
	NSFileManager* fm = [NSFileManager defaultManager];
    
    NSError* err = nil;
    NSArray* contents = [fm contentsOfDirectoryAtPath:cacheLocation error:&err];
    if (!err && contents)
    {
        for (NSString* item in contents)
        {
            NSURL* url = [NSURL URLWithString:item];
            if ([self uuIsCacheExpiredForUrl:[self uuCachePathForURL:url]])
            {
                [self uuClearCacheForURL:url];
            }
        }
    }
}

+ (NSData*) uuDataForURL:(NSURL*)url
{
	NSData* data = nil;
	
    if (url != nil)
    {
		//First check to see if the data is in the bundle...
		data = [UUDataCache uuBundleDataForUrl:url];
		
		//If not, let's check our cache...
		if (!data)
		{
			NSString* path = [UUDataCache uuCachePathForURL:url];
			
			//Make sure the cache isn't expired...
			if (![UUDataCache uuIsCacheExpiredForUrl:path])
			{
				data = [NSData dataWithContentsOfFile:path];
			}
			else
			{
				[UUDataCache uuClearCacheForURL:url];
			}
		}
    }

	return data;
}
	
+ (void) uuCacheData:(NSData*)data forURL:(NSURL*)url
{
	//Write out the data
	NSString* path = [UUDataCache uuCachePathForURL:url];
	[data writeToFile:path atomically:YES];

	//Store the date
	NSDate* now = [NSDate date];
	[[NSUserDefaults standardUserDefaults] setObject:now forKey:path];
    [[NSUserDefaults standardUserDefaults] synchronize];

}

+ (NSString*) uuCachePathForURL:(NSURL*)url
{
	NSString* cacheLocation = [UUDataCache uuCacheLocation];
	
	NSString* path = [url absoluteString];
	path = [[path componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:@"-"];
	path = [cacheLocation stringByAppendingPathComponent:path];
	return path;
}

+ (BOOL) uuDoesCachedFileExistForURL:(NSURL*)url
{
    NSString* cacheLocation = [UUDataCache uuCachePathForURL:url];
    return [[NSFileManager defaultManager] fileExistsAtPath:cacheLocation];
}

+ (UUDataCache*) sharedCache
{
	static UUDataCache* theSharedCache = nil;
	if (!theSharedCache)
	{
		theSharedCache = [[UUDataCache alloc] init];
	}
	
	return theSharedCache;
}

- (id) objectForKey:(id)key
{
	return [UUDataCache uuDataForURL:[NSURL URLWithString:key]];
}

- (void) setObject:(id)object forKey:(id)key
{
	[UUDataCache uuCacheData:object forURL:[NSURL URLWithString:key]];
}


@end