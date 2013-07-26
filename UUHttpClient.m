//
//  UUHttpClient.m
//  Useful Utilities - Lightweight Objective C HTTP Client
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

#import "UUHttpClient.h"

NSString * const kUUContentTypeApplicationJson  = @"application/json";
NSString * const kUUContentTypeTextJson         = @"text/json";
NSString * const kUUContentTypeTextHtml         = @"text/html";
NSString * const kUUContentTypeBinary           = @"application/octet-stream";
NSString * const kUUContentTypeImagePng         = @"image/png";
NSString * const kUUContentTypeImageJpeg        = @"image/jpeg";

NSString * const kUUHttpClientErrorDomain           = @"kUUHttpClientErrorDomain";
NSString * const kUUHttpClientHttpErrorCodeKey      = @"kUUHttpClientHttpErrorCodeKey";
NSString * const kUUHttpClientHttpErrorMessageKey   = @"kUUHttpClientHttpErrorMessageKey";
NSString * const kUUHttpClientAppResponseKey        = @"kUUHttpClientAppResponseKey";

NSString * const kUUContentLengthHeader  = @"Content-Length";
NSString * const kUUContentTypeHeader    = @"Content-Type";
NSString * const kUUAcceptHeader         = @"Accept";
NSString * const kUUHttpMethodGet        = @"GET";
NSString * const kUUHttpMethodPut        = @"PUT";
NSString * const kUUHttpMethodPost       = @"POST";
NSString * const kUUHttpMethodDelete     = @"DELETE";
NSString * const kUUHttpMethodHead       = @"HEAD";

const NSTimeInterval kUUDefaultHttpTimeout  = 60.0f;

static NSMutableArray* theSharedRequestQueue;
static NSMutableDictionary* theResponseHandlers;
static NSTimeInterval theDefaultHttpTimeout = kUUDefaultHttpTimeout;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Declare the built-in response handlers
@interface UUTextResponseHandler : NSObject<UUHttpResponseHandler>
@end

@interface UUBinaryResponseHandler : NSObject<UUHttpResponseHandler>
@end

@interface UUJsonResponseHandler : NSObject<UUHttpResponseHandler>
@end

@interface UUImageResponseHandler : NSObject<UUHttpResponseHandler>
@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation UUHttpClientRequest

- (id) initWithUrl:(NSString*)url
{
    self = [super init];
    
    if (self)
    {
        self.url = url;
        self.httpMethod = UUHttpMethodGet;
        self.timeout = theDefaultHttpTimeout;
    }
    
    return self;
}

+ (instancetype) getRequest:(NSString*)url queryArguments:(NSDictionary*)queryArguments
{
    UUHttpClientRequest* cr = UU_AUTORELEASE([[UUHttpClientRequest alloc] initWithUrl:url]);
    cr.httpMethod = UUHttpMethodGet;
    cr.queryArguments = queryArguments;
    return cr;
}

+ (instancetype) putRequest:(NSString*)url queryArguments:(NSDictionary*)queryArguments body:(NSData*)body contentType:(NSString*)contentType
{
    UUHttpClientRequest* cr = UU_AUTORELEASE([[UUHttpClientRequest alloc] initWithUrl:url]);
    cr.httpMethod = UUHttpMethodPut;
    cr.queryArguments = queryArguments;
    cr.body = body;
    
    if (contentType)
    {
        cr.headerFields = @{kUUContentTypeHeader:contentType};
    }
    
    return cr;
}

+ (instancetype) postRequest:(NSString*)url queryArguments:(NSDictionary*)queryArguments body:(NSData*)body contentType:(NSString*)contentType
{
    UUHttpClientRequest* cr = UU_AUTORELEASE([[UUHttpClientRequest alloc] initWithUrl:url]);
    cr.httpMethod = UUHttpMethodPost;
    cr.queryArguments = queryArguments;
    cr.body = body;
    
    if (contentType)
    {
        cr.headerFields = @{kUUContentTypeHeader:contentType};
    }
    
    return cr;
}

