//
//  UUAccessorySession.m
//  Useful Utilities - Simple client for communicating with an external accessory
//
//  Created by Ryan on 02/01/16
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//

#import "UUAccessorySession.h"
#import "UUString.h"
#import "UUData.h"

#ifndef UUDebugLog
#ifdef DEBUG
#define UUDebugLog(fmt, ...) NSLog(fmt, ##__VA_ARGS__)
#else
#define UUDebugLog(fmt, ...)
#endif
#endif

NSString * const kUUAccessorySessionErrorDomain = @"UUAccessorySessionErrorDomain";

@interface UUAccessorySession () <EAAccessoryDelegate, NSStreamDelegate>

@property (nonatomic, copy) NSString* protocol;
@property (nonatomic, strong) EAAccessory* discoveredAccessory;
@property (nonatomic, strong) EASession* currentSession;
@property (nonatomic, strong) NSRunLoop* sessionRunLoop;

@property (nonatomic, strong) NSMutableArray* txQueue; // of NSData
@property (nonatomic, strong) NSMutableData* rxBuffer;

@property (nonatomic, copy) UUAccessoryConnectCallback connectCallback;
@property (nonatomic, copy) UUAccessoryReadDataCallback readDataCallback;
@property (nonatomic, copy) UUAccessoryPushedDataCallback pushDataCallback;
@property (assign) NSUInteger readDataCount;
@property (assign) NSTimeInterval readDataTimeout;
@property (nonatomic, strong) NSTimer* readWatchdogTimer;


@end

@implementation UUAccessorySession

- (id) initWithProtocol:(NSString*)protocol
{
    self = [super init];
    
    if (self)
    {
        self.protocol = protocol;
        self.txQueue = [NSMutableArray array];
        
        [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccessoryConnected:) name:EAAccessoryDidConnectNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccessoryDisconnected:) name:EAAccessoryDidDisconnectNotification object:nil];
    }
    
    return self;
}

- (BOOL) isConnected
{
    return (self.currentSession != nil);
}

- (void) connect:(UUAccessoryConnectCallback)completion
{
    NSError* error = nil;
    EAAccessory* accessory = [self firstConnectedAccessory];
    if (accessory)
    {
        error = [self setupSession:accessory];
    }
    else
    {
        error = [NSError uuAccessorySessionError:UUAccessorySessionErrorCodeNoDeviceFound];
    }
    
    [self invokeBlock:error completion:completion];
}

- (EAAccessory*) firstConnectedAccessory
{
    NSArray* connectedAccessories = [[EAAccessoryManager sharedAccessoryManager] connectedAccessories];
    for (EAAccessory* a in connectedAccessories)
    {
        if ([a.protocolStrings containsObject:self.protocol])
        {
            [self logAccessory:a];
            return a;
        }
    }
    
    return nil;
}

- (void) writeData:(NSData*)data completion:(UUAccessoryWriteDataCallback)completion
{
    [self queueData:data];
    if (completion)
    {
        completion(nil);
    }
}

- (void) readData:(NSUInteger)count timeout:(NSTimeInterval)timeout completion:(UUAccessoryReadDataCallback)completion
{
    self.readDataCallback = completion;
    self.readDataCount = count;
    self.readDataTimeout = timeout;
    [self notifyRxData];
}

- (void) kickReadDataWatchdog
{
    [self cancelReadDataWatchdog];
    
    UUDebugLog(@"Kicking read data watchdog by %@ seconds", @(self.readDataTimeout));
    self.readWatchdogTimer = [NSTimer scheduledTimerWithTimeInterval:self.readDataTimeout target:self selector:@selector(handleReadDataTimeout) userInfo:nil repeats:NO];
}

- (void) cancelReadDataWatchdog
{
    [self.readWatchdogTimer invalidate];
    self.readWatchdogTimer = nil;
}

- (void) handleReadDataTimeout
{
    [self cancelReadDataWatchdog];
    
    UUDebugLog(@"Read data timed out");
    
    NSError* error = [NSError uuAccessorySessionError:UUAccessorySessionErrorCodeNoDeviceFoundReadDataTimeout];
    
    if (self.readDataCallback)
    {
        UUAccessoryReadDataCallback callback = self.readDataCallback;
        self.readDataCallback = nil;
        callback(error, nil);
    }
}

- (void) registerPushedDataCallback:(UUAccessoryPushedDataCallback)callback
{
    self.pushDataCallback = callback;
}

- (void) invokeBlock:(NSError*)err completion:(void (^)(NSError* error))completion
{
    if (completion)
    {
        dispatch_async(dispatch_get_main_queue(),
        ^{
            completion(err);
        });
    }
}

