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

#if __has_feature(objc_arc)
    #define UU_BRIDGE(x) (__bridge x)
#else
    #define UU_BRIDGE(x) (x)
#endif

@implementation NSString (UUStringTwiddling)

+ (NSString*) uuHexStringFromData:(NSData*)data
{
	NSMutableString* sb = UU_AUTORELEASE([[NSMutableString alloc] init]);
    
    const char* rawData = [data bytes];
    int count = data.length;
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
	int length = self.length;
	
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
	for (int i = [self length] - 1; i >= 0; i--) {
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

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Http String Functions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NSString (UUHttpString)

- (NSString *) uuUrlEncoded
{
	CFStringRef cf = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8);
	if (cf) {
		NSString* s = UU_BRIDGE(NSString *)cf;
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
		NSString* s = UU_BRIDGE(NSString *)cf;
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
	CC_MD5(buffer.bytes, buffer.length, md5Buffer);
 
	// Convert unsigned char buffer to NSString of hex values
	NSMutableString* digest = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
	for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
	{
		[digest appendFormat:@"%02x",md5Buffer[i]];
	}
	
	return [[self lowercaseString] isEqualToString:[digest lowercaseString]];
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
		return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
	}
	
	//If we got here there was a problem. Clean up and bail.
	free(buffer);
	return nil;
}



@end