@end

@implementation UUHttpClientResponse
	//Nothing to see here.  Move along...
@end

@interface UUHttpClient ()

@property (nonatomic, strong) UUHttpClientRequest* clientRequest;
@property (nonatomic, strong) NSURLConnection* connection;
@property (nonatomic, strong) NSMutableData* rxBuffer;
@property (nonatomic, strong) NSURLRequest* request;
@property (nonatomic, strong) NSHTTPURLResponse* response;
@property (nonatomic, strong) NSError* error;
@property (assign) NSUInteger expectedResponseLength;
@property (assign) NSUInteger totalBytesReceived;
@property (atomic, assign) bool isActive;
@property (nonatomic, copy) void (^blocksCompletionHandler)(UUHttpClientResponse* response);

@end



@implementation UUHttpClient

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public class Methods
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (void) installDefaultResponseHandlers
{
    [UUHttpClient registerResponseHandler:[UUJsonResponseHandler new]];
    [UUHttpClient registerResponseHandler:[UUTextResponseHandler new]];
    [UUHttpClient registerResponseHandler:[UUBinaryResponseHandler new]];
    [UUHttpClient registerResponseHandler:[UUImageResponseHandler new]];
}

+ (void) registerResponseHandler:(NSObject<UUHttpResponseHandler>*)handler
{
    for (NSString* mimeType in [handler supportedMimeTypes])
    {
        [[self sharedResponseHandlers] setObject:handler forKey:mimeType];
    }
}

+ (void) setDefaultTimeout:(NSTimeInterval)timeout
{
	theDefaultHttpTimeout = timeout;
}

+ (instancetype) get:(NSString*)url queryArguments:(NSDictionary*)queryArguments completionHandler:(void (^)(UUHttpClientResponse* response))completionHandler
{
    UUHttpClientRequest* request = [UUHttpClientRequest getRequest:url queryArguments:queryArguments];
    return [self executeRequest:request completionHandler:completionHandler];
}

+ (instancetype) put:(NSString*)url queryArguments:(NSDictionary*)queryArguments putBody:(NSData*)putBody contentType:(NSString*)contentType completionHandler:(void (^)(UUHttpClientResponse* response))completionHandler
{
    UUHttpClientRequest* request = [UUHttpClientRequest putRequest:url queryArguments:queryArguments body:putBody contentType:contentType];
    return [self executeRequest:request completionHandler:completionHandler];
}

+ (instancetype) post:(NSString*)url queryArguments:(NSDictionary*)queryArguments postBody:(NSData*)postBody contentType:(NSString*)contentType completionHandler:(void (^)(UUHttpClientResponse* response))completionHandler
{
    UUHttpClientRequest* request = [UUHttpClientRequest postRequest:url queryArguments:queryArguments body:postBody contentType:contentType];
    return [self executeRequest:request completionHandler:completionHandler];
}
                            
+ (instancetype) executeRequest:(UUHttpClientRequest*)request completionHandler:(void (^)(UUHttpClientResponse* response))completionHandler
{
    UUHttpClient* client = UU_AUTORELEASE([[[self class] alloc] initWithRequest:request progressDelegate:nil]);
	[client execute:completionHandler];
    return client;
}

+ (UUHttpClientResponse*) synchronousGet:(NSString*)url queryArguments:(NSDictionary*)queryArguments
{
	__block UUHttpClientResponse* returnObject = nil;
	
	UUHttpClient* client = [UUHttpClient get:url queryArguments:queryArguments completionHandler:^(UUHttpClientResponse* response)
	{
		returnObject = response;
	}];
	
	while (client.isActive)
	{
		[[NSRunLoop currentRunLoop] run];
	}
	
	return returnObject;
}

