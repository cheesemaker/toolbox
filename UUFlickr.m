//
//  UUFlickr
//  Useful Utilities - Useful functions to interact with Flickr
// (c) Copyright Jonathan Hays, all rights reserved
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import "UUFlickr.h"
#import "UUString.h"
#import "UUHttpClient.h"
#import "UUString.h"

//ARC Preprocessor
#if __has_feature(objc_arc)
	#define UU_RELEASE(x)		(void)(0)
	#define UU_RETAIN(x)		x
	#define UU_AUTORELEASE(x)	x
	#define UU_BLOCK_RELEASE(x) (void)(0)
	#define UU_BLOCK_COPY(x)    [x copy]
	#define UU_NATIVE_CAST(x)	(__bridge x)
#else
	#define UU_RELEASE(x)		[x release]
	#define UU_RETAIN(x)		[x retain]
	#define UU_AUTORELEASE(x)	[(x) autorelease]
	#define UU_BLOCK_RELEASE(x) Block_release(x)
	#define UU_BLOCK_COPY(x)    Block_copy(x)
	#define UU_NATIVE_CAST(x)	(x)
#endif

//Pref location where we store the Instagram User Secret
#define kUUFlickrOAuthTokenPref		@"::UUFlickrOAuthTokenIdentifier::"
#define kUUFlickrOAuthSecretPref	@"::UUFlickrOAuthSecretIdentifier::"
#define kUUFlickrOAuthVerifierPref  @"::UUFlickrOAuthVerifierIdentifier::"
#define kUUFlickrUserIdPref			@"::UUFlickrUserIdIdentifier::"
#define kUUFlickrUserNamePref		@"::UUFlickrUserNameIdentifier::"

@interface UUFlickr()
	@property (nonatomic, copy)	  void (^completionHandler)(BOOL success, NSError* error);
	@property (nonatomic, strong) NSString* appKey;
	@property (nonatomic, strong) NSString* appSecret;
	@property (nonatomic, strong) NSString* appCallback;

	@property (nonatomic, strong) NSString* oAuthToken;
	@property (nonatomic, strong) NSString* oAuthSecret;
	@property (nonatomic, strong) NSString* oAuthVerifier;

	@property (nonatomic, strong) NSString* userId;
	@property (nonatomic, strong) NSString* userName;
@end


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UUFlickr
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation UUFlickr

////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - General Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (UUFlickr*) sharedInstance
{
	static dispatch_once_t onceToken;
	static UUFlickr* theFlicker = nil;

    dispatch_once (&onceToken, ^
	{
		theFlicker = [[UUFlickr alloc] init];
    });
		
	return theFlicker;
}

+ (void) saveAuthInfo
{
	UUFlickr* flickr = [UUFlickr sharedInstance];
	[[NSUserDefaults standardUserDefaults] setObject:flickr.oAuthToken forKey:kUUFlickrOAuthTokenPref];
	[[NSUserDefaults standardUserDefaults] setObject:flickr.oAuthSecret forKey:kUUFlickrOAuthSecretPref];
	[[NSUserDefaults standardUserDefaults] setObject:flickr.oAuthVerifier forKey:kUUFlickrOAuthVerifierPref];
	[[NSUserDefaults standardUserDefaults] setObject:flickr.userId forKey:kUUFlickrUserIdPref];
	[[NSUserDefaults standardUserDefaults] setObject:flickr.userName forKey:kUUFlickrUserNamePref];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void) loadSavedAuthInfo
{
	UUFlickr* flickr = [UUFlickr sharedInstance];
	flickr.oAuthToken = [[NSUserDefaults standardUserDefaults] objectForKey:kUUFlickrOAuthTokenPref];
	flickr.oAuthSecret = [[NSUserDefaults standardUserDefaults] objectForKey:kUUFlickrOAuthSecretPref];
	flickr.oAuthVerifier = [[NSUserDefaults standardUserDefaults] objectForKey:kUUFlickrOAuthVerifierPref];
	flickr.userId = [[NSUserDefaults standardUserDefaults] objectForKey:kUUFlickrUserIdPref];
	flickr.userName = [[NSUserDefaults standardUserDefaults] objectForKey:kUUFlickrUserNamePref];
}

