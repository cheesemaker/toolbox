//
//  UUHttpSession.m
//  Useful Utilities - Lightweight Objective C HTTP Client
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//

#import "UUHttpSession.h"
#import "UUDictionary.h"

//If you want to provide your own logging mechanism, define UUDebugLog in your .pch
#ifndef UUDebugLog
#ifdef DEBUG
#define UUDebugLog(fmt, ...) NSLog(fmt, ##__VA_ARGS__)
#else
#define UUDebugLog(fmt, ...)
#endif
#endif

NSString * const kUUHttpSessionErrorDomain           = @"kUUHttpSessionErrorDomain";
NSString * const kUUHttpSessionHttpErrorCodeKey      = @"kUUHttpSessionHttpErrorCodeKey";
NSString * const kUUHttpSessionHttpErrorMessageKey   = @"kUUHttpSessionHttpErrorMessageKey";
NSString * const kUUHttpSessionAppResponseKey        = @"kUUHttpSessionAppResponseKey";

const NSTimeInterval kUUDefaultHttpRequestTimeout = 60.0f;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface UUHttpRequest ()

@property (atomic, strong, readwrite) NSURLRequest* httpRequest;

@end

@implementation UUHttpRequest

- (id) initWithUrl:(NSString*)url
{
    self = [super init];
    
    if (self)
    {
        self.url = url;
        self.httpMethod = UUHttpMethodGet;
		self.processMimeTypes = YES;
    }
    
    return self;
}

+ (instancetype) getRequest:(NSString*)url queryArguments:(NSDictionary*)queryArguments
{
    UUHttpRequest* cr = [[[self class] alloc] initWithUrl:url];
    cr.httpMethod = UUHttpMethodGet;
    cr.queryArguments = queryArguments;
    return cr;
}

+ (instancetype) deleteRequest:(NSString*)url queryArguments:(NSDictionary*)queryArguments
{
    UUHttpRequest* cr = [[[self class] alloc] initWithUrl:url];
    cr.httpMethod = UUHttpMethodDelete;
    cr.queryArguments = queryArguments;
    return cr;
}

+ (instancetype) putRequest:(NSString*)url queryArguments:(NSDictionary*)queryArguments body:(NSData*)body contentType:(NSString*)contentType
{
    UUHttpRequest* cr = [[[self class] alloc] initWithUrl:url];
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
    UUHttpRequest* cr = [[[self class] alloc] initWithUrl:url];
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
    UUHttpRequest* cr = [self getRequest:url queryArguments:queryArguments];
    cr.credentials = [NSURLCredential credentialWithUser:user password:password persistence:NSURLCredentialPersistenceForSession];
    cr.headerFields = [self addBasicAuthToHeaders:cr.headerFields user:user password:password];
    
    return cr;
}

+ (instancetype) deleteRequest:(NSString*)url queryArguments:(NSDictionary*)queryArguments user:(NSString*)user password:(NSString*)password
{
    UUHttpRequest* cr = [self deleteRequest:url queryArguments:queryArguments];
    cr.credentials = [NSURLCredential credentialWithUser:user password:password persistence:NSURLCredentialPersistenceForSession];
    cr.headerFields = [self addBasicAuthToHeaders:cr.headerFields user:user password:password];
    
    return cr;
}

+ (instancetype) putRequest:(NSString*)url queryArguments:(NSDictionary*)queryArguments body:(NSData*)body contentType:(NSString*)contentType user:(NSString*)user password:(NSString*)password
{
    UUHttpRequest* cr = [self putRequest:url queryArguments:queryArguments body:body contentType:contentType];
    cr.credentials = [NSURLCredential credentialWithUser:user password:password persistence:NSURLCredentialPersistenceForSession];
    cr.headerFields = [self addBasicAuthToHeaders:cr.headerFields user:user password:password];
    
    return cr;
}