+ (UUHttpClientResponse*) synchronousPut:(NSString*)url  queryArguments:(NSDictionary*)queryArguments putBody:(NSData*)putBody contentType:(NSString*)contentType
{
	__block UUHttpClientResponse* returnObject = nil;
	
	UUHttpClient* client = [UUHttpClient put:url queryArguments:queryArguments putBody:putBody contentType:contentType completionHandler:^(UUHttpClientResponse* response)
	{
		returnObject = response;
	}];
	
	while (client.isActive)
	{
		[[NSRunLoop currentRunLoop] run];
	}
	
	return returnObject;
}

+ (UUHttpClientResponse*) synchronousPost:(NSString*)url queryArguments:(NSDictionary*)queryArguments postBody:(NSData*)postBody contentType:(NSString*)contentType
{
	__block UUHttpClientResponse* returnObject = nil;
	
	UUHttpClient* client = [UUHttpClient post:url queryArguments:queryArguments postBody:postBody contentType:contentType completionHandler:^(UUHttpClientResponse* response)
	{
		returnObject = response;
	}];
	
	while (client.isActive)
	{
		[[NSRunLoop currentRunLoop] run];
	}
	
	return returnObject;
}



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public instance Methods
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id) initWithRequest:(UUHttpClientRequest*)request progressDelegate:(NSObject<UUHttpProgressDelegate>*)progressDelegate
{
    //Do a one time install of the default response handlers
    static bool defaultHandlersInstalled = false;
    if (!defaultHandlersInstalled)
        [UUHttpClient installDefaultResponseHandlers];
    
	self = [super init];
	if (self)
	{
        self.clientRequest = request;
        self.rxBuffer = [NSMutableData data];
		self.progressDelegate = progressDelegate;
	}
	
	return self;
}

- (void) execute:(void (^)(UUHttpClientResponse* response))completionHandler
{
	self.blocksCompletionHandler = completionHandler;
	[self begin];
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Internals
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) begin
{
    self.request = [[self class] buildRequest:self.clientRequest];
    UUDebugLog(@"Begin HTTP request for url: %@", self.request.URL);
    
	self.isActive = YES;
    self.connection = [NSURLConnection connectionWithRequest:self.request delegate:self];
    [UUHttpClient addToRequestQueue:self];
}

- (void) cancel
{
    [self.connection cancel];
    
    self.error = [NSError errorWithDomain:kUUHttpClientErrorDomain code:UUHttpClientErrorUserCancelled userInfo:nil];
    [self notifyCancelled];
    [UUHttpClient removeFromRequestQueue:self];
}

- (void) notifyFailure:(NSError*)error
{
    UUDebugLog(@"\n\n **** UUHttpClient Received an Error Reply for url **** \n%@\n\n%@\n", self.request.URL, error);
    self.isActive = NO;
    if (self.blocksCompletionHandler)
    {
		UUHttpClientResponse* httpResponse = UU_AUTORELEASE([[UUHttpClientResponse alloc] init]);
		httpResponse.httpRequest= self.request;
		httpResponse.httpResponse = self.response;
		httpResponse.httpError = error;
        self.blocksCompletionHandler(httpResponse);
    }
	
	if (self.progressDelegate && [self.progressDelegate respondsToSelector:@selector(downloadTerminated)])
		[self.progressDelegate downloadTerminated];
}

- (void) notifySuccess:(id)response
{
	self.isActive = NO;
    if (self.blocksCompletionHandler)
    {
		UUHttpClientResponse* httpResponse = UU_AUTORELEASE([[UUHttpClientResponse alloc] init]);
		httpResponse.httpError = nil;
		httpResponse.httpResponse = self.response;
		httpResponse.httpRequest= self.request;		
		httpResponse.parsedResponse = response;
        self.blocksCompletionHandler(httpResponse);
    }

	if (self.progressDelegate && [self.progressDelegate respondsToSelector:@selector(downloadTerminated)])
		[self.progressDelegate downloadTerminated];
}

