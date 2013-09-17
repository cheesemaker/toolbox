//
//  UUHttpClient.h
//  Useful Utilities - Lightweight Objective C HTTP Client
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com
//
//
// UUHttpClient is a transactional http wrapper ideal for interfacing with JSON based web services. The system is designed around the concept
// that for the majority of web transactions you want an actual object back from your URL request.  Whether that is a JSON Dictionary, a UIImage
// or just a text blob, UUHttpClient minimizes the amount of code you have to write.
//
// Usage Example 1:
//
//    [UUHttpClient get:@"http://www.myserver.com/somejpeg.jpg" queryStringArgs:nil completionHandler:^(UUHttpClientResponse* response) {
//         if (!response.httpError) {
//			    UIImage* image = response.parsedResponse;
//		        //Do something with the image now!
//         }
//    }];
//
//
// Usage Example 2:
//
//	UUHttpClientRequest* request = [UUHttpClientRequest getRequest:@"http://www.myserver.com/somepng.png" queryArguments:nil];
//	request.timeout = 1.0;
//
//	UUHttpClient* httpClient = [[UUHttpClient alloc] initWithRequest:request progressDelegate:self];
//
//	[httpClient execute:^(UUHttpClientResponse* response) {
//	    if (!response.httpError) {
//			UIImage* image = response.parsedResponse;
//		}
//	}];
//
//
// Usage Example 3:
//
//	UUHttpClientResponse* response = [UUHttpClient synchronouseGet:@"http://www.myserver.com/somejpeg.jpg" queryStringArgs:nil];
//	UIImage* image = response.parsedResponse;
//

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
@property (atomic, assign) BOOL				processMimeTypes;

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

- (UUHttpClientResponse*) synchronousExecute;

@property (atomic, assign) NSObject<UUHttpProgressDelegate>* progressDelegate;



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Static verb interface
+ (instancetype) get:(NSString*)url  queryArguments:(NSDictionary*)queryArguments completionHandler:(void (^)(UUHttpClientResponse* response))completionHandler;
+ (instancetype) put:(NSString*)url  queryArguments:(NSDictionary*)queryArguments putBody:(NSData*)putBody contentType:(NSString*)contentType completionHandler:(void (^)(UUHttpClientResponse* response))completionHandler;
+ (instancetype) post:(NSString*)url queryArguments:(NSDictionary*)queryArguments postBody:(NSData*)postBody contentType:(NSString*)contentType completionHandler:(void (^)(UUHttpClientResponse* response))completionHandler;
+ (instancetype) executeRequest:(UUHttpClientRequest*)request completionHandler:(void (^)(UUHttpClientResponse* response))completionHandler;

+ (instancetype) getImage:(NSString*)url queryArguments:(NSDictionary*)queryArguments scale:(float)imageScale completionHandler:(void (^)(NSError* error, UIImage* image))completionHandler;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Synchronous interface. The returned response contains all relevant information about the transaction
+ (UUHttpClientResponse*) synchronousGet:(NSString*)url  queryArguments:(NSDictionary*)queryArguments;
+ (UUHttpClientResponse*) synchronousPut:(NSString*)url  queryArguments:(NSDictionary*)queryArguments putBody:(NSData*)putBody contentType:(NSString*)contentType;
+ (UUHttpClientResponse*) synchronousPost:(NSString*)url queryArguments:(NSDictionary*)queryArguments postBody:(NSData*)postBody contentType:(NSString*)contentType;

+ (UUHttpClientResponse*) synchronousGetImage:(NSString*)url queryArguments:(NSDictionary*)queryArguments scale:(float)imageScale;

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

extern NSString * const kUUContentTypeApplicationJson;
extern NSString * const kUUContentTypeTextJson;
extern NSString * const kUUContentTypeTextHtml;
extern NSString * const kUUContentTypeBinary;
extern NSString * const kUUContentTypeImagePng;
extern NSString * const kUUContentTypeImageJpeg;