+ (instancetype) postRequest:(NSString*)url queryArguments:(NSDictionary*)queryArguments body:(NSData*)body contentType:(NSString*)contentType user:(NSString*)user password:(NSString*)password
{
    UUHttpRequest* cr = [self postRequest:url queryArguments:queryArguments body:body contentType:contentType];
    cr.credentials = [NSURLCredential credentialWithUser:user password:password persistence:NSURLCredentialPersistenceForSession];
    cr.headerFields = [self addBasicAuthToHeaders:cr.headerFields user:user password:password];
    
    return cr;
}

+ (NSDictionary*) addBasicAuthToHeaders:(NSDictionary*)headers user:(NSString*)user password:(NSString*)password
{
    NSMutableDictionary* newDictionary = [NSMutableDictionary dictionaryWithDictionary:headers];
    NSData* authorizationData = [[NSString stringWithFormat:@"%@:%@", user, password] dataUsingEncoding:NSASCIIStringEncoding];
    NSString* authorizationString = [authorizationData base64EncodedStringWithOptions:0];
    NSString* basicAuthString = [NSString stringWithFormat:@"Basic %@", authorizationString];
    [newDictionary setValue:basicAuthString forKey:@"Authorization"];
    
    return newDictionary;
}

@end

@implementation UUHttpResponse

- (NSString *)description
{
	return [NSString stringWithFormat:@"UUHTTP Response:\r%@\r\rError:\r%@", self.httpResponse, self.httpError];
}

- (NSString *)debugDescription
{
	return [NSString stringWithFormat:@"*****UUHTTP Response*****\r%@\r\r*****Error*****\r%@\r\r*****Original Request*****\r%@", self.httpResponse, self.httpError, self.httpRequest];
}



@end






@interface UUHttpSession () <NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSession* urlSession;
@property (nonatomic, strong) NSURLSessionConfiguration* sessionConfiguration;
@property (nonatomic, strong) NSMutableArray* activeTasks;
@property (nonatomic, strong) NSMutableDictionary* responseHandlers;

+ (instancetype) sharedInstance;

- (UUHttpRequest*) executeRequest:(UUHttpRequest*)request completionHandler:(UUHttpSessionResponseHandler)completionHandler;

- (UUHttpRequest*) get:(NSString*)url queryArguments:(NSDictionary*)queryArguments completionHandler:(UUHttpSessionResponseHandler)completionHandler;
- (UUHttpRequest*) delete:(NSString*)url queryArguments:(NSDictionary*)queryArguments completionHandler:(UUHttpSessionResponseHandler)completionHandler;
- (UUHttpRequest*) put:(NSString*)url queryArguments:(NSDictionary*)queryArguments putBody:(NSData*)putBody contentType:(NSString*)contentType completionHandler:(UUHttpSessionResponseHandler)completionHandler;
- (UUHttpRequest*) post:(NSString*)url queryArguments:(NSDictionary*)queryArguments postBody:(NSData*)postBody contentType:(NSString*)contentType completionHandler:(UUHttpSessionResponseHandler)completionHandler;

@end

@implementation UUHttpSession

+ (instancetype) sharedInstance
{
	static id theSharedObject = nil;
	static dispatch_once_t onceToken;
    
    dispatch_once (&onceToken, ^
    {
        theSharedObject = [[[self class] alloc] init];
    });
	
	return theSharedObject;
}

- (void) installDefaultResponseHandlers
{
    [self registerResponseHandler:[UUJsonResponseHandler new]];
    [self registerResponseHandler:[UUTextResponseHandler new]];
    [self registerResponseHandler:[UUBinaryResponseHandler new]];
    [self registerResponseHandler:[UUImageResponseHandler new]];
}

- (void) registerResponseHandler:(NSObject<UUHttpResponseHandler>*)handler
{
    for (NSString* mimeType in [handler supportedMimeTypes])
    {
        [self.responseHandlers setObject:handler forKey:mimeType];
    }
}

