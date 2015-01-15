//
//  UUObjectFactory.h
//  Useful Utilities - Object parsing protocols and helpers
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com
//
//
// These methods and protocols are meant to simplify a common problem when building
// RESTful iOS applications.  That of converting raw data into real objects.
// Typically this will be the form of a JSON web service that the application
// will turn into plain data objects, or Core Data managed objects

@import Foundation;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Object Factory
@protocol UUObjectFactory <NSObject>

+ (id) uuObjectFromDictionary:(NSDictionary*)dictionary withContext:(id)context;

@end

@interface UUObjectFactory : NSObject

+ (id) process:(Class)objectFactoryClass object:(id)object context:(id)context;

@end
