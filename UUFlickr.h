//
//  UUFlickr
//  Useful Utilities - Useful functions to interact with Flickr
// (c) Copyright Jonathan Hays, all rights reserved
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import <Foundation/Foundation.h>

@interface UUFlickr : NSObject

	+ (void) initializeKey:(NSString*)key secret:(NSString*)secret callbackURL:(NSString*)callbackURL;
	+ (void) authenticate:(UIViewController*)parent completionHandler:(void (^)(BOOL success, NSError* error))completionBlock;
	+ (NSString*) userName;
	+ (void) logout;

	+ (void) getUserMedia:(void (^)(BOOL success, NSArray* userMedia))completionBlock;
	+ (void) getPhotoSetMedia:(NSString*)photoSetId completionBlock:(void (^)(BOOL success, NSArray* userMedia))completionBlock;
	+ (void) getUserPhotoSets:(void (^)(BOOL success, NSArray* photoSets))completionBlock;
	+ (void) getUserPhotoCount:(void (^)(BOOL success, NSInteger count))completionBlock;

	// Call this from your App Delegate
	+ (BOOL) handleURLCallback:(NSURL*)url;

@end
