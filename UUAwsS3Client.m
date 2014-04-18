//
//  UUAwsS3Client.h
//  Useful Utilities - Lightweight Wrapper for Amazon S3
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  This file requires the AWSS3 and AWSRuntime frameworks

#import "UUAwsS3Client.h"

static NSString* theAwsAccessId = nil;
static NSString* theAwsSecretKey = nil;
static NSString* theAwsBucket = nil;

@interface UUAwsS3Client () <AmazonServiceRequestDelegate>

@property (nonatomic, strong) AmazonS3Client* s3Client;
@property (nonatomic, copy) NSString* accessId;
@property (nonatomic, copy) NSString* secretKey;
@property (nonatomic, copy) NSString* bucket;

@property (nonatomic, copy) UUAwsS3UploadProgressHandler progressBlock;
@property (nonatomic, copy) UUAwsS3UploadCompletionHandler completionBlock;
@property (nonatomic, copy) NSString* fileName;

// Set in didFailWithError
@property (nonatomic, strong) NSError* error;

@end

@implementation UUAwsS3Client

#pragma mark - Static Interface

+ (void) load
{
    [AmazonErrorHandler shouldNotThrowExceptions];
}

+ (void) init:(NSString*)accessId key:(NSString*)key bucket:(NSString*)bucket
{
    theAwsAccessId = accessId;
    theAwsSecretKey = key;
    theAwsBucket = bucket;
}

+ (instancetype) defaultClient
{
    id client = [[[self class] alloc] initWithAccessId:theAwsAccessId
                                             secretKey:theAwsSecretKey
                                                bucket:theAwsBucket];
    return client;
}

// NSString fileName => UUAwsS3Client object
+ (NSMutableDictionary*) pendingRequests
{
	static NSMutableDictionary* theSharedObject = nil;
	static dispatch_once_t onceToken;
    
    dispatch_once (&onceToken, ^
    {
        theSharedObject = [NSMutableDictionary dictionary];
    });
	
	return theSharedObject;
}

+ (UUAwsS3Client*) uploadFile:(NSData*)data
                     fileName:(NSString*)fileName
                  contentType:(NSString*)contentType
                     progress:(UUAwsS3UploadProgressHandler)progress
                   completion:(UUAwsS3UploadCompletionHandler)completion
{
    UUAwsS3Client* client = [self defaultClient];
    client.completionBlock = completion;
    client.progressBlock = progress;
    client.fileName = fileName;
    
    [[self pendingRequests] setValue:client forKey:fileName];
    [client uploadFile:data fileName:fileName contentType:contentType];
    
    return client;
}

#pragma mark - Instance Interface

- (id) initWithAccessId:(NSString*)accessId
              secretKey:(NSString*)secretKey
                 bucket:(NSString*)bucket
{
    self = [super init];
    
    if (self)
    {
        self.accessId = accessId;
        self.secretKey = secretKey;
        self.bucket = bucket;
        self.error = nil;
        
        self.s3Client = [[AmazonS3Client alloc] initWithAccessKey:self.accessId withSecretKey:self.secretKey];
    }
    
    return self;
}

- (void) uploadFile:(NSData*)data
           fileName:(NSString*)fileName
        contentType:(NSString*)contentType
{
    S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:fileName inBucket:self.bucket];
    por.contentType = contentType;
    por.data = data;
    por.delegate = self;
    por.cannedACL = [S3CannedACL publicRead];
    [self.s3Client putObject:por];
}

- (NSString*) formatPublicUrl:(NSString*)fileName
{
    return [NSString stringWithFormat:@"https://s3.amazonaws.com/%@/%@", self.bucket, fileName];
}

#pragma mark - AmazonServiceRequestDelegate

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
    //UUDebugLog(@"\nRequest: %@\n\nResponse:\n%@\n\nError: %@\n\n", request.url, response, response.error);
    
    [self finishUpload];
}

-(void)request:(AmazonServiceRequest *)request didSendData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten totalBytesExpectedToWrite:(long long)totalBytesExpectedToWrite
{
    //UUDebugLog(@"\nRequest: %@\n\nbytesWritten: %lld\ntotalBytesWritten: %lld\ntotalBytesExpected: %lld", request.url, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    
    [self notifyProgress:totalBytesWritten total:totalBytesExpectedToWrite];
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error
{
    //UUDebugLog(@"\nRequest: %@\n\nError:\n%@\n\n", request.url, error);
    
    // Store the error here.  didCompleteWithResonse will still be called.
    self.error = error;
}

#pragma mark - Private

- (void) notifyProgress:(long long)written total:(long long)total
{
    if (self.progressBlock)
    {
        float percent = (float)written / (float)total;
        self.progressBlock(percent);
    }
}

- (void) finishUpload
{
    if (self.completionBlock)
    {
        NSString* url = nil;
        if (!self.error)
        {
            url = [self formatPublicUrl:self.fileName];
        }
        
        self.completionBlock(url, self.error);
        self.completionBlock = nil;
        self.progressBlock = nil;
    }
    
    [[[self class] pendingRequests] removeObjectForKey:self.fileName];
}

@end
