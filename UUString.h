//
//  UUString.h
//  Useful Utilities - Extensions for NSStrings
//
//  Created by Jonathan on 7/29/13.
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import <Foundation/Foundation.h>


@interface NSString (UUString)

// Formats a sequence of numbers as a list of range or discrete values
// 1,2,3,4,5,6,7,8 ==> "1-8"
// 1,3,5,7,8 ==> "1,3,5,7,8"
// 1,2,3,6,7,8 ==> "1-3,6-8"
// 1,2,3,4,6,8,9,10 ==> "1-4,6,8-10"
+ (NSString*) uuFormatSortedNumbers:(NSArray*)numbers;

+ (NSString*) uuFormatCurrency:(NSDecimalNumber*)value withLocale:(NSLocale*)locale;

- (NSString*) uuTrimWhitespace;
- (NSString*) uuToProperString;

- (bool) uuContainsString:(NSString*)subString;
- (bool) uuStartsWithSubstring:(NSString *)inSubstring;
- (bool) uuEndsWithSubstring:(NSString *)inSubstring;
- (NSString *) uuReverse;

+ (NSString*) uuGenerateUUIDString;

- (NSData*) uuToHexData;
+ (NSData*) uuToHexData:(NSString*)string;
+ (NSString*) uuHexStringFromData:(NSData*)data;

- (bool) uuCsvContainsString:(NSString*)token;

// Validates a string against RFC 2822
- (BOOL) uuValidEmailAddress;

@end


@interface NSString (UUHttpString)

// Extracts the part after the '=' in a typical HTTP query string.
// NSString* url = http://www.threejacks.com?someArg=foobar&anotherArg=blarfo
// NSString* arg = [url parseQueryStringArg:@"someArg"];
// arg is 'foobar'
- (NSDictionary*) uuDictionaryFromQueryString;
- (NSString*)	  uuFindQueryStringArg:(NSString*)argName;
- (NSString *)	  uuUrlEncoded;
- (NSString *)	  uuUrlDecoded;

@end

@interface NSString (UUStringEncryption)

- (bool)		uuIsValidMD5Hash:(NSData*)buffer;
- (NSString*)	uuHMACSHA1:(NSString*)key;
+ (NSData*)		uuAESEncryptString:(NSString*)string with:(NSString*)key;
+ (NSString*)	uuAESDecryptData:(NSData*)data with:(NSString*)key;

@end

