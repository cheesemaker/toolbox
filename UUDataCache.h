//
//  UUDataCache.h
//  Useful Utilities - UUDataCache for commonly fetched data from URL's
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import <Foundation/Foundation.h>

@interface UUDataCache : NSObject

	+ (NSData*) uuDataForURL:(NSURL*)url;
	+ (void)	uuCacheData:(NSData*)data forURL:(NSURL*)url;
    + (void)	uuClearCacheForURL:(NSURL*)url;
	+ (void)	uuSetCacheExpirationLength:(NSTimeInterval)seconds;
	+ (void)	uuClearCacheContents;

	+ (UUDataCache*) sharedCache;

	// If you want to use UUDataCache as an NSCache or NSMutableDictionary replacement
	- (id) objectForKey:(id)key;
	- (void) setObject:(id)object forKey:(id)key;


@end