- (id) init
{
    self = [super init];
    
    if (self)
    {
        self.sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.sessionConfiguration.timeoutIntervalForRequest = kUUDefaultHttpRequestTimeout;
        
        self.urlSession = [NSURLSession sessionWithConfiguration:self.sessionConfiguration];// delegate:self delegateQueue:nil];
        
        self.activeTasks = [NSMutableArray array];
        self.responseHandlers = [NSMutableDictionary dictionary];
        [self installDefaultResponseHandlers];
    }
    
    return self;
}

- (UUHttpRequest*) get:(NSString*)url queryArguments:(NSDictionary*)queryArguments completionHandler:(UUHttpSessionResponseHandler)completionHandler
{
    UUHttpRequest* req = [UUHttpRequest getRequest:url queryArguments:queryArguments];
    return [self executeRequest:req completionHandler:completionHandler];
}

- (UUHttpRequest*) delete:(NSString*)url queryArguments:(NSDictionary*)queryArguments completionHandler:(UUHttpSessionResponseHandler)completionHandler
{
    UUHttpRequest* req = [UUHttpRequest deleteRequest:url queryArguments:queryArguments];
    return [self executeRequest:req completionHandler:completionHandler];
}

- (UUHttpRequest*) put:(NSString*)url queryArguments:(NSDictionary*)queryArguments putBody:(NSData*)putBody contentType:(NSString*)contentType completionHandler:(UUHttpSessionResponseHandler)completionHandler
{
    UUHttpRequest* req = [UUHttpRequest putRequest:url queryArguments:queryArguments body:putBody contentType:contentType];
    return [self executeRequest:req completionHandler:completionHandler];
}

- (UUHttpRequest*) post:(NSString*)url queryArguments:(NSDictionary*)queryArguments postBody:(NSData*)postBody contentType:(NSString*)contentType completionHandler:(UUHttpSessionResponseHandler)completionHandler
{
    UUHttpRequest* req = [UUHttpRequest postRequest:url queryArguments:queryArguments body:postBody contentType:contentType];
    return [self executeRequest:req completionHandler:completionHandler];
}

- (UUHttpRequest*) executeRequest:(UUHttpRequest*)request completionHandler:(UUHttpSessionResponseHandler)completionHandler
{
    request.httpRequest = [[self class] buildRequest:request];
    
    UUDebugLog(@"Begin Request\n\nMethod: %@\nURL: %@\nHeaders:\n%@\n\n", request.httpRequest.HTTPMethod, request.httpRequest.URL, request.httpRequest.allHTTPHeaderFields);
    
    NSURLSessionTask* task = [self.urlSession dataTaskWithRequest:request.httpRequest
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        [self handleResponse:request data:data response:response error:error completion:completionHandler];
    }];
    
    
    [self.activeTasks addObject:task];
    [task resume];
    return request;
}

- (void) handleResponse:(UUHttpRequest*)request
                   data:(NSData*)data
               response:(NSURLResponse*)response
                  error:(NSError*)error
             completion:(void (^)(UUHttpResponse* response))completion
{
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    
    UUHttpResponse* uuResponse = [UUHttpResponse new];
    uuResponse.httpResponse = httpResponse;
    uuResponse.httpRequest = request.httpRequest;
    uuResponse.rawResponse = data;
    
    NSError* err = nil;
    id parsedResponse = nil;
    
    NSInteger httpResponseCode = httpResponse.statusCode;
    
    if (error)
    {
        NSDictionary* userInfo = @{ NSUnderlyingErrorKey : error };
        err = [NSError errorWithDomain:kUUHttpSessionErrorDomain code:UUHttpSessionErrorHttpFailure userInfo:userInfo];
    }
    else
    {
        if (request.processMimeTypes)
        {
            parsedResponse = [self parseResponse:request httpResponse:httpResponse data:data];
            if ([parsedResponse isKindOfClass:[NSError class]])
            {
                err = parsedResponse;
                parsedResponse = nil;
            }
        }
		
        if (![self isHttpSuccessResponseCode:httpResponseCode])
        {
            NSMutableDictionary* d = [NSMutableDictionary dictionary];
            [d setValue:@(httpResponseCode) forKey:kUUHttpSessionHttpErrorCodeKey];
            [d setValue:[NSHTTPURLResponse localizedStringForStatusCode:httpResponseCode] forKey:kUUHttpSessionHttpErrorMessageKey];
            [d setValue:parsedResponse forKey:kUUHttpSessionAppResponseKey];
            
            err = [NSError errorWithDomain:kUUHttpSessionErrorDomain code:UUHttpSessionErrorHttpError userInfo:d];
        }
    }
    
    uuResponse.httpError = err;
    uuResponse.parsedResponse = parsedResponse;
    
    if (completion)
    {
        completion(uuResponse);
    }
}

