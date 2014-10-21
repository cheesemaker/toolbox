//
//  UUHttpResponseParser.m
//  UUToolboxTestBed
//
//  Created by Ryan DeVore on 9/18/14.
//  Copyright (c) 2014 Ryan DeVore. All rights reserved.
//

#import "UUHttpResponseHandler.h"

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
NSString * const kUUContentTypeTextPlain        = @"text/plain";
NSString * const kUUContentTypeBinary           = @"application/octet-stream";
NSString * const kUUContentTypeImagePng         = @"image/png";
NSString * const kUUContentTypeImageJpeg        = @"image/jpeg";

NSString * const kUUContentLengthHeader  = @"Content-Length";
NSString * const kUUContentTypeHeader    = @"Content-Type";
NSString * const kUUAcceptHeader         = @"Accept";
NSString * const kUUHttpMethodGet        = @"GET";
NSString * const kUUHttpMethodPut        = @"PUT";
NSString * const kUUHttpMethodPost       = @"POST";
NSString * const kUUHttpMethodDelete     = @"DELETE";
NSString * const kUUHttpMethodHead       = @"HEAD";


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark- Response Handlers
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Text Response Handler
@implementation UUTextResponseHandler

- (NSArray*) supportedMimeTypes
{
    return @[kUUContentTypeTextHtml, kUUContentTypeTextPlain];
}

- (id) parseResponse:(NSData*)rxBuffer response:(NSHTTPURLResponse*)response forRequest:(NSURLRequest*)request
{
    NSStringEncoding responseEncoding = NSUTF8StringEncoding;
    
    if ([response textEncodingName])
    {
        CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef) [response textEncodingName]);
        responseEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
    }
    
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
