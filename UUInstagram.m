//
//  UUInstagram
//  Useful Utilities - Useful functions to interact with Instagram
// (c) Copyright Jonathan Hays, all rights reserved
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import "UUInstagram.h"
#import "UUString.h"
#import "UUHttpClient.h"

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
#define kUUInstagramUserAccessTokenPref @"::UUInstagramUserAccessToken::"
#define kUUInstagramUserIdentifierPref  @"::UUInstagramUserIdentifier::"
#define kUUInstagramUserNamePref		@"::UUInstagramUserName::"

//Pre-declare here...
@interface UUInstagramLoginViewController : UIViewController<UIWebViewDelegate>
	@property (nonatomic, strong)		UIWebView* webView;
	@property (nonatomic, strong)		UIActivityIndicatorView* spinner;
    @property (nonatomic, strong)		UINavigationBar* navBar;
	@property (nonatomic, copy)			void (^completionHandler)(BOOL success, NSError* error);
@end


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UUInstagram
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface UUInstagram()
	@property (nonatomic, strong) NSString* clientId;
	@property (nonatomic, strong) NSString* clientSecret;
	@property (nonatomic, strong) NSString* redirectURL;

	@property (nonatomic, strong) UUInstagramLoginViewController* loginViewController;
	@property (nonatomic, strong) UIDocumentInteractionController* interactionController;
@end

@implementation UUInstagram

+ (UUInstagram*) sharedInstance
{
	static dispatch_once_t onceToken;
	static UUInstagram* theInstagram = nil;

    dispatch_once (&onceToken, ^
	{
		theInstagram = [[UUInstagram alloc] init];
    });
		
	return theInstagram;
}

+ (void) setAccessToken:(NSString*)secret
{
	[[NSUserDefaults standardUserDefaults] setObject:secret forKey:kUUInstagramUserAccessTokenPref];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString*) accessToken
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:kUUInstagramUserAccessTokenPref];
}

+ (void) setUserIdentifier:(NSNumber*)userIdentifier
{
	[[NSUserDefaults standardUserDefaults] setObject:userIdentifier forKey:kUUInstagramUserIdentifierPref];
}

+ (NSNumber*) userIdentifier
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:kUUInstagramUserIdentifierPref];
}

+ (void) setUserName:(NSString*)userIdentifier
{
	[[NSUserDefaults standardUserDefaults] setObject:userIdentifier forKey:kUUInstagramUserNamePref];
}

+ (NSString*) userName
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:kUUInstagramUserNamePref];
}

+ (NSArray*) listOfUserThumbnailURLs:(NSDictionary*)userMedia
{
	NSMutableArray* thumbnailArray = [NSMutableArray array];
	
	NSArray* array = [userMedia objectForKey:@"data"];
	for (NSDictionary* entryDictionary in array)
	{
		NSDictionary* images = [entryDictionary objectForKey:@"images"];
		NSDictionary* standardResolutionInfo = [images objectForKey:@"thumbnail"];
		NSString* url = [standardResolutionInfo objectForKey:@"url"];
		if (url)
		{
			[thumbnailArray addObject:url];
		}
	}

	return thumbnailArray;
}

+ (NSArray*) listOfUserImageURLs:(NSDictionary*)userMedia
{
	NSMutableArray* thumbnailArray = [NSMutableArray array];
	
	NSArray* array = [userMedia objectForKey:@"data"];
	for (NSDictionary* entryDictionary in array)
	{
		NSDictionary* images = [entryDictionary objectForKey:@"images"];
		NSDictionary* standardResolutionInfo = [images objectForKey:@"standard_resolution"];
		NSString* url = [standardResolutionInfo objectForKey:@"url"];
		if (url)
		{
			[thumbnailArray addObject:url];
		}
	}

	return thumbnailArray;
}

+ (void) initialize:(NSString*)clientId secret:(NSString*)clientSecret redirect:(NSString*)redirectURL
{
	UUInstagram* instagram = [UUInstagram sharedInstance];
	instagram.clientId = clientId;
	instagram.clientSecret = clientSecret;
	instagram.redirectURL = redirectURL;
}

+ (void) authenticate:(UIViewController*)parent completionHandler:(void (^)(BOOL success, NSError* error))completionBlock
{
	UUInstagram* instagram = [self sharedInstance];
	NSAssert(instagram.clientId, @"Client Id must be set. Make sure to call initialize first!");
	NSAssert(instagram.clientSecret, @"Client Secret must be set. Make sure to call initialize first!");
	NSAssert(instagram.redirectURL, @"Redirect URL must be set. Make sure to call initialize first!");

	NSString* accessToken = [self accessToken];
	if (accessToken)
	{
		[UUHttpClient get:@"https://api.instagram.com/v1/users/self/" queryArguments:@{ @"access_token" : accessToken } completionHandler:^(UUHttpClientResponse *response)
		{
			if (!response.httpError)
			{
				NSDictionary* parsedResponse = response.parsedResponse;
				if (parsedResponse)
				{
					NSDictionary* data = [parsedResponse objectForKey:@"data"];
					if (data)
					{
						NSNumber* userId = [data objectForKey:@"id"];
						NSString* userName = [data objectForKey:@"username"];
						[UUInstagram setUserIdentifier:userId];
						[UUInstagram setUserName:userName];
					
						if (completionBlock)
							completionBlock(YES, nil);
						
						return;
					}
				}
			
				//If we got here then Instagram wasn't happy with our token situation
				[instagram showLoginController:parent completionHandler:completionBlock];
			}
			else
			{
				if (completionBlock)
					completionBlock(NO, response.httpError);
			}
		}];
	}
	else
	{
		[instagram showLoginController:parent completionHandler:completionBlock];
	}
}