- (void) notifyCancelled
{
    if (self.blocksCompletionHandler)
    {
		UUHttpClientResponse* httpResponse = UU_AUTORELEASE([[UUHttpClientResponse alloc] init]);
		httpResponse.httpRequest= self.request;		
		httpResponse.httpError = self.error;
        self.blocksCompletionHandler(httpResponse);
    }

	if (self.progressDelegate && [self.progressDelegate respondsToSelector:@selector(downloadTerminated)])
		[self.progressDelegate downloadTerminated];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSURLConnection delegate
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // Clear the receive buffer
	[self.rxBuffer setLength:0];
	
	self.expectedResponseLength = -1;
	if (response != nil && [response isKindOfClass:[NSHTTPURLResponse class]])
	{
		self.response = (NSHTTPURLResponse*)response;
		self.expectedResponseLength = [self.response expectedContentLength];
	}
	
	if (self.progressDelegate && [self.progressDelegate respondsToSelector:@selector(downloadResponseReceived:expectedResponseSize:)])
		[self.progressDelegate downloadResponseReceived:self expectedResponseSize:self.expectedResponseLength];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	self.totalBytesReceived += data.length;
	[self.rxBuffer appendData:data];
	if (self.progressDelegate && [self.progressDelegate respondsToSelector:@selector(downloadProgress:bytesReceived:totalBytes:)])
		[self.progressDelegate downloadProgress:self bytesReceived:self.totalBytesReceived totalBytes:self.expectedResponseLength];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.error = error;
    [self notifyFailure:error];
    [UUHttpClient removeFromRequestQueue:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection*) connection
{
    NSError* err = nil;
    id parsedResponse = nil;
    
    int httpResponseCode = self.response.statusCode;
    
    if (self.response == nil)
    {
        err = [NSError errorWithDomain:kUUHttpClientErrorDomain code:UUHttpClientErrorNoResponse userInfo:nil];
    }
    else if (!self.rxBuffer || self.rxBuffer.length == 0)
    {
        err = [NSError errorWithDomain:kUUHttpClientErrorDomain code:UUHttpClientErrorEmptyResponse userInfo:nil];
    }
    else
    {
        parsedResponse = [self parseResponse];
        if ([parsedResponse isKindOfClass:[NSError class]])
        {
            err = parsedResponse;
            parsedResponse = nil;
        }
        
        if (![self isHttpSuccessResponseCode:httpResponseCode])
        {
            NSMutableDictionary* d = [NSMutableDictionary dictionary];
            [d setValue:@(httpResponseCode) forKey:kUUHttpClientHttpErrorCodeKey];
            [d setValue:[NSHTTPURLResponse localizedStringForStatusCode:httpResponseCode] forKey:kUUHttpClientHttpErrorMessageKey];
            [d setValue:parsedResponse forKey:kUUHttpClientAppResponseKey];
            
            err = [NSError errorWithDomain:kUUHttpClientErrorDomain code:UUHttpClientErrorHttpError userInfo:d];
        }
    }
    
    if (err)
    {
        [self notifyFailure:err];
    }
    else
    {
        [self notifySuccess:parsedResponse];
    }
    
    [UUHttpClient removeFromRequestQueue:self];
}

- (id) parseResponse
{
	NSString* mimeType = self.response.MIMEType;
	UUDebugLog(@"MIMEType: %@", mimeType);
	
	NSObject<UUHttpResponseHandler>* handler = [[[self class] sharedResponseHandlers] objectForKey:self.response.MIMEType];
	if (handler)
		return [handler parseResponse:self.rxBuffer response:self.response forRequest:self.request];
	
	return nil;
}

#pragma mark - Private Methods

+ (NSString*) httpVerbString:(UUHttpMethod)method
{
    switch (method)
    {
        case UUHttpMethodGet:
            return kUUHttpMethodGet;
            
        case UUHttpMethodPut:
            return kUUHttpMethodPut;
            
        case UUHttpMethodPost:
            return kUUHttpMethodPost;
            
        case UUHttpMethodDelete:
            return kUUHttpMethodDelete;
            
        case UUHttpMethodHead:
            return kUUHttpMethodHead;
            
        default:
            return @"";
    }
}
+ (NSMutableURLRequest*) buildRequest:(UUHttpClientRequest*)request
{
    NSString* fullUrl = request.url;
    if (request.queryArguments != nil && request.queryArguments.count > 0)
    {
        fullUrl = [request.url stringByAppendingString:[self buildQueryString:request.queryArguments]];
    }
    
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fullUrl]];
    [req setHTTPMethod:[self httpVerbString:request.httpMethod]];
    [req setTimeoutInterval:request.timeout];
    
    if (request.headerFields)
    {
        NSArray* allKeys = [request.headerFields allKeys];
        for (NSString* key in allKeys)
        {
            NSString* val = [request.headerFields valueForKey:key];
            if (key && val)
            {
                [req addValue:val forHTTPHeaderField:key];
            }
        }
    }
    
    if (request.body)
    {
        [req setValue:[NSString stringWithFormat:@"%d", request.body.length] forHTTPHeaderField:kUUContentLengthHeader];
        [req setHTTPBody:request.body];
    }
    
    return req;
}