- (BOOL) isHttpSuccessResponseCode:(NSInteger)responseCode
{
    return (responseCode >= 200 && responseCode < 300);
}

- (id) parseResponse:(UUHttpRequest*)request httpResponse:(NSHTTPURLResponse*)httpResponse data:(NSData*)data
{
    NSURLRequest* httpRequest = request.httpRequest;
    
    NSString* mimeType = httpResponse.MIMEType;
    
    UUDebugLog(@"Handle Response\n\nMethod: %@\nURL: %@\nMIMEType: %@\nRaw Response:\n\n%@\n\n", request.httpRequest.HTTPMethod, request.httpRequest.URL, mimeType, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    NSObject<UUHttpResponseHandler>* handler = [self.responseHandlers objectForKey:mimeType];
    if (handler)
    {
        id parsedResponse = [handler parseResponse:data response:httpResponse forRequest:httpRequest];
        return parsedResponse;
    }
    
	return nil;
}

+ (void) setRequestTimeout:(NSTimeInterval)requestTimeout
{
    [[[self sharedInstance] sessionConfiguration] setTimeoutIntervalForRequest:requestTimeout];
}

+ (UUHttpRequest*) executeRequest:(UUHttpRequest*)request completionHandler:(UUHttpSessionResponseHandler)completionHandler
{
    return [[self sharedInstance] executeRequest:request completionHandler:completionHandler];
}

+ (UUHttpRequest*) get:(NSString*)url queryArguments:(NSDictionary*)queryArguments completionHandler:(UUHttpSessionResponseHandler)completionHandler
{
    return [[self sharedInstance] get:url queryArguments:queryArguments completionHandler:completionHandler];
}

+ (UUHttpRequest*) delete:(NSString*)url queryArguments:(NSDictionary*)queryArguments completionHandler:(UUHttpSessionResponseHandler)completionHandler
{
    return [[self sharedInstance] delete:url queryArguments:queryArguments completionHandler:completionHandler];
}

+ (UUHttpRequest*) put:(NSString*)url queryArguments:(NSDictionary*)queryArguments putBody:(NSData*)putBody contentType:(NSString*)contentType completionHandler:(UUHttpSessionResponseHandler)completionHandler
{
    return [[self sharedInstance] put:url queryArguments:queryArguments putBody:putBody contentType:contentType completionHandler:completionHandler];
}

+ (UUHttpRequest*) post:(NSString*)url queryArguments:(NSDictionary*)queryArguments postBody:(NSData*)postBody contentType:(NSString*)contentType completionHandler:(UUHttpSessionResponseHandler)completionHandler
{
    return [[self sharedInstance] post:url queryArguments:queryArguments postBody:postBody contentType:contentType completionHandler:completionHandler];
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

+ (NSMutableURLRequest*) buildRequest:(UUHttpRequest*)request
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

////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSURLSessionDelegate
////////////////////////////////////////////////////////////////////////////////

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    
}


@end
