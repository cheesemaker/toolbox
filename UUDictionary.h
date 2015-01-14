//
//  UUDictionary.h
//  Useful Utilities - Extensions for NSDictionary
//
//  Created by Ryan DeVore on 4/18/14.
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com
//

#import <Foundation/Foundation.h>

@interface NSDictionary (UUDictionary)

// Safely get the object at the specified key.  If the object is NSNull, then
// nil will be returned.
- (id) uuSafeGet:(NSString*)key;

// Safely gets an object and verifies it is of the expected class type. If
// the value is NSNull or not of the expecting type, nil will be returned
- (id) uuSafeGet:(NSString*)key forClass:(Class)forClass;

// Safely gets an object and verifies it is of the expected class type.  If the
// value is NSNull or not of the expected type, the passed in default will be
// returned.
- (id) uuSafeGet:(NSString*)key forClass:(Class)forClass defaultValue:(id)defaultValue;

// Safely gets an NSNumber.  If the value is an NSString, this method will
// attempt to convert it to a number object using NSNumberFormatter
- (NSNumber*) uuSafeGetNumber:(NSString*)key;
- (NSNumber*) uuSafeGetNumber:(NSString*)key defaultValue:(NSNumber*)defaultValue;

// Safely gets an NSString
- (NSString*) uuSafeGetString:(NSString*)key;
- (NSString*) uuSafeGetString:(NSString*)key defaultValue:(NSString*)defaultValue;

// Safely gets a string object and formats is as an NSDate using the
// specified NSDateFormatter
- (NSDate*) uuSafeGetDate:(NSString*)key formatter:(NSDateFormatter*)formatter;

// Convenience wrappers
- (NSDictionary*) uuSafeGetDictionary:(NSString*)key;
- (NSArray*) uuSafeGetArray:(NSString*)key;

@end


@interface NSDictionary (UUHttpDictionary)

// Builds a formatted query string from the dictionary arguments.  Only handles
// value objects that are NSNumber or NSString.
- (NSString*) uuBuildQueryString;

@end