+ (void) logout
{
	[self setUserIdentifier:nil];
	[self setAccessToken:nil];
	[self setUserName:nil];
}

+ (void) fetchPagination:(NSString*)fullURL withDataArray:(NSMutableArray*)data withCompletionBlock:(void (^)(BOOL success, NSDictionary* userMedia))completionBlock
{
	[UUHttpClient get:fullURL queryArguments:nil completionHandler:^(UUHttpClientResponse *response)
	{
		if (response.parsedResponse)
		{
			NSDictionary* sourceDictionary = response.parsedResponse;
			NSDictionary* paginationDictionary = [sourceDictionary objectForKey:@"pagination"];
			NSString* nextPageURL = nil;
			if (paginationDictionary)
				nextPageURL = [paginationDictionary objectForKey:@"next_url"];

			NSMutableArray* incomingData = [sourceDictionary objectForKey:@"data"];
			[data addObjectsFromArray:incomingData];
			
			if (nextPageURL)
			{
				[UUInstagram fetchPagination:nextPageURL withDataArray:data withCompletionBlock:completionBlock];
			}
			else
			{
				if (completionBlock)
					completionBlock(YES, @{ @"data" : data} );
			}
		}
		else
		{
			if (completionBlock)
				completionBlock(NO, nil);
		}
	}];
}

+ (void) getUserMedia:(void (^)(BOOL success, NSDictionary* userMedia))completionBlock
{
	NSString* baseAPIUrl = @"https://api.instagram.com/v1/users/self/media/recent/";
	NSString* accessToken = [UUInstagram accessToken];

	[UUHttpClient get:baseAPIUrl queryArguments:@{ @"access_token" : accessToken, @"count" : @"100" } completionHandler:^(UUHttpClientResponse *response)
	{
		if (response.parsedResponse)
		{
			NSDictionary* sourceDictionary = response.parsedResponse;
			NSDictionary* paginationDictionary = [sourceDictionary objectForKey:@"pagination"];
			NSString* nextPageURL = nil;
			if (paginationDictionary)
				nextPageURL = [paginationDictionary objectForKey:@"next_url"];
			
			if (nextPageURL)
			{
				NSMutableArray* data = [NSMutableArray arrayWithArray:[sourceDictionary objectForKey:@"data"]];
				[UUInstagram fetchPagination:nextPageURL withDataArray:data withCompletionBlock:completionBlock];
			}
			else
			{
				if (completionBlock)
					completionBlock(YES, response.parsedResponse);
			}
		}
		else
		{
			if (completionBlock)
				completionBlock(NO, nil);
		}
	}];
}

+ (void) getUserFeed:(void (^)(BOOL success, NSDictionary* userMedia))completionBlock
{
	NSString* baseAPIUrl = @"https://api.instagram.com/v1/users/self/feed/";
	NSString* accessToken = [UUInstagram accessToken];

	[UUHttpClient get:baseAPIUrl queryArguments:@{ @"access_token" : accessToken, @"count" : @"100" } completionHandler:^(UUHttpClientResponse *response)
	{
		if (response.parsedResponse)
		{
			NSDictionary* sourceDictionary = response.parsedResponse;
			NSDictionary* paginationDictionary = [sourceDictionary objectForKey:@"pagination"];
			NSString* nextPageURL = nil;
			if (paginationDictionary)
				nextPageURL = [paginationDictionary objectForKey:@"next_url"];
			
			if (nextPageURL)
			{
				NSMutableArray* data = [NSMutableArray arrayWithArray:[sourceDictionary objectForKey:@"data"]];
				[UUInstagram fetchPagination:nextPageURL withDataArray:data withCompletionBlock:completionBlock];
			}
			else
			{
				if (completionBlock)
					completionBlock(YES, response.parsedResponse);
			}
		}
		else
		{
			if (completionBlock)
				completionBlock(NO, nil);
		}
	}];
}

