//
//  UUAwsS3Client.h
//  Useful Utilities - Lightweight Wrapper for Amazon S3
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  This file requires the AWSS3 and AWSRuntime frameworks

#import <Foundation/Foundation.h>
#import <AWSS3/AWSS3.h>

typedef void (^UUAwsS3UploadCompletionHandler)(NSString* resourceUrl, NSError* error);
typedef void (^UUAwsS3UploadProgressHandler)(float percent);

@interface UUAwsS3Client : NSObject

// Should be called prior to any usage.
+ (void) init:(NSString*)accessId key:(NSString*)key bucket:(NSString*)bucket;

// Uploads a single file to Amazon S3.  File access is set to public read
// so the returned URL can be used.
+ (UUAwsS3Client*) uploadFile:(NSData*)data
                     fileName:(NSString*)fileName
                  contentType:(NSString*)contentType
                     progress:(UUAwsS3UploadProgressHandler)progress
                   completion:(UUAwsS3UploadCompletionHandler)completion;

@end