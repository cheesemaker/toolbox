//
//  UUString.m
//  Useful Utilities - Extensions for NSStrings
//
//  Created by Jonathan on 7/29/13.
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import "UUString.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonHMAC.h>

//If you want to impement your own UU_RELEASE and UU_AUTORELEASE mechanisms in your .pch, you may do so, just remember to define UU_MEMORY_MANAGEMENT
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

@implementation NSString (UUStringTwiddling)

+ (NSString*) uuHexStringFromData:(NSData*)data
{
	NSMutableString* sb = UU_AUTORELEASE([[NSMutableString alloc] init]);
    
    const char* rawData = [data bytes];
    NSUInteger count = data.length;
    for (int i = 0; i < count; i++)
    {
        [sb appendFormat:@"%02X", (UInt8)rawData[i]];
    }
    
	return sb;
}

+ (NSData*) uuToHexData:(NSString*)string
{
	return [string uuToHexData];
}

- (NSData*) uuToHexData
{
	NSUInteger length = self.length;
	
	// Must be divisible by two
	if ((length % 2) != 0)
		return nil;
	
	NSMutableData* data = UU_AUTORELEASE([[NSMutableData alloc] init]);
	
	for (int i = 0; i < length; i += 2)
	{
		NSScanner* sc = [NSScanner scannerWithString:(NSString*)[self substringWithRange:NSMakeRange(i, 2)]];
		unsigned int hex = 0;
		if ([sc scanHexInt:&hex])
		{
            UInt8 tmp = (UInt8)hex;
            [data appendBytes:&tmp length:sizeof(tmp)];
		}
		else
		{
			return nil;
		}
	}
	
	return data;
}

+ (NSString*) uuGenerateUUIDString
{
	CFUUIDRef uuid = CFUUIDCreate(NULL);
	NSString* uniqueID = UU_NATIVE_CAST(NSString*)CFUUIDCreateString(NULL, uuid);
	CFRelease(uuid);

	return UU_AUTORELEASE(uniqueID);
}

+ (NSString*) uuFormatCurrency:(NSDecimalNumber*)value withLocale:(NSLocale*)locale
{
    NSNumberFormatter* nf = UU_AUTORELEASE([[NSNumberFormatter alloc] init]);
    nf.numberStyle = NSNumberFormatterCurrencyStyle;
    nf.locale = locale;
    return [nf stringForObjectValue:value];
}

+ (void) uuAppendRun:(NSArray*)run ToString:(NSMutableString*)sb
{
    if (run.count == 1)
    {
        if (sb.length > 0)
        {
            [sb appendString:@","];
        }
        
        [sb appendFormat:@"%d", [[run objectAtIndex:0] intValue]];
        
    }
    else if (run.count == 2)
    {
        int first = [[run objectAtIndex:0] intValue];
        int last = [[run lastObject] intValue];
        if (sb.length > 0)
        {
            [sb appendString:@","];
        }
        
        if (last - first == 1)
        {
            [sb appendFormat:@"%d,%d", first, last];
        }
        else
        {
            [sb appendFormat:@"%d-%d", first, last];
        }
    }
}

+ (NSString*) uuFormatSortedNumbers:(NSArray*)numbers
{
    int current = 0;
    NSMutableArray* run = [NSMutableArray array];
    NSMutableString* sb = [NSMutableString string];
    
    for (NSNumber* n in numbers)
    {
        current = [n intValue];
        
        if (run.count == 0)
        {
            [run addObject:n];
        }
        else if (run.count == 1)
        {
            if ((current - [run.lastObject intValue]) == 1)
            {
                [run addObject:n];
            }
            else
            {
                [self uuAppendRun:run ToString:sb];
                [run removeAllObjects];
                [run addObject:n];
            }
        }
        else
        {
            if ((current - [run.lastObject intValue]) == 1)
            {
                [run removeLastObject];
                [run addObject:n];
            }
            else
            {
                [self uuAppendRun:run ToString:sb];
                [run removeAllObjects];
                [run addObject:n];
            }
        }
    }
    
    if (run.count > 0)
    {
        [self uuAppendRun:run ToString:sb];
    }
    
    return sb;
}

- (NSString*) uuTrimWhitespace
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString*) uuToProperString
{
    NSString *properString = [[[self substringToIndex:1] uppercaseString] stringByAppendingString:[self substringFromIndex:1]];
    return properString;
}

- (bool) uuContainsString:(NSString*)subString
{
    bool isStringThere = YES;
    NSRange rangeOfSubString  = [self rangeOfString:subString];

    if (rangeOfSubString.location == NSNotFound)
    {
        isStringThere = NO;
    }
    
    return isStringThere;
}

- (bool) uuStartsWithSubstring:(NSString *)inSubstring
{
	NSRange r = [self rangeOfString:inSubstring];
	return (r.length > 0) && (r.location == 0);
}

- (bool) uuEndsWithSubstring:(NSString *)inSubstring
{
	NSRange r = [self rangeOfString:inSubstring];
	return (r.length > 0) && (r.location == ([self length] - [inSubstring length]));
}

- (NSString *) uuReverse
{
	NSMutableString* reversed = [NSMutableString stringWithCapacity:[self length]];
	for (NSInteger i = [self length] - 1; i >= 0; i--) {
		[reversed appendString:[self substringWithRange:NSMakeRange (i, 1)]];
	}
	return reversed;	
}

- (bool) uuCsvContainsString:(NSString*)token
{
    if (token != nil)
    {
        NSArray* tagList = [self componentsSeparatedByString:@","];
        for (NSString* tag in tagList)
        {
            if ([tag caseInsensitiveCompare:token] == NSOrderedSame)
            {
                return YES;
            }
        }
    }
    
    return NO;
}