+ (void) getPopularMedia:(void (^)(BOOL success, NSDictionary* userMedia))completionBlock
{
	NSString* baseAPIUrl = @"https://api.instagram.com/v1/media/popular";
	NSString* accessToken = [UUInstagram accessToken];

	[UUHttpClient get:baseAPIUrl queryArguments:@{ @"access_token" : accessToken, @"count" : @"100" } completionHandler:^(UUHttpClientResponse *response)
	{
		if (response.parsedResponse)
		{
			NSDictionary* sourceDictionary = response.parsedResponse;
			NSDictionary* paginationDictionary = [sourceDictionary objectForKey:@"pagination"];
			NSString* nextPageURL = nil;
			if (paginationDictionary)
				nextPageURL = [paginationDictionary objectForKey:@"next_url"];
			
			if (nextPageURL)
			{
				NSMutableArray* data = [NSMutableArray arrayWithArray:[sourceDictionary objectForKey:@"data"]];
				[UUInstagram fetchPagination:nextPageURL withDataArray:data withCompletionBlock:completionBlock];
			}
			else
			{
				if (completionBlock)
					completionBlock(YES, response.parsedResponse);
			}
		}
		else
		{
			if (completionBlock)
				completionBlock(NO, nil);
		}
	}];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id) init
{
	self = [super init];
	if (self)
	{
		self.loginViewController = [[UUInstagramLoginViewController alloc] init];
	}
	
	return self;
}

- (void) showLoginController:(UIViewController*)parent completionHandler:(void (^)(BOOL success, NSError* error))completionBlock
{
	self.loginViewController.view.frame = parent.view.bounds;
	self.loginViewController.completionHandler = completionBlock;
	[parent presentViewController:self.loginViewController animated:YES completion:nil];
}

@end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UUInstagramLoginViewController
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation UUInstagramLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGFloat width = self.view.bounds.size.width;
    CGFloat navBarHeight = 66.0f;
  
    self.navBar = UU_AUTORELEASE([[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, width, navBarHeight)]);
    
    UINavigationItem* item = UU_AUTORELEASE([[UINavigationItem alloc] initWithTitle:@"Login"]);
    
    UIBarButtonItem* b = UU_AUTORELEASE([[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(onCancelClicked:)]);
    item.leftBarButtonItem = b;
    
    [self.navBar pushNavigationItem:item animated:NO];
    
	[self.view addSubview:self.navBar];
    
	self.webView = UU_AUTORELEASE([[UIWebView alloc] initWithFrame:CGRectMake(0, navBarHeight, width, self.view.bounds.size.height - navBarHeight)]);
	self.webView.delegate = self;
	[self.view addSubview:self.webView];
}

- (void) viewWillAppear:(BOOL)animated
{
	self.view.backgroundColor = [UIColor blackColor];
	self.webView.backgroundColor = [UIColor blackColor];
}

- (void) viewDidAppear:(BOOL)animated
{
	NSString* clientId = [UUInstagram sharedInstance].clientId;
	NSString* redirectURL = [UUInstagram sharedInstance].redirectURL;
	
	NSString* url = [NSString stringWithFormat:@"https://api.instagram.com/oauth/authorize/?client_id=%@&redirect_uri=%@&response_type=token", clientId, redirectURL];
	NSURLRequest* urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60.0f];

	//Clear the local cache
	[[NSURLCache sharedURLCache] removeAllCachedResponses];

	for(NSHTTPCookie* cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies])
	{
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
	
	[self.webView loadRequest:urlRequest];

	self.spinner = UU_AUTORELEASE([[UIActivityIndicatorView alloc] init]);
	self.spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
	self.spinner.backgroundColor = [UIColor clearColor];
	self.spinner.center = self.view.center;
	[self.view addSubview:self.spinner];
	self.spinner.hidden = NO;
	[self.spinner startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[self.spinner stopAnimating];
	self.spinner.hidden = YES;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSString* callbackURL = [UUInstagram sharedInstance].redirectURL;
	NSString* callbackSuccessURL = [NSString stringWithFormat:@"%@#access_token=", callbackURL];
	NSURL* url = request.URL;
	NSString* urlString = [[url absoluteString] uuUrlDecoded];
		
	if ([[urlString lowercaseString] hasPrefix:[callbackURL lowercaseString]])
	{
		bool success = [[urlString lowercaseString] uuContainsString:[callbackSuccessURL lowercaseString]];
		
		NSString* accessToken = nil;
		
		if (success)
        {
			accessToken = [urlString substringFromIndex:callbackSuccessURL.length];
			[UUInstagram setAccessToken:accessToken];
			
			[UUHttpClient get:@"https://api.instagram.com/v1/users/self/" queryArguments:@{ @"access_token" : accessToken } completionHandler:^(UUHttpClientResponse *response)
			{
				if (!response.httpError)
				{
					NSDictionary* parsedResponse = response.parsedResponse;
					if (parsedResponse)
					{
						NSDictionary* data = [parsedResponse objectForKey:@"data"];
						if (data)
						{
							NSNumber* userId = [data objectForKey:@"id"];
							NSString* userName = [data objectForKey:@"username"];
							[UUInstagram setUserIdentifier:userId];
							[UUInstagram setUserName:userName];
						}
					}
				}
				
				[self dismissViewControllerAnimated:YES completion:^
				{
					if (self.completionHandler)
						self.completionHandler((response.httpError == nil), response.httpError);
				}];
			}];
			
        }
		else
		{
			[self dismissViewControllerAnimated:YES completion:^
			{
				if (self.completionHandler)
					self.completionHandler(success, nil);
			}];
		}
		
		return NO;
	}
	return YES;
}

- (void) onCancelClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^
     {
         if (self.completionHandler)
         {
             self.completionHandler(NO, nil);
         }
     }];
}



@end
