//
//  UUHttpClientResponseHandlers.h
//  Useful Utilities - Commonly used Response Handlers for UUHttpClient
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com


#import <Foundation/Foundation.h>
#import "UUHttpClient.h"

extern NSString * const kUUContentTypeApplicationJson;
extern NSString * const kUUContentTypeTextJson;
extern NSString * const kUUContentTypeTextHtml;
extern NSString * const kUUContentTypeBinary;
extern NSString * const kUUContentTypeImagePng;
extern NSString * const kUUContentTypeImageJpeg;

@interface UUTextResponseHandler : NSObject<UUHttpResponseHandler>

@end

@interface UUBinaryResponseHandler : NSObject<UUHttpResponseHandler>

@end

@interface UUJsonResponseHandler : NSObject<UUHttpResponseHandler>

@end

@interface UUImageResponseHandler : NSObject<UUHttpResponseHandler>

@end