+ (NSString*) userName
{
	UUFlickr* flickr = [UUFlickr sharedInstance];
	return flickr.userName;
}

+ (void) logout
{
	UUFlickr* flickr = [UUFlickr sharedInstance];
	flickr.oAuthToken = nil;
	flickr.oAuthSecret = nil;
	flickr.oAuthVerifier = nil;
	flickr.userId = nil;
	flickr.userName = nil;
	
	[UUFlickr saveAuthInfo];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Authorization
////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (void) initializeKey:(NSString*)key secret:(NSString*)secret callbackURL:(NSString*)callbackURL
{
	UUFlickr* flickr = [UUFlickr sharedInstance];
	flickr.appKey = key;
	flickr.appSecret = secret;
	flickr.appCallback = callbackURL;
	
	[UUFlickr loadSavedAuthInfo];
}

+ (void) authenticate:(UIViewController*)parent completionHandler:(void (^)(BOOL success, NSError* error))completionBlock
{
	UUFlickr* flickr = [self sharedInstance];
	NSAssert(flickr.appKey,		 @"Flickr App Key must be set");
	NSAssert(flickr.appSecret,	 @"Flickr App Secret must be set");
	NSAssert(flickr.appCallback, @"Flickr App Callback must be set");
	
	flickr.completionHandler = completionBlock;
	
	[UUFlickr loadSavedAuthInfo];
	
	if (!flickr.oAuthToken || !flickr.oAuthSecret || !flickr.oAuthVerifier || !flickr.userId)
	{
		[UUFlickr requestOAuthToken];
	}
	else
	{
		flickr.completionHandler(YES, nil);
	}
}

+ (void) requestOAuthToken
{
	NSDictionary* parameters = @{ @"oauth_callback" : [UUFlickr sharedInstance].appCallback };
	NSURL* url = [NSURL URLWithString:@"https://www.flickr.com/services/oauth/request_token"];
	NSString* urlPath = [UUFlickr buildAndSignForURLRequest:parameters baseURL:url method:@"GET"];

	[UUHttpClient get:urlPath queryArguments:nil completionHandler:^(UUHttpClientResponse *response)
	{
		[[UUFlickr sharedInstance] handleResponseFromRequestToken:response];
	}];
}

+ (void) requestUserAuthorization
{
	NSString* urlPath = [NSString stringWithFormat:@"https://www.flickr.com/services/oauth/authorize?oauth_token=%@", [[UUFlickr sharedInstance].oAuthToken uuUrlEncoded]];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlPath]];
}

+ (void) exchangeForAccessToken
{
	UUFlickr* flickr = [UUFlickr sharedInstance];

	NSDictionary* arguments = [NSDictionary dictionary];
	NSURL* url = [NSURL URLWithString:@"https://www.flickr.com/services/oauth/access_token"];
	NSString* signedURL = [UUFlickr buildAndSignForURLRequest:arguments baseURL:url method:@"GET"];
	[UUHttpClient get:signedURL queryArguments:arguments completionHandler:^(UUHttpClientResponse *response)
	{
		if (!response.httpError)
		{
			NSData* rawResponse = response.rawResponse;
			NSString* stringResponse = [[NSString alloc] initWithData:rawResponse encoding:NSUTF8StringEncoding];
			NSLog(@"%@", stringResponse);
	
			NSDictionary* dictionary = [stringResponse uuDictionaryFromQueryString];
			NSLog(@"%@", dictionary);
		
			flickr.oAuthToken = [dictionary objectForKey:@"oauth_token"];
			flickr.oAuthSecret = [dictionary objectForKey:@"oauth_token_secret"];
			flickr.userId = [dictionary objectForKey:@"user_nsid"];
			flickr.userName = [dictionary objectForKey:@"username"];
			[UUFlickr saveAuthInfo];
		
			if (flickr.oAuthToken && flickr.oAuthSecret && flickr.userId)
			{
				if (flickr.completionHandler)
					flickr.completionHandler(YES, nil);
			}
			else
			{
				if (flickr.completionHandler)
					flickr.completionHandler(NO, nil);
			}
		}
		else
		{
			if (flickr.completionHandler)
				flickr.completionHandler(NO, response.httpError);
		}
	}];
}

