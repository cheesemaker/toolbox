//
//  UUInstagram
//  Useful Utilities - Useful functions to interact with Instagram
// (c) Copyright Jonathan Hays, all rights reserved
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import <Foundation/Foundation.h>

@interface UUInstagram : NSObject
	+ (void) initialize:(NSString*)clientId secret:(NSString*)clientSecret redirect:(NSString*)redirectURL;
	+ (void) authenticate:(UIViewController*)parent completionHandler:(void (^)(BOOL success, NSError* error))completionBlock;

	+ (NSString*) userName;
	+ (void) logout;
	
	+ (void) getUserMedia:(void (^)(BOOL success, NSDictionary* userMedia))completionBlock;
	+ (void) getUserFeed:(void (^)(BOOL success, NSDictionary* userMedia))completionBlock;
	+ (void) getPopularMedia:(void (^)(BOOL success, NSDictionary* userMedia))completionBlock;

	//Helper functions to build the URLs for thumbnails and standard resolution URL's for images
	+ (NSArray*) listOfUserThumbnailURLs:(NSDictionary*)userMedia;
	+ (NSArray*) listOfUserImageURLs:(NSDictionary*)userMedia;

	+ (NSString*) accessToken;
@end

