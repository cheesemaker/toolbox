//
//  UUAccessorySession.h
//  Useful Utilities - Simple client for communicating with an external accessory
//
//  Created by Ryan on 02/01/16
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//

#import <Foundation/Foundation.h>
#import <ExternalAccessory/ExternalAccessory.h>

typedef void (^UUAccessoryConnectCallback)(NSError* error);
typedef void (^UUAccessoryWriteDataCallback)(NSError* error);
typedef void (^UUAccessoryReadDataCallback)(NSError* error, NSData* data);
typedef void (^UUAccessoryPushedDataCallback)(NSData* data);

@interface UUAccessorySession : NSObject

- (id) initWithProtocol:(NSString*)protocol;

- (BOOL) isConnected;
- (void) connect:(UUAccessoryConnectCallback)completion;
- (void) writeData:(NSData*)data completion:(UUAccessoryWriteDataCallback)completion;
- (void) readData:(NSUInteger)count timeout:(NSTimeInterval)timeout completion:(UUAccessoryReadDataCallback)completion;

// Some accessories will just push data to the phone.  This provides a raw data pipe
// where the accessory data will be passed along.
//
// NOTE: This callback will only be invoked if there is no current call to readData that
// is waiting for data to come in.
- (void) registerPushedDataCallback:(UUAccessoryPushedDataCallback)callback;

@end




extern NSString * const kUUAccessorySessionErrorDomain;

typedef NS_ENUM(NSInteger, UUAccessorySessionErrorCode)
{
    UUAccessorySessionErrorCodeBluetoothPickerError = 1000,
    UUAccessorySessionErrorCodeUnableToCreateAccessory,
    UUAccessorySessionErrorCodeUnableToAcquireInputStream,
    UUAccessorySessionErrorCodeUnableToOpenInputStream,
    UUAccessorySessionErrorCodeUnableToAcquireOutputStream,
    UUAccessorySessionErrorCodeUnableToOpenOutputStream,
    UUAccessorySessionErrorCodeNoDeviceFound,
    UUAccessorySessionErrorCodeNoDeviceFoundReadDataTimeout
};

@interface NSError (UUAccessorySession)

+ (instancetype) uuAccessorySessionError:(UUAccessorySessionErrorCode)code;
+ (instancetype) uuAccessorySessionError:(UUAccessorySessionErrorCode)code inner:(NSError*)inner;

@end