+ (NSString*) buildQueryString:(NSDictionary*)dictionary
{
    NSMutableString* queryStringArgs = [NSMutableString string];
    
    if (dictionary && dictionary.count > 0)
    {
        [queryStringArgs appendString:@"?"];
        
        // Append query string args
        int count = 0;
        NSArray* keys = [dictionary allKeys];
        for (int i = 0; i < dictionary.count; i++)
        {
            NSString* key = [keys objectAtIndex:i];
            id rawVal = [dictionary objectForKey:key];
            
            NSString* val = nil;
            if ([rawVal isKindOfClass:[NSString class]])
            {
                val = (NSString*)rawVal;
            }
            else if ([rawVal isKindOfClass:[NSNumber class]])
            {
                val = [rawVal stringValue];
            }
            
            if (val != nil)
            {
                if (count > 0)
                {
                    [queryStringArgs appendString:@"&"];
                }
                
                [queryStringArgs appendFormat:@"%@=%@", [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [val stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                ++count;
            }
        }
    }
    
    return queryStringArgs;
}

#pragma mark - Request Queue

+ (NSMutableArray*) sharedRequestQueue
{
    if (theSharedRequestQueue == nil)
    {
        theSharedRequestQueue = [[NSMutableArray alloc] init];
    }
    
    return theSharedRequestQueue;
}

+ (void) cancelAllRequests
{
    NSMutableArray* queue = [self sharedRequestQueue];
    @synchronized(queue)
    {
        int count = queue.count;
        for (int i = 0; i < count; i++)
        {
            [[queue objectAtIndex:i] cancel];
        }
    }
}

+ (void) toggleNetworkActivityIndicator:(BOOL)enabled
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:enabled];
}

+ (void) addToRequestQueue:(id)client
{
    NSMutableArray* queue = [self sharedRequestQueue];
    @synchronized(queue)
    {
        [queue addObject:client];
        [self toggleNetworkActivityIndicator:YES];
    }
}

+ (void) removeFromRequestQueue:(id)client
{
    NSMutableArray* queue = [self sharedRequestQueue];
    @synchronized(queue)
    {
        [queue removeObject:client];
        
        if (queue.count <= 0)
        {
            [self toggleNetworkActivityIndicator:NO];
        }
    }
}

- (BOOL) isHttpSuccessResponseCode:(int)responseCode
{
    switch (responseCode)
    {
        case 200: // OK
        case 201: // Created
            return YES;
            
        default:
            return NO;
    }
}


#pragma mark - Response Handlers

+ (NSMutableDictionary*) sharedResponseHandlers
{
    if (theResponseHandlers == nil)
    {
        theResponseHandlers = [[NSMutableDictionary alloc] init];
    }
    
    return theResponseHandlers;
}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark- Response Handlers
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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