+ (BOOL) checkForAnyError:(UUHttpClientResponse*)response
{
	NSDictionary* dictionary = response.parsedResponse;

	if (!dictionary)
	{
		dictionary = [NSJSONSerialization JSONObjectWithData:response.rawResponse options:NSJSONReadingMutableContainers error:nil];
	}
	
	NSString* status = [dictionary objectForKey:@"stat"];
	if ([status isEqualToString:@"fail"])
	{
		return YES;
	}
	
	return NO;
}

+ (BOOL) checkForAuthorizationError:(UUHttpClientResponse*)response
{
	NSDictionary* dictionary = response.parsedResponse;

	if (!dictionary)
	{
		dictionary = [NSJSONSerialization JSONObjectWithData:response.rawResponse options:NSJSONReadingMutableContainers error:nil];
	}
	
	NSString* status = [dictionary objectForKey:@"stat"];
	NSNumber* code = [dictionary objectForKey:@"code"];
	if ([status isEqualToString:@"fail"] && (code.integerValue == 108 || code.integerValue == 96))
	{
		[UUFlickr sharedInstance].oAuthSecret = nil;
		[UUFlickr sharedInstance].oAuthToken = nil;
		[UUFlickr sharedInstance].oAuthVerifier = nil;
		[self requestOAuthToken];
		return YES;
	}
	return NO;
}


- (void) handleResponseFromRequestToken:(UUHttpClientResponse*)response
{
	if (!response.httpError)
	{
		NSData* rawResponse = response.rawResponse;
		NSString* stringResponse = [[NSString alloc] initWithData:rawResponse encoding:NSUTF8StringEncoding];
		NSLog(@"%@", stringResponse);
		
		NSDictionary* dictionary = [stringResponse uuDictionaryFromQueryString];
		NSString* confirmedString = [dictionary objectForKey:@"oauth_callback_confirmed"];
		if (confirmedString && [[confirmedString lowercaseString] isEqualToString:@"true"])
		{
			NSString* oauthToken = [dictionary objectForKey:@"oauth_token"];
			NSString* oauthTokenSecret = [dictionary objectForKey:@"oauth_token_secret"];
			
			[UUFlickr sharedInstance].oAuthToken = oauthToken;
			[UUFlickr sharedInstance].oAuthSecret = oauthTokenSecret;
			
			[UUFlickr requestUserAuthorization];
		}
		else
		{
			if (self.completionHandler)
			{
				self.completionHandler(NO, nil);
			}
		}
	}
	else
	{
		[self handleHttpError:response.httpError];
	}
}

+ (BOOL) handleURLCallback:(NSURL*)url
{
	NSLog(@"%@", url);
	NSString* fullUrl = [url absoluteString];
	NSDictionary* dictionary = [fullUrl uuDictionaryFromQueryString];
	NSString* oauthVerifier = [dictionary objectForKey:@"oauth_verifier"];
	if (oauthVerifier)
	{
		UUFlickr* flickr = [UUFlickr sharedInstance];
		flickr.oAuthVerifier = oauthVerifier;
	
		[UUFlickr exchangeForAccessToken];
		return YES;
	}
	
	return NO;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Media requests
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSString*) photoSourceURLFromDictionary:(NSDictionary *)inDictionary size:(NSString *)inSizeModifier
{
	NSNumber *farm = [inDictionary objectForKey:@"farm"];
	NSString *photoID = [inDictionary objectForKey:@"id"];
	NSString *secret = [inDictionary objectForKey:@"secret"];
	NSString *server = [inDictionary objectForKey:@"server"];
	
	NSMutableString *URLString = [NSMutableString stringWithString:@"http://"];
	if (farm)
	{
		[URLString appendFormat:@"farm%@.", [farm stringValue]];
	}
	
	[URLString appendString:[@"http://static.flickr.com/" substringFromIndex:7]];
	[URLString appendFormat:@"%@/%@_%@", server, photoID, secret];
	
	if ([inSizeModifier length]) {
		[URLString appendFormat:@"_%@.jpg", inSizeModifier];
	}
	else {
		[URLString appendString:@".jpg"];
	}
	
	return URLString;
}