- (NSError*) setupSession:(EAAccessory*)accessory
{
    if (self.discoveredAccessory == accessory &&
        self.currentSession &&
        self.sessionRunLoop)
    {
        UUDebugLog(@"Session already active with accessory");
        return nil;
    }
    
    self.discoveredAccessory = accessory;
    
    NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
    self.sessionRunLoop = runLoop;
    
    EASession* session = [[EASession alloc] initWithAccessory:accessory forProtocol:self.protocol];
    if (session == nil)
    {
        UUDebugLog(@"Unable to connect to accessory");
        return [NSError uuAccessorySessionError:UUAccessorySessionErrorCodeUnableToCreateAccessory];
    }
    
    NSInputStream* is = [session inputStream];
    if (is == nil)
    {
        UUDebugLog(@"Unable to acquire input stream");
        return [NSError uuAccessorySessionError:UUAccessorySessionErrorCodeUnableToAcquireInputStream];
    }
    
    [is setDelegate:self];
    [is scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];
    [is open];
    
    if ([is streamStatus] != NSStreamStatusOpen)
    {
        UUDebugLog(@"Unable to open input stream");
        return [NSError uuAccessorySessionError:UUAccessorySessionErrorCodeUnableToOpenInputStream];
    }
    
    NSOutputStream* os = [session outputStream];
    if (os == nil)
    {
        UUDebugLog(@"Unable to acquire output stream");
        return [NSError uuAccessorySessionError:UUAccessorySessionErrorCodeUnableToAcquireOutputStream];
    }
    
    [os setDelegate:self];
    [os scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];
    [os open];
    
    if ([os streamStatus] != NSStreamStatusOpen)
    {
        return [NSError uuAccessorySessionError:UUAccessorySessionErrorCodeUnableToOpenOutputStream];
    }
    
    self.currentSession = session;
    
    return nil;
}

- (void) receiveDataFromStream:(NSInputStream*)inputStream
{
    if (inputStream != nil)
    {
        uint8_t buf[1024];
        
        if (!self.rxBuffer)
        {
            self.rxBuffer = [NSMutableData data];
        }
        
        while ([inputStream hasBytesAvailable])
        {
            memset(buf, 0, sizeof(buf));
            NSUInteger result = [inputStream read:buf maxLength:sizeof(buf)];
            UUDebugLog(@"read result: %d", (int)result);
            if (result > 0)
            {
                UUDebugLog(@"RXChunk: %@", [NSString uuHexStringFromData:[NSData dataWithBytes:buf length:result]]);
                
                if ([self notifyPushedRxData:buf length:result])
                {
                    UUDebugLog(@"Sent data to pushed callback");
                    continue;
                }
                
                if (self.readDataCallback)
                {
                    @synchronized(self.rxBuffer)
                    {
                        [self.rxBuffer appendBytes:buf length:result];
                    }
                    
                    UUDebugLog(@"RxBuffer Length: %@", @(self.rxBuffer.length));
                    
                    [self notifyRxData];
                }
            }
        }
    }
}

- (BOOL) notifyPushedRxData:(uint8_t*)buffer length:(NSUInteger)length
{
    if (self.readDataCallback == nil && self.pushDataCallback != nil && buffer != nil && length > 0)
    {
        NSData* tmp = [NSData dataWithBytes:buffer length:length];
        self.pushDataCallback(tmp);
        return YES;
    }
    else
    {
        return NO;
    }
}

- (void) notifyRxData
{
    UUDebugLog(@"ReadDataCount: %@, ReadDataCallback: %@", @(self.readDataCount), self.readDataCallback);
    
    if (self.readDataCallback && self.readDataCount > 0)
    {
        [self kickReadDataWatchdog];
        
        NSData* data = nil;
        
        @synchronized(self.rxBuffer)
        {
            if (self.rxBuffer.length >= self.readDataCount)
            {
                UUDebugLog(@"Received enough bytes, copying data for notify");
                NSRange range = NSMakeRange(0, self.readDataCount);
                data = [self.rxBuffer subdataWithRange:range];
                [self.rxBuffer replaceBytesInRange:range withBytes:NULL length:0];
            }
            else
            {
                UUDebugLog(@"Have not received enough bytes");
            }
        }
        
        if (data != nil)
        {
            UUDebugLog(@"Calling read callback with %@ bytes", @(data.length));
            [self cancelReadDataWatchdog];
            
            UUAccessoryReadDataCallback callback = self.readDataCallback;
            self.readDataCallback = nil;
            callback(nil, data);
        }
    }
}

- (void)queueData:(NSData*)data
{
    @synchronized(self.txQueue)
    {
        [self.txQueue addObject:data];
    }
    
    if (self.rxBuffer)
    {
        @synchronized (self.rxBuffer)
        {
            [self.rxBuffer setLength:0];
        }
    }

    // If there is space available, send immediately
    if ([[self.currentSession outputStream] hasSpaceAvailable])
    {
        [self sendDataFromQueue:[self.currentSession outputStream]];
    }
}

