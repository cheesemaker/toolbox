//
//  UUHttpClient.h
//  Useful Utilities - Lightweight Objective C HTTP Client
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import <Foundation/Foundation.h>

@protocol UUHttpResponseHandler;
@protocol UUHttpProgressDelegate;

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
// Construct a UUHttpClientRequest to pass to UUHttpClient
@interface UUHttpClientRequest : NSObject

- (id) initWithUrl:(NSString*)url;

@property (atomic, strong) NSString*		url;
@property (atomic, assign) UUHttpMethod		httpMethod;
@property (atomic, strong) NSDictionary*	queryArguments;
@property (atomic, strong) NSDictionary*	headerFields;
@property (atomic, strong) NSData*			body;
@property (atomic, assign) NSTimeInterval	timeout;

// Static helper functions for the most common cases
+ (instancetype) getRequest:(NSString*)url queryArguments:(NSDictionary*)queryArguments;
+ (instancetype) putRequest:(NSString*)url queryArguments:(NSDictionary*)queryArguments body:(NSData*)body contentType:(NSString*)contentType;
+ (instancetype) postRequest:(NSString*)url queryArguments:(NSDictionary*)queryArguments body:(NSData*)body contentType:(NSString*)contentType;

@end



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// UUHttpClientResponse encapsulates the relevant info for an app to query after a UUHttpClientRequest has completed
@interface UUHttpClientResponse : NSObject

@property (atomic, strong) NSError*				httpError;
@property (atomic, strong) NSURLRequest*		httpRequest;
@property (atomic, strong) NSHTTPURLResponse*	httpResponse;
@property (atomic, strong) id					parsedResponse;
@property (atomic, strong) NSData*				rawResponse;
@property (atomic, strong) NSString*			rawResponsePath;

@end



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// UUHttpClient is responsible for taking UUHttpClientRequests and turning them into UUHttpClientResponses
@interface UUHttpClient : NSObject

- (id) initWithRequest:(UUHttpClientRequest*)request progressDelegate:(NSObject<UUHttpProgressDelegate>*)progressDelegate; //progressDelegate can be nil

// Verb interface
- (void) execute:(void (^)(UUHttpClientResponse* response))completionHandler;
- (void) cancel;

@property (atomic, assign) NSObject<UUHttpProgressDelegate>* progressDelegate;



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Static verb interface
+ (instancetype) get:(NSString*)url  queryStringArgs:(NSDictionary*)queryStringArgs completionHandler:(void (^)(UUHttpClientResponse* response))completionHandler;
+ (instancetype) put:(NSString*)url  queryStringArgs:(NSDictionary*)queryStringArgs putBody:(NSData*)putBody contentType:(NSString*)contentType completionHandler:(void (^)(UUHttpClientResponse* response))completionHandler;
+ (instancetype) post:(NSString*)url queryStringArgs:(NSDictionary*)queryStringArgs postBody:(NSData*)postBody contentType:(NSString*)contentType completionHandler:(void (^)(UUHttpClientResponse* response))completionHandler;
+ (instancetype) executeRequest:(UUHttpClientRequest*)request completionHandler:(void (^)(UUHttpClientResponse* response))completionHandler;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Synchronous interface. The returned response contains all relevant information about the transaction
+ (UUHttpClientResponse*) synchronousGet:(NSString*)url  queryStringArgs:(NSDictionary*)queryStringArgs;
+ (UUHttpClientResponse*) synchronousPut:(NSString*)url  queryStringArgs:(NSDictionary*)queryStringArgs putBody:(NSData*)putBody contentType:(NSString*)contentType;
+ (UUHttpClientResponse*) synchronousPost:(NSString*)url queryStringArgs:(NSDictionary*)queryStringArgs postBody:(NSData*)postBody contentType:(NSString*)contentType;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Static configuration interface
+ (void) registerResponseHandler:(NSObject<UUHttpResponseHandler>*)handler;
+ (void) setDefaultTimeout:(NSTimeInterval)timeout;
+ (void) cancelAllRequests;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Register response handlers to construct objects from mime types
@protocol UUHttpResponseHandler <NSObject>
@required
    - (NSArray*) supportedMimeTypes;
	- (id) parseResponse:(NSData*)rxBuffer response:(NSHTTPURLResponse*)response forRequest:(NSURLRequest*)request;
@end



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Delegate to update progress of downloads for things like progress bars, etc.
@protocol UUHttpProgressDelegate <NSObject>
@optional
	- (void) downloadResponseReceived:(UUHttpClient*)client expectedResponseSize:(NSInteger)expectedResponseSize;
	- (void) downloadProgress:(UUHttpClient*)client bytesReceived:(NSInteger)bytesReceived totalBytes:(NSInteger)totalBytes;
	- (void) downloadTerminated;
@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Error constants

typedef enum
{
    UUHttpClientErrorSuccess        = 0,
    UUHttpClientErrorUserCancelled  = 1,
    UUHttpClientErrorHttpError      = 2,
    UUHttpClientErrorHttpFailure    = 3,
    UUHttpClientErrorNoResponse     = 4,
    UUHttpClientErrorEmptyResponse  = 5,
    
} UUHttpClientError;

extern NSString * const kUUHttpClientErrorDomain;
extern NSString * const kUUHttpClientHttpErrorCodeKey;
extern NSString * const kUUHttpClientHttpErrorMessageKey;
extern NSString * const kUUHttpClientAppResponseKey;