+ (NSMutableArray*) parseMediaDictionary:(NSDictionary*)sourceDictionary
{
	NSMutableArray* array = [NSMutableArray array];
	
	NSDictionary* photosDictionary = [sourceDictionary objectForKey:@"photos"];
	if (!photosDictionary)
		photosDictionary = [sourceDictionary objectForKey:@"photoset"];
		
	NSArray* photos = [photosDictionary objectForKey:@"photo"];
	for (NSDictionary* photoDictionary in photos)
	{
		NSString* fullSizePath = [UUFlickr photoSourceURLFromDictionary:photoDictionary size:@"b"];
		NSString* thumbnailPath = [UUFlickr photoSourceURLFromDictionary:photoDictionary size:@"s"];
		NSNumber* latitude = [photoDictionary objectForKey:@"latitude"];
		NSNumber* longitude = [photoDictionary objectForKey:@"longitude"];
		NSString* dateString = [photoDictionary objectForKey:@"datetaken"];
		NSDate* date = [NSDate date];
		if (dateString)
		{
			static NSDateFormatter* dateFormatter = nil;
			if (!dateFormatter)
			{
				dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
			}
			
			date = [dateFormatter dateFromString:dateString];
		}
		 
		NSDictionary* individualPhoto = @{ @"photo"		: fullSizePath,
										   @"thumbnail" : thumbnailPath,
										   @"date"		: date,
										   @"latitude"	: latitude,
										   @"longitude" : longitude };
		[array addObject:individualPhoto];
	}
	
	return array;
}

+ (void) requestMediaPage:(NSMutableDictionary*)parameters array:(NSMutableArray*)inPhotoArray responseObject:(NSString*)responseObject completionBlock:(void (^)(BOOL success, NSArray* userMedia))completionBlock
{
	NSURL* url = [NSURL URLWithString:@"http://api.flickr.com/services/rest/"];
	NSString* signedRequest = [UUFlickr buildAndSignForURLRequest:parameters baseURL:url method:@"GET"];
	NSMutableArray* photoArray = inPhotoArray;
	if (!photoArray)
		photoArray = [NSMutableArray array];
		
	[UUHttpClient get:signedRequest queryArguments:nil completionHandler:^(UUHttpClientResponse *response)
	{
		if (!response.httpError)
		{
			if ([UUFlickr checkForAnyError:response])
			{
				if (completionBlock)
					completionBlock(NO, nil);
				
				return;
			}

			NSDictionary* dictionary = response.parsedResponse;
			NSDictionary* containerDictionary = [dictionary objectForKey:responseObject];
			NSNumber* currentPage = [containerDictionary objectForKey:@"page"];
			NSNumber* totalPages = [containerDictionary objectForKey:@"pages"];
			if ([currentPage isKindOfClass:[NSString class]])
			{
				NSString* stringPage = (NSString*)currentPage;
				currentPage = @(stringPage.intValue);
			}
			
			NSMutableArray* photosToAdd = [UUFlickr parseMediaDictionary:response.parsedResponse];
			[photoArray addObjectsFromArray:photosToAdd];
				
			if (([totalPages integerValue] == 0) || [totalPages isEqualToNumber:currentPage])
			{
				if (completionBlock)
					completionBlock(YES, photoArray);
			}
			else
			{
				[parameters setObject:[NSString stringWithFormat:@"%d", currentPage.intValue + 1] forKey:@"page"];
				[UUFlickr requestMediaPage:parameters array:photoArray responseObject:responseObject completionBlock:completionBlock];
			}
		}
		else
		{
			if (completionBlock)
				completionBlock(NO, nil);
		}
	}];
}

+ (void) getUserMedia:(void (^)(BOOL success, NSArray* userMedia))completionBlock
{
	NSString* userId = [UUFlickr sharedInstance].userId;
	NSMutableDictionary* parameters = [NSMutableDictionary dictionaryWithDictionary:
							   @{ @"method"			: @"flickr.people.getPhotos",
								  @"user_id"		: userId,
								  @"format"			: @"json",
								  @"nojsoncallback" : @"1",
								  @"per_page"		: @"500",
								  @"extras"			: @"geo,date_taken",
								  @"api_key"		: [UUFlickr sharedInstance].appKey } ];
	
	[UUFlickr requestMediaPage:parameters array:nil responseObject:@"photos" completionBlock:completionBlock];
}

