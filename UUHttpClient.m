//
//  UUHttpClient.m
//  Useful Utilities - Lightweight Objective C HTTP Client
//  Copyright (c) 2013 Jonathan Hays. All rights reserved.
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
#import "UUDictionary.h"

NSString * const kUUHttpClientErrorDomain           = @"kUUHttpClientErrorDomain";
NSString * const kUUHttpClientHttpErrorCodeKey      = @"kUUHttpClientHttpErrorCodeKey";
NSString * const kUUHttpClientHttpErrorMessageKey   = @"kUUHttpClientHttpErrorMessageKey";
NSString * const kUUHttpClientAppResponseKey        = @"kUUHttpClientAppResponseKey";

const NSTimeInterval kUUDefaultHttpTimeout  = 60.0f;

static NSMutableArray* theSharedRequestQueue;
static NSMutableDictionary* theResponseHandlers;
static NSTimeInterval theDefaultHttpTimeout = kUUDefaultHttpTimeout;


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
		self.processMimeTypes = YES;
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

+ (instancetype) deleteRequest:(NSString*)url queryArguments:(NSDictionary*)queryArguments
{
    UUHttpClientRequest* cr = UU_AUTORELEASE([[UUHttpClientRequest alloc] initWithUrl:url]);
    cr.httpMethod = UUHttpMethodDelete;
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

+ (instancetype) getRequest:(NSString*)url queryArguments:(NSDictionary*)queryArguments user:(NSString*)user password:(NSString*)password
{
	UUHttpClientRequest* cr = [self getRequest:url queryArguments:queryArguments];
	cr.credentials = [NSURLCredential credentialWithUser:user password:password persistence:NSURLCredentialPersistenceForSession];
	[self addBasicAuthToHeaders:cr.headerFields user:user password:password];

	return cr;
}

+ (instancetype) deleteRequest:(NSString*)url queryArguments:(NSDictionary*)queryArguments user:(NSString*)user password:(NSString*)password
{
	UUHttpClientRequest* cr = [self deleteRequest:url queryArguments:queryArguments];
	cr.credentials = [NSURLCredential credentialWithUser:user password:password persistence:NSURLCredentialPersistenceForSession];
	[self addBasicAuthToHeaders:cr.headerFields user:user password:password];

	return cr;
}

+ (instancetype) putRequest:(NSString*)url queryArguments:(NSDictionary*)queryArguments body:(NSData*)body contentType:(NSString*)contentType user:(NSString*)user password:(NSString*)password
{
	UUHttpClientRequest* cr = [self putRequest:url queryArguments:queryArguments body:body contentType:contentType];
	cr.credentials = [NSURLCredential credentialWithUser:user password:password persistence:NSURLCredentialPersistenceForSession];
	[self addBasicAuthToHeaders:cr.headerFields user:user password:password];

	return cr;
}

+ (instancetype) postRequest:(NSString*)url queryArguments:(NSDictionary*)queryArguments body:(NSData*)body contentType:(NSString*)contentType user:(NSString*)user password:(NSString*)password
{
	UUHttpClientRequest* cr = [self postRequest:url queryArguments:queryArguments body:body contentType:contentType];
	cr.credentials = [NSURLCredential credentialWithUser:user password:password persistence:NSURLCredentialPersistenceForSession];
	[self addBasicAuthToHeaders:cr.headerFields user:user password:password];

	return cr;
}

+ (NSDictionary*) addBasicAuthToHeaders:(NSDictionary*)headers user:(NSString*)user password:(NSString*)password
{
	NSMutableDictionary* newDictionary = [NSMutableDictionary dictionaryWithDictionary:headers];
	NSData* authorizationData = [[NSString stringWithFormat:@"%@:%@", user, password] dataUsingEncoding:NSASCIIStringEncoding];
	NSString* authorizationString = [authorizationData base64EncodedStringWithOptions:0];
	[newDictionary setValue:authorizationString forKey:@"Authorization"];
	
	return newDictionary;
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

+ (instancetype) getImage:(NSString*)url queryArguments:(NSDictionary*)queryArguments scale:(float)imageScale completionHandler:(void (^)(NSError* error, UIImage* image))completionHandler
{
	UUHttpClientRequest* request = [UUHttpClientRequest getRequest:url queryArguments:queryArguments];
	request.processMimeTypes = NO;
	return [self executeRequest:request completionHandler:^(UUHttpClientResponse *response)
	{
		UIImage* image = nil;
		if (response.rawResponse)
		{
			image = [UIImage imageWithData:response.rawResponse scale:imageScale];
		}
		
		completionHandler(response.httpError, image);
	}];
}

+ (instancetype) getImage:(NSString*)url queryArguments:(NSDictionary*)queryArguments scale:(float)imageScale user:(NSString *)user password:(NSString *)password completionHandler:(void (^)(NSError *, UIImage *))completionHandler
{
	UUHttpClientRequest* request = [UUHttpClientRequest getRequest:url queryArguments:queryArguments user:user password:password];
	request.processMimeTypes = NO;
	return [self executeRequest:request completionHandler:^(UUHttpClientResponse *response)
	{
		UIImage* image = nil;
		if (response.rawResponse)
		{
			image = [UIImage imageWithData:response.rawResponse scale:imageScale];
		}
		
		completionHandler(response.httpError, image);
	}];
}

+ (instancetype) get:(NSString*)url queryArguments:(NSDictionary*)queryArguments completionHandler:(void (^)(UUHttpClientResponse* response))completionHandler
{
    UUHttpClientRequest* request = [UUHttpClientRequest getRequest:url queryArguments:queryArguments];
    return [self executeRequest:request completionHandler:completionHandler];
}

+ (instancetype) delete:(NSString*)url queryArguments:(NSDictionary*)queryArguments completionHandler:(void (^)(UUHttpClientResponse* response))completionHandler
{
    UUHttpClientRequest* request = [UUHttpClientRequest deleteRequest:url queryArguments:queryArguments];
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

+ (instancetype) get:(NSString*)url queryArguments:(NSDictionary*)queryArguments user:(NSString*)user password:(NSString*)password completionHandler:(void (^)(UUHttpClientResponse* response))completionHandler
{
    UUHttpClientRequest* request = [UUHttpClientRequest getRequest:url queryArguments:queryArguments user:user password:password];
    return [self executeRequest:request completionHandler:completionHandler];
}

+ (instancetype) delete:(NSString*)url queryArguments:(NSDictionary*)queryArguments user:(NSString*)user password:(NSString*)password completionHandler:(void (^)(UUHttpClientResponse* response))completionHandler
{
    UUHttpClientRequest* request = [UUHttpClientRequest deleteRequest:url queryArguments:queryArguments user:user password:password];
    return [self executeRequest:request completionHandler:completionHandler];
}

+ (instancetype) put:(NSString*)url queryArguments:(NSDictionary*)queryArguments putBody:(NSData*)putBody contentType:(NSString*)contentType user:(NSString*)user password:(NSString*)password completionHandler:(void (^)(UUHttpClientResponse* response))completionHandler
{
    UUHttpClientRequest* request = [UUHttpClientRequest putRequest:url queryArguments:queryArguments body:putBody contentType:contentType user:user password:password];
    return [self executeRequest:request completionHandler:completionHandler];
}

+ (instancetype) post:(NSString*)url queryArguments:(NSDictionary*)queryArguments postBody:(NSData*)postBody contentType:(NSString*)contentType user:(NSString*)user password:(NSString*)password completionHandler:(void (^)(UUHttpClientResponse* response))completionHandler
{
    UUHttpClientRequest* request = [UUHttpClientRequest postRequest:url queryArguments:queryArguments body:postBody contentType:contentType user:user password:password];
    return [self executeRequest:request completionHandler:completionHandler];
}
                            
+ (UUHttpClientResponse*) synchronousGetImage:(NSString*)url queryArguments:(NSDictionary*)queryArguments scale:(float)imageScale
{
	UUHttpClientRequest* request = [UUHttpClientRequest getRequest:url queryArguments:queryArguments];
	request.processMimeTypes = NO;
	UUHttpClient* client = UU_AUTORELEASE([[UUHttpClient alloc] initWithRequest:request progressDelegate:nil]);
	
	UUHttpClientResponse* response = [client synchronousExecute];
	if (response.rawResponse)
	{
		UIImage* image = [UIImage imageWithData:response.rawResponse scale:imageScale];
		response.parsedResponse = image;
		response.rawResponse = nil;
	}
	
	return response;
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

+ (UUHttpClientResponse*) synchronousDelete:(NSString*)url  queryArguments:(NSDictionary*)queryArguments
{
	__block UUHttpClientResponse* returnObject = nil;
	
	UUHttpClient* client = [UUHttpClient delete:url queryArguments:queryArguments completionHandler:^(UUHttpClientResponse* response)
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

- (UUHttpClientResponse*) synchronousExecute
{
	__block UUHttpClientResponse* returnObject = nil;
	
	[self execute:^(UUHttpClientResponse *response)
	{
		returnObject = response;
	}];
	
	while (self.isActive)
	{
		[[NSRunLoop currentRunLoop] run];
	}
	
	return returnObject;
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
    if (self.blocksCompletionHandler)
    {
		UUHttpClientResponse* httpResponse = UU_AUTORELEASE([[UUHttpClientResponse alloc] init]);
		httpResponse.httpRequest= self.request;
		httpResponse.httpResponse = self.response;
		httpResponse.httpError = error;
        self.blocksCompletionHandler(httpResponse);
    }

    self.isActive = NO;
	
	if (self.progressDelegate && [self.progressDelegate respondsToSelector:@selector(downloadTerminated)])
		[self.progressDelegate downloadTerminated];
}

- (void) notifySuccess:(id)response
{
    if (self.blocksCompletionHandler)
    {
		UUHttpClientResponse* httpResponse = UU_AUTORELEASE([[UUHttpClientResponse alloc] init]);
		httpResponse.httpError = nil;
		httpResponse.httpResponse = self.response;
		httpResponse.httpRequest= self.request;		
		httpResponse.parsedResponse = response;
		
		if (!response)
			httpResponse.rawResponse = self.rxBuffer;
		
        self.blocksCompletionHandler(httpResponse);
    }

	self.isActive = NO;

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

	self.isActive = NO;

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
		self.expectedResponseLength = (NSUInteger)[self.response expectedContentLength];
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
    
    NSInteger httpResponseCode = self.response.statusCode;
    
    if (self.response == nil)
    {
        err = [NSError errorWithDomain:kUUHttpClientErrorDomain code:UUHttpClientErrorNoResponse userInfo:nil];
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

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	UUDebugLog(@"Received authentication challenge");
    if (![challenge previousFailureCount])
	{
		if (self.clientRequest.credentials)
		{
			[challenge.sender useCredential:self.clientRequest.credentials forAuthenticationChallenge:challenge];
		}
    }
}

- (id) parseResponse
{
	if (self.clientRequest.processMimeTypes)
	{
		NSString* mimeType = self.response.MIMEType;
		UUDebugLog(@"MIMEType: %@", mimeType);
		UUDebugLog(@"%@", [[NSString alloc] initWithData:self.rxBuffer encoding:NSUTF8StringEncoding]);
	
		NSObject<UUHttpResponseHandler>* handler = [[[self class] sharedResponseHandlers] objectForKey:self.response.MIMEType];
		if (handler)
			return [handler parseResponse:self.rxBuffer response:self.response forRequest:self.request];
	}
	
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
        fullUrl = [request.url stringByAppendingString:[request.queryArguments uuBuildQueryString]];
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
        [req setValue:[NSString stringWithFormat:@"%lu", (unsigned long)request.body.length] forHTTPHeaderField:kUUContentLengthHeader];
        [req setHTTPBody:request.body];
    }
    
    return req;
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
        NSInteger count = queue.count;
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

- (BOOL) isHttpSuccessResponseCode:(NSInteger)responseCode
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
		[UUHttpClient installDefaultResponseHandlers];
    }
    
    return theResponseHandlers;
}

@end

