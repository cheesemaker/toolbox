//
//  UUHttpClientResponseHandlers.m
//  Useful Utilities - Commonly used Response Handlers for UUHttpClient
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

//If you want to provide your own logging mechanism, define UUDebugLog in your .pch
#ifndef UUDebugLog
#ifdef DEBUG
#define UUDebugLog(fmt, ...) NSLog(fmt, ##__VA_ARGS__)
#else
#define UUDebugLog(fmt, ...)
#endif
#endif

//If you want to impement your own UU_RELEASE and UU_AUTORELEASE mechanisms in your .pch, you may do so, just remember to define UU_MEMORY_MANAGEMENT
#ifndef UU_MEMORY_MANAGEMENT
#if !__has_feature(objc_arc)
#define UU_AUTORELEASE(x) [(x) autorelease]
#define UU_RELEASE(x)	  [(x) release]
#else
#define UU_AUTORELEASE(x) x
#define UU_RELEASE(x)     (void)(0)
#endif
#endif

NSString * const kUUContentTypeApplicationJson  = @"application/json";
NSString * const kUUContentTypeTextJson         = @"text/json";
NSString * const kUUContentTypeTextHtml         = @"text/html";
NSString * const kUUContentTypeBinary           = @"application/octet-stream";
NSString * const kUUContentTypeImagePng         = @"image/png";
NSString * const kUUContentTypeImageJpeg        = @"image/jpeg";

#import "UUHttpClientResponseHandlers.h"

#pragma mark - Text Response Handler
@implementation UUTextResponseHandler 

- (NSArray*) supportedMimeTypes
{
    return @[kUUContentTypeTextHtml];
}

- (id) parseResponse:(NSData*)rxBuffer response:(NSHTTPURLResponse*)response forRequest:(NSURLRequest*)request
{
    CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef) [response textEncodingName]);
    NSStringEncoding responseEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
    
    return UU_AUTORELEASE([[NSString alloc] initWithData:rxBuffer encoding:responseEncoding]);
}

@end

#pragma mark - Binary Response Handler
@implementation UUBinaryResponseHandler 

- (NSArray*) supportedMimeTypes
{
    return @[kUUContentTypeBinary];
}


- (id) parseResponse:(NSData*)rxBuffer response:(NSHTTPURLResponse*)response forRequest:(NSURLRequest*)request
{
    return rxBuffer;
}

@end

#pragma mark - JSON Response Handler

@implementation UUJsonResponseHandler

- (NSArray*) supportedMimeTypes
{
    return @[kUUContentTypeApplicationJson, kUUContentTypeTextJson];
}

- (id) parseResponse:(NSData*)rxBuffer response:(NSHTTPURLResponse*)response forRequest:(NSURLRequest*)request
{
    NSError* err = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:rxBuffer options:0 error:&err];
    if (err != nil)
    {
        UUDebugLog(@"Error derializing JSON: %@", err);
        return nil;
    }
    
    if (obj == nil)
    {
        UUDebugLog(@"JSON deserialization returned success but a nil object!");
    }
    
    return obj;
}

@end

#pragma mark - Image Response Handler

@implementation UUImageResponseHandler

- (NSArray*) supportedMimeTypes
{
    return @[kUUContentTypeImagePng, kUUContentTypeImageJpeg];
}

- (id) parseResponse:(NSData*)rxBuffer response:(NSHTTPURLResponse*)response forRequest:(NSURLRequest*)request
{
    return [UIImage imageWithData:rxBuffer];
}

@end