- (BOOL) uuValidEmailAddress
{
	// Adapted from http://www.cocoawithlove.com/2009/06/verifying-that-string-is-email-address.html
	
    NSString* emailRegex =  @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
							@"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
							@"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
							@"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
							@"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
							@"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
							@"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
				
    NSPredicate* emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", emailRegex];

    return [emailTest evaluateWithObject:self];
}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Http String Functions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NSString (UUHttpString)

- (NSString *) uuUrlEncoded
{
	CFStringRef cf = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8);
	if (cf) {
		NSString* s = UU_NATIVE_CAST(NSString *)cf;
		return UU_AUTORELEASE(s);
	}
	else {
		return self;
	}
}

- (NSString *) uuUrlDecoded
{
	CFStringRef cf = CFURLCreateStringByReplacingPercentEscapes (NULL, (CFStringRef)self, CFSTR(""));
	if (cf) {
		NSString* s = UU_NATIVE_CAST(NSString *)cf;
		return UU_AUTORELEASE(s);
	}
	else {
		return self;
	}
}

- (NSString*) uuFindQueryStringArg:(NSString*)argName
{
    NSRange queryMarkerRange = [self rangeOfString:@"?"];
    if (queryMarkerRange.location != NSNotFound)
    {
        NSUInteger startIndex = queryMarkerRange.location + 1;
        if (self.length - startIndex > 0)
        {
            NSString* wholeQueryString = [self substringFromIndex:(queryMarkerRange.location + 1)];
            NSArray* parts = [wholeQueryString componentsSeparatedByString:@"&"];
            for (NSString* part in parts)
            {
                NSArray* subParts = [part componentsSeparatedByString:@"="];
                if (subParts && subParts.count == 2)
                {
                    if ([argName isEqualToString:subParts[0]])
                    {
                        return subParts[1];
                    }
                }
            }
        }
    }
    
    return nil;
}

- (NSDictionary*) uuDictionaryFromQueryString
{
	NSString* queryString = self;
    NSRange queryMarkerRange = [self rangeOfString:@"?"];
    if (queryMarkerRange.location != NSNotFound)
	{
		queryString = [self substringFromIndex:(queryMarkerRange.location + 1)];
	}
	
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
	NSArray* arguments = [queryString componentsSeparatedByString:@"&"];
	for (NSString* argument in arguments)
	{
		NSArray* elements = [argument componentsSeparatedByString:@"="];
		if (elements.count == 2)
		{
			NSString* key = [elements objectAtIndex:0];
			NSString* value = [elements objectAtIndex:1];
			key = [key uuUrlDecoded];
			value = [value uuUrlDecoded];
			[dictionary setObject:value forKey:key];
		}
	}
	
	return dictionary;
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - String Encryption
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation NSString (UUStringEncryption)

- (bool) uuIsValidMD5Hash:(NSData*)buffer
{
	// Create byte array of unsigned chars
	unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
 
	// Create 16 byte MD5 hash value, store in buffer
	CC_MD5(buffer.bytes, (CC_LONG)buffer.length, md5Buffer);
 
	// Convert unsigned char buffer to NSString of hex values
	NSMutableString* digest = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
	for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
	{
		[digest appendFormat:@"%02x",md5Buffer[i]];
	}
	
	return [[self lowercaseString] isEqualToString:[digest lowercaseString]];
}

- (NSString*) uuHMACSHA1:(NSString*)key
{
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [self cStringUsingEncoding:NSASCIIStringEncoding];

    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];

    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);

    NSData* HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];

    NSString *hash = [HMAC base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    return hash;
}

+ (NSData*) uuAESEncryptString:(NSString*)string with:(NSString*)key
{
	NSData* data = [string dataUsingEncoding:NSUTF8StringEncoding];
	
	char keyRaw[kCCKeySizeAES256 + 1];
	bzero(keyRaw, sizeof(keyRaw));
	[key getCString:keyRaw maxLength:sizeof(keyRaw) encoding:NSUTF8StringEncoding];
	
	size_t bufferSize = [data length] + kCCBlockSizeAES128;
	void* buffer = malloc(bufferSize);
	
	size_t numBytesEncrypted = 0;
	CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
									 keyRaw, kCCKeySizeAES256, NULL,
									 [data bytes], [data length],
									 buffer, bufferSize,
									 &numBytesEncrypted);
				
	if (cryptStatus == kCCSuccess)
	{
		return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
	}

	//If we got here there was a problem. Clean up and bail.
	free(buffer);
	return nil;
}

+ (NSString*) uuAESDecryptData:(NSData*)data with:(NSString*)key
{
	char keyRaw[kCCKeySizeAES256+1];
	bzero(keyRaw, sizeof(keyRaw));	
	[key getCString:keyRaw maxLength:sizeof(keyRaw) encoding:NSUTF8StringEncoding];
		
	size_t bufferSize = [data length] + kCCBlockSizeAES128;
	void *buffer = malloc(bufferSize);
	
	size_t numBytesDecrypted = 0;
	CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
									 keyRaw, kCCKeySizeAES256, NULL,
									 [data bytes], [data length],
									 buffer, bufferSize,
									 &numBytesDecrypted);
	
	if (cryptStatus == kCCSuccess)
	{
        NSData* data = [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
        NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        return str;
	}
	
	//If we got here there was a problem. Clean up and bail.
	free(buffer);
	return nil;
}



@end