- (void) sendDataFromQueue:(NSOutputStream*)outputStream
{
    if (outputStream != nil)
    {
        NSData* data = nil;
        
        @synchronized(self.txQueue)
        {
            UUDebugLog(@"TXQueue has %@ items", @(self.txQueue.count));
            
            if (self.txQueue.count > 0)
            {
                data = self.txQueue[0];
            }
        }
        
        if (data != nil)
        {
            UUDebugLog(@"TX: %@", [data uuToHexString]);
            NSInteger result = [outputStream write:[data bytes] maxLength:data.length];
            UUDebugLog(@"sendFrameFromQueue, write result: %@", @(result));
            
            if (result == data.length)
            {
                @synchronized(self.txQueue)
                {
                    if (self.txQueue.count > 0)
                    {
                        [self.txQueue removeObjectAtIndex:0];
                    }
                }
            }
            else
            {
                // FAILED to send all bytes!
            }
        }
    }
}

- (void)stream:(NSStream*)theStream handleEvent:(NSStreamEvent)streamEvent
{
    UUDebugLog(@"Received stream event: %d (%@) from stream %@", (int)streamEvent, [self streamEventToString:streamEvent], [theStream class]);
    
    switch (streamEvent)
    {
        case NSStreamEventHasBytesAvailable:
            [self receiveDataFromStream:(NSInputStream*)theStream];
            break;
            
        case NSStreamEventHasSpaceAvailable:
            [self sendDataFromQueue:(NSOutputStream*)theStream];
            break;
            
        default:
            break;
    }
}

- (void) disconnect
{
    UUDebugLog(@"disconnecting from accessory...");
    
    EASession* session = self.currentSession;
    NSRunLoop* runLoop = self.sessionRunLoop;
    
    if (session != nil)
    {
        UUDebugLog(@"EASession is not null, shutting it down");
        [[session inputStream] close];
        [[session inputStream] removeFromRunLoop:runLoop forMode:NSDefaultRunLoopMode];
        [[session inputStream] setDelegate:nil];
        
        [[session outputStream] close];
        [[session outputStream] removeFromRunLoop:runLoop forMode:NSDefaultRunLoopMode];
        [[session outputStream] setDelegate:nil];
    }
    
    self.sessionRunLoop = nil;
    self.currentSession = nil;
    self.discoveredAccessory.delegate = nil;
    self.discoveredAccessory = nil;
    self.rxBuffer = nil;
    [self.txQueue removeAllObjects];
}

#pragma mark - EAAccessoryDelegate Methods

- (void)accessoryDidDisconnect:(EAAccessory *)accessory
{
    UUDebugLog(@"Accessory Did Disconnect -- %@", accessory);
    [self disconnect];
}

#pragma mark - Notification Handling

- (void) handleAccessoryConnected:(NSNotification*)sender
{
    UUDebugLog(@"Accessory did connect");
    
    EAAccessory* accessory = [sender.userInfo valueForKey:EAAccessoryKey];
    if (accessory)
    {
        [self logAccessory:accessory];
        
        if (self.connectCallback)
        {
            if ([accessory.protocolStrings containsObject:self.protocol])
            {
                NSError* err = [self setupSession:accessory];
                UUDebugLog(@"Setup Session returned %@", err);
                
                self.connectCallback(err);
                self.connectCallback = nil;
            }
        }
        else
        {
            UUDebugLog(@"Connect callback is nil");
        }
    }
}

- (void) handleAccessoryDisconnected:(NSNotification*)sender
{
    UUDebugLog(@"Accessory did disconnect");
    
    EAAccessory* accessory = [sender.userInfo valueForKey:EAAccessoryKey];
    if (accessory == self.discoveredAccessory)
    {
        UUDebugLog(@"Discovered Accessory disconnected, cleaning up");
        [self disconnect];
    }
}

#pragma mark - String Helpers

- (NSString*) streamEventToString:(NSStreamEvent)streamEvent
{
    switch (streamEvent)
    {
        case NSStreamEventNone: return @"None";
        case NSStreamEventOpenCompleted: return @"OpenCompleted";
        case NSStreamEventHasBytesAvailable: return @"HasBytesAvailable";
        case NSStreamEventHasSpaceAvailable: return @"HasSpaceAvailable";
        case NSStreamEventErrorOccurred: return @"ErrorOccurred";
        case NSStreamEventEndEncountered: return @"EndEncountered";
    }
    
    return [NSString stringWithFormat:@"%d", (int)streamEvent];
}

- (NSString*) streamStatusToString:(NSStreamStatus)streamStatus
{
    switch (streamStatus)
    {
        case NSStreamStatusNotOpen: return @"NotOpen";
        case NSStreamStatusOpening: return @"Opening";
        case NSStreamStatusOpen: return @"Open";
        case NSStreamStatusReading: return @"Reading";
        case NSStreamStatusWriting: return @"Writing";
        case NSStreamStatusAtEnd: return @"AtEnd";
        case NSStreamStatusClosed: return @"Closed";
        case NSStreamStatusError: return @"Error";
    };
    
    return [NSString stringWithFormat:@"%d", (int)streamStatus];
}

- (NSString*) pickerCodeToString:(EABluetoothAccessoryPickerErrorCode)code
{
    switch (code)
    {
        case EABluetoothAccessoryPickerAlreadyConnected: return @"AlreadyConnected";
        case EABluetoothAccessoryPickerResultNotFound: return @"NotFound";
        case EABluetoothAccessoryPickerResultCancelled: return @"Cancelled";
        case EABluetoothAccessoryPickerResultFailed: return @"Failed";
        default: return [NSString stringWithFormat:@"%d", (int)code];
    }
}

- (void) logAccessory:(EAAccessory*)accessory
{
    UUDebugLog(@"---- %@ ----", [accessory class]);
    
    UUDebugLog(@"    ConnectionID: %@", @(accessory.connectionID));
    UUDebugLog(@"    Manufacturer: %@", accessory.manufacturer);
    UUDebugLog(@"            Name: %@", accessory.name);
    UUDebugLog(@"     ModelNumber: %@", accessory.modelNumber);
    UUDebugLog(@"    SerialNumber: %@", accessory.serialNumber);
    UUDebugLog(@"FirmwareRevision: %@", accessory.firmwareRevision);
    UUDebugLog(@"HardwareRevision: %@", accessory.hardwareRevision);
    
    if (accessory.protocolStrings != nil)
    {
        for (int i = 0; i < accessory.protocolStrings.count; i++)
        {
            UUDebugLog(@"     Protocol_%d: %@", i, [accessory.protocolStrings objectAtIndex:i]);
        }
    }
}




@end




@implementation NSError (UUAccessorySession)

+ (instancetype) uuAccessorySessionError:(UUAccessorySessionErrorCode)code
{
    return [self uuAccessorySessionError:code inner:nil];
}

+ (instancetype) uuAccessorySessionError:(UUAccessorySessionErrorCode)code inner:(NSError*)inner
{
    NSMutableDictionary* md = [NSMutableDictionary dictionary];
    [md setValue:inner forKey:NSUnderlyingErrorKey];
    [md setValue:[self textForError:code] forKey:NSLocalizedDescriptionKey];
    [md setValue:[self resolutionForError:code] forKey:NSLocalizedRecoverySuggestionErrorKey];
    
    return [self errorWithDomain:kUUAccessorySessionErrorDomain code:code userInfo:md];
}

+ (NSString*) textForError:(UUAccessorySessionErrorCode)code
{
    switch (code)
    {
        case UUAccessorySessionErrorCodeBluetoothPickerError:
            return @"Bluetooth Picker Error";
            
        case UUAccessorySessionErrorCodeUnableToCreateAccessory:
            return @"Unable to create EAAccessory object";
            
        case UUAccessorySessionErrorCodeUnableToAcquireInputStream:
            return @"Failed to create input stream";
            
        case UUAccessorySessionErrorCodeUnableToOpenInputStream:
            return @"Failed to open input stream";
            
        case UUAccessorySessionErrorCodeUnableToAcquireOutputStream:
            return @"Failed to create output stream";
            
        case UUAccessorySessionErrorCodeUnableToOpenOutputStream:
            return @"Failed to open output stream";
            
        case UUAccessorySessionErrorCodeNoDeviceFound:
            return @"No devices found";
            
        case UUAccessorySessionErrorCodeNoDeviceFoundReadDataTimeout:
            return @"Read timeout";
            
        default:
            return [NSString stringWithFormat:@"UUAccessorySessionErrorCode_%@", @(code)];
    }
}

+ (NSString*) resolutionForError:(UUAccessorySessionErrorCode)code
{
    switch (code)
    {
        case UUAccessorySessionErrorCodeNoDeviceFound:
            return @"Turn on the device and try again";
            
        case UUAccessorySessionErrorCodeBluetoothPickerError:
        case UUAccessorySessionErrorCodeUnableToCreateAccessory:
        case UUAccessorySessionErrorCodeUnableToAcquireInputStream:
        case UUAccessorySessionErrorCodeUnableToOpenInputStream:
        case UUAccessorySessionErrorCodeUnableToAcquireOutputStream:
        case UUAccessorySessionErrorCodeUnableToOpenOutputStream:
        case UUAccessorySessionErrorCodeNoDeviceFoundReadDataTimeout:
        default:
            return nil;
    }
}

@end