+ (void) getPhotoSetMedia:(NSString*)photoSetId completionBlock:(void (^)(BOOL success, NSArray* userMedia))completionBlock
{
	NSString* userId = [UUFlickr sharedInstance].userId;
	
	NSMutableDictionary* parameters = [NSMutableDictionary dictionaryWithDictionary:
							   @{ @"method"			: @"flickr.photosets.getPhotos",
								  @"photoset_id"	: photoSetId,
								  @"media"			: @"photos",
								  @"user_id"		: userId,
								  @"format"			: @"json",
								  @"nojsoncallback" : @"1",
								  @"per_page"		: @"500",
								  @"extras"			: @"geo,date_taken",
								  @"api_key"		: [UUFlickr sharedInstance].appKey }];
				
	[UUFlickr requestMediaPage:parameters array:nil responseObject:@"photoset" completionBlock:completionBlock];
}

+ (void) getUserPhotoSets:(void (^)(BOOL success, NSArray* photoSets))completionBlock
{
	NSString* userId = [UUFlickr sharedInstance].userId;
	NSURL* url = [NSURL URLWithString:@"http://api.flickr.com/services/rest/"];
	NSDictionary* parameters = @{ @"method"			: @"flickr.photosets.getList",
								  @"user_id"		: userId,
								  @"format"			: @"json",
								  @"nojsoncallback" : @"1",
								  @"per_page"		: @"500",
								  @"primary_photo_extras" : @"url_sq",
								  @"api_key"		: [UUFlickr sharedInstance].appKey };
	NSString* signedRequest = [UUFlickr buildAndSignForURLRequest:parameters baseURL:url method:@"GET"];
	[UUHttpClient get:signedRequest queryArguments:nil completionHandler:^(UUHttpClientResponse *response)
	{
		if (!response.httpError)
		{
			if ([UUFlickr checkForAnyError:response])
			{
				if (completionBlock)
					completionBlock(NO, nil);
				
				return;
			}

			NSMutableArray* returnedPhotoSets = [NSMutableArray array];
			NSDictionary* dictionary = response.parsedResponse;
			NSDictionary* photoSetDictionary = [dictionary objectForKey:@"photosets"];
			NSArray* photoSetArray = [photoSetDictionary objectForKey:@"photoset"];
			for (NSDictionary* singleSetDictionary in photoSetArray)
			{
				NSString* identifier = [singleSetDictionary objectForKey:@"id"];
				NSDictionary* titleDictionary = [singleSetDictionary objectForKey:@"title"];
				NSString* titleString = [titleDictionary objectForKey:@"_content"];
				NSNumber* count = [singleSetDictionary objectForKey:@"photos"];
				NSString* primaryPhotoURL = [[singleSetDictionary objectForKey:@"primary_photo_extras"] objectForKey:@"url_sq"];
				
				[returnedPhotoSets addObject:@{ @"id" : identifier, @"title" : titleString, @"count" : count, @"primary_photo_url" : primaryPhotoURL }];
			}
		
			if (completionBlock)
				completionBlock(YES, returnedPhotoSets);
		}
		else
		{
			if (completionBlock)
				completionBlock(NO, nil);
		}
	}];
}

