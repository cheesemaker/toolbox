//
//  UUHttpSession.m
//  UUToolboxTestBed
//
//  Created by Ryan DeVore on 8/28/14.
//  Copyright (c) 2014 Ryan DeVore. All rights reserved.
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

//const NSTimeInterval kUUDefaultHttpTimeout  = 60.0f;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation UUHttpRequest

- (id) initWithUrl:(NSString*)url
{
    self = [super init];
    
    if (self)
    {
        self.url = url;
        self.httpMethod = UUHttpMethodGet;
        //self.timeout = theDefaultHttpTimeout;
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

@end

@implementation UUHttpResponse
//Nothing to see here.  Move along...
@end






@interface UUHttpSession ()

@property (nonatomic, strong) NSURLSession* urlSession;
@property (nonatomic, strong) NSMutableArray* activeTasks;
@property (nonatomic, strong) NSMutableDictionary* responseHandlers;

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
        NSOperationQueue* queue = [[NSOperationQueue alloc] init];
        [queue setMaxConcurrentOperationCount:1];
        
        NSURLSessionConfiguration* sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfiguration.timeoutIntervalForRequest = 60.0f;
        
        self.urlSession = [NSURLSession sessionWithConfiguration:sessionConfiguration];
        
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

- (UUHttpRequest*) executeRequest:(UUHttpRequest*)request completionHandler:(void (^)(UUHttpResponse* response))completionHandler
{
    NSURLRequest* httpRequest = [[self class] buildRequest:request];
    
    NSURLSessionTask* task = [self.urlSession dataTaskWithRequest:httpRequest
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        [self handleResponse:request httpRequest:httpRequest data:data response:response error:error completion:completionHandler];
    }];
    
    [self.activeTasks addObject:task];
    [task resume];
    return request;
}

- (void) handleResponse:(UUHttpRequest*)request
            httpRequest:(NSURLRequest*)httpRequest
                   data:(NSData*)data
               response:(NSURLResponse*)response
                  error:(NSError*)error
             completion:(void (^)(UUHttpResponse* response))completion
{
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    
    UUHttpResponse* uuResponse = [UUHttpResponse new];
    uuResponse.httpResponse = httpResponse;
    uuResponse.httpRequest = httpRequest;
    uuResponse.rawResponse = data;
    
    NSError* err = nil;
    id parsedResponse = nil;
    
    NSInteger httpResponseCode = httpResponse.statusCode;
    
    if (error)
    {
        NSDictionary* userInfo = @{ NSUnderlyingErrorKey : error };
        err = [NSError errorWithDomain:kUUHttpSessionErrorDomain code:UUHttpSessionErrorHttpFailure userInfo:userInfo];
    }
    else if (response == nil)
    {
        err = [NSError errorWithDomain:kUUHttpSessionErrorDomain code:UUHttpSessionErrorNoResponse userInfo:nil];
    }
    else if (!data || data.length == 0)
    {
        err = [NSError errorWithDomain:kUUHttpSessionErrorDomain code:UUHttpSessionErrorEmptyResponse userInfo:nil];
    }
    else
    {
        if (request.processMimeTypes)
        {
            parsedResponse = [self parseResponse:httpRequest httpResponse:httpResponse data:data];
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
    switch (responseCode)
    {
        case 200: // OK
        case 201: // Created
            return YES;
            
        default:
            return NO;
    }
}

- (id) parseResponse:(NSURLRequest*)httpRequest httpResponse:(NSHTTPURLResponse*)httpResponse data:(NSData*)data
{
    NSString* mimeType = httpResponse.MIMEType;
    UUDebugLog(@"MIMEType: %@", mimeType);
    
    NSObject<UUHttpResponseHandler>* handler = [self.responseHandlers objectForKey:mimeType];
    if (handler)
    {
        return [handler parseResponse:data response:httpResponse forRequest:httpRequest];
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

@end
