//
//  UUHttpResponseHandler.h
//  Useful Utilities - HTTP response de-serialization protocol
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com
//

#import <UIKit/UIKit.h>

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Currently supported HTTP verbs
typedef enum
{
    UUHttpMethodGet,
    UUHttpMethodPut,
    UUHttpMethodPost,
    UUHttpMethodDelete,
    UUHttpMethodHead,
} UUHttpMethod;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Common HTTP response Codes
typedef enum
{
    UUHttpResponseCodeOK        = 200,
    UUHttpResponseCodeCreated   = 201,
    
} UUHttpResponseCode;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// HTTP String Constants

extern NSString * const kUUContentTypeApplicationJson;
extern NSString * const kUUContentTypeTextJson;
extern NSString * const kUUContentTypeTextHtml;
extern NSString * const kUUContentTypeTextPlain;
extern NSString * const kUUContentTypeBinary;
extern NSString * const kUUContentTypeImagePng;
extern NSString * const kUUContentTypeImageJpeg;

extern NSString * const kUUContentLengthHeader;
extern NSString * const kUUContentTypeHeader;
extern NSString * const kUUAcceptHeader;
extern NSString * const kUUHttpMethodGet;
extern NSString * const kUUHttpMethodPut;
extern NSString * const kUUHttpMethodPost;
extern NSString * const kUUHttpMethodDelete;
extern NSString * const kUUHttpMethodHead;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Register response handlers to construct objects from mime types
@protocol UUHttpResponseHandler <NSObject>
@required
- (NSArray*) supportedMimeTypes;
- (id) parseResponse:(NSData*)rxBuffer response:(NSHTTPURLResponse*)response forRequest:(NSURLRequest*)request;
@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Built-in response handlers
@interface UUTextResponseHandler : NSObject<UUHttpResponseHandler>
@end

@interface UUBinaryResponseHandler : NSObject<UUHttpResponseHandler>
@end

@interface UUJsonResponseHandler : NSObject<UUHttpResponseHandler>
@end

@interface UUImageResponseHandler : NSObject<UUHttpResponseHandler>
@end