+ (void) getUserPhotoCount:(void (^)(BOOL success, NSInteger count))completionBlock
{
	NSString* userId = [UUFlickr sharedInstance].userId;
	NSURL* url = [NSURL URLWithString:@"http://api.flickr.com/services/rest/"];
	NSDictionary* parameters = @{ @"method"			: @"flickr.people.getPhotos",
								  @"user_id"		: userId,
								  @"format"			: @"json",
								  @"nojsoncallback" : @"1",
								  @"per_page"		: @"0",
								  @"api_key"		: [UUFlickr sharedInstance].appKey };
	NSString* signedRequest = [UUFlickr buildAndSignForURLRequest:parameters baseURL:url method:@"GET"];
	[UUHttpClient get:signedRequest queryArguments:nil completionHandler:^(UUHttpClientResponse *response)
	 {
		 if (!response.httpError)
		 {
			if ([UUFlickr checkForAnyError:response])
			{
				if (completionBlock)
					completionBlock(NO, 0);
				
				return;
			}
			 
			 NSDictionary* dictionary = response.parsedResponse;
			 NSNumber* total_photos = [[dictionary objectForKey:@"photos"] objectForKey:@"total"];
			 
			 completionBlock(YES, [total_photos integerValue]);
		 }
		 else
		 {
			completionBlock(NO, 0);
		 }
	 }];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - General Functions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//method can be "GET", "POST" or "HEAD"
+ (NSString*) buildAndSignForURLRequest:(NSDictionary*)otherArguments baseURL:(NSURL*)url method:(NSString*)method
{
	//Flickr wants LOTS of arguments
	unsigned long timeStampLong = (unsigned long)[[NSDate date] timeIntervalSince1970];
	NSString* nonce = [NSString stringWithFormat:@"%lu", (unsigned long)arc4random()];
	NSString* timeStamp = [NSString stringWithFormat:@"%lu", (unsigned long)timeStampLong];
	NSString* consumerKey = [UUFlickr sharedInstance].appKey;
	NSString* signatureMethod = @"HMAC-SHA1";
	NSString* oAuthVersion = @"1.0";
	NSString* oAuthToken = [UUFlickr sharedInstance].oAuthToken;
	NSString* oAuthVerifier = [UUFlickr sharedInstance].oAuthVerifier;
	
	//Build a dictionary with all of the arguments
    NSMutableDictionary* arguments = [NSMutableDictionary dictionaryWithDictionary:otherArguments];
    [arguments setObject:oAuthVersion		forKey:@"oauth_version"];
    [arguments setObject:signatureMethod	forKey:@"oauth_signature_method"];
    [arguments setObject:nonce				forKey:@"oauth_nonce"];
    [arguments setObject:timeStamp			forKey:@"oauth_timestamp"];
    [arguments setObject:consumerKey		forKey:@"oauth_consumer_key"];
	if (oAuthToken)
		[arguments setObject:oAuthToken			forKey:@"oauth_token"];
	if (oAuthVerifier)
		[arguments setObject:oAuthVerifier forKey:@"oauth_verifier"];
    
	NSString* queryArgumentsAsString = @"";
	NSArray* sortedArguments = [[arguments allKeys] sortedArrayUsingSelector:@selector(compare:)];
	for (NSString* keyName in sortedArguments)
	{
		NSString* value = [[arguments objectForKey:keyName] uuUrlEncoded];
		if (queryArgumentsAsString.length)
			queryArgumentsAsString = [queryArgumentsAsString stringByAppendingString:@"&"];
		queryArgumentsAsString = [queryArgumentsAsString stringByAppendingString:[NSString stringWithFormat:@"%@=%@", keyName, value]];
	}

	NSString* urlEncodedArguments = [queryArgumentsAsString uuUrlEncoded];
	NSString* urlEncodedURL = [[url absoluteString] uuUrlEncoded];
	
	//Then prepend the method aka GET or POST
	NSString* baseStringForSignature = [NSString stringWithFormat:@"%@&%@&%@", method, urlEncodedURL, urlEncodedArguments];

	//Setup the signature key
    NSString* signatureKey = [NSString stringWithFormat:@"%@&", [UUFlickr sharedInstance].appSecret];
	if ([UUFlickr sharedInstance].oAuthSecret)
		signatureKey = [NSString stringWithFormat:@"%@&%@", [UUFlickr sharedInstance].appSecret, [UUFlickr sharedInstance].oAuthSecret];

    NSString* signature = [baseStringForSignature uuHMACSHA1:signatureKey];
	signature = [signature uuUrlEncoded];
	
	NSString* fullURL = [NSString stringWithFormat:@"%@?%@", [url absoluteString], queryArgumentsAsString];
	fullURL = [fullURL stringByAppendingString:[NSString stringWithFormat:@"&%@=%@", @"oauth_signature", signature]];
	
    return fullURL;
}

- (void) handleHttpError:(NSError*)httpError
{
	//Need to do something here!
	NSLog(@"%@", httpError);
	
	if (self.completionHandler)
		self.completionHandler(NO, httpError);
}

@end



