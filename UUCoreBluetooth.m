//
//  UUCoreBluetooth.m
//  Useful Utilities - CoreBluetooth wrapper to make scanning and connecting eaiser
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only
//  requirement is that you smile everytime you use it.
//

#import "UUCoreBluetooth.h"
#import "UUDictionary.h"
#import "UUTimer.h"
#import "UUString.h"
#import "UUMacros.h"
#import "UUData.h"

#ifndef UUCoreBluetoothLog
#ifdef DEBUG
#define UUCoreBluetoothLog(fmt, ...) UUDebugLog(fmt, ##__VA_ARGS__)
#else
#define UUCoreBluetoothLog(fmt, ...)
#endif
#endif

@import CoreBluetooth;

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Constants
////////////////////////////////////////////////////////////////////////////////

const char * _Nonnull const kUUCoreBluetoothQueueName = "UUCoreBluetoothQueue";

NSString * _Nonnull const kUUCoreBluetoothErrorDomain = @"UUCoreBluetoothErrorDomain";
NSTimeInterval const kUUCoreBluetoothTimeoutDisabled = -1;

NSString * _Nonnull const kUUCoreBluetoothConnectWatchdogBucket = @"UUCoreBluetoothConnectWatchdogBucket";
NSString * _Nonnull const kUUCoreBluetoothServiceDiscoveryWatchdogBucket = @"UUCoreBluetoothServiceDiscoveryWatchdogBucket";
NSString * _Nonnull const kUUCoreBluetoothCharacteristicDiscoveryWatchdogBucket = @"UUCoreBluetoothCharacteristicDiscoveryWatchdogBucket";
NSString * _Nonnull const kUUCoreBluetoothIncludedServicesDiscoveryWatchdogBucket = @"UUCoreBluetoothIncludedServicesDiscoveryWatchdogBucket";
NSString * _Nonnull const kUUCoreBluetoothDescriptorDiscoveryWatchdogBucket = @"UUCoreBluetoothDescriptorDiscoveryWatchdogBucket";
NSString * _Nonnull const kUUCoreBluetoothCharacteristicNotifyStateWatchdogBucket = @"UUCoreBluetoothCharacteristicNotifyStateWatchdogBucket";
NSString * _Nonnull const kUUCoreBluetoothReadCharacteristicValueWatchdogBucket = @"UUCoreBluetoothReadCharacteristicValueWatchdogBucket";
NSString * _Nonnull const kUUCoreBluetoothWriteCharacteristicValueWatchdogBucket = @"UUCoreBluetoothWriteCharacteristicValueWatchdogBucket";
NSString * _Nonnull const kUUCoreBluetoothReadRssiWatchdogBucket = @"UUCoreBluetoothReadRssiWatchdogBucket";
NSString * _Nonnull const kUUCoreBluetoothPollRssiBucket = @"UUCoreBluetoothPollRssiBucket";
NSString * _Nonnull const kUUCoreBluetoothDisconnectWatchdogBucket = @"UUCoreBluetoothDisconnectWatchdogBucket";


////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSError (UUCoreBluetooth)
////////////////////////////////////////////////////////////////////////////////

@interface NSError (UUCoreBluetooth)

+ (instancetype) uuCoreBluetoothError:(UUCoreBluetoothErrorCode)errorCode;
+ (instancetype) uuCoreBluetoothError:(UUCoreBluetoothErrorCode)errorCode inner:(nonnull NSError*)inner;
+ (instancetype) uuCoreBluetoothError:(UUCoreBluetoothErrorCode)errorCode userInfo:(nullable NSDictionary*)userInfo;

@end

@implementation NSError (UUCoreBluetooth)

+ (instancetype) uuCoreBluetoothError:(UUCoreBluetoothErrorCode)errorCode
{
    return [self uuCoreBluetoothError:errorCode userInfo:nil];
}

+ (instancetype) uuCoreBluetoothError:(UUCoreBluetoothErrorCode)errorCode inner:(nonnull NSError*)inner
{
    return [self uuCoreBluetoothError:errorCode userInfo:@{ NSUnderlyingErrorKey : inner }];
}

+ (instancetype) uuCoreBluetoothError:(UUCoreBluetoothErrorCode)errorCode userInfo:(NSDictionary*)userInfo
{
    NSMutableDictionary* md = [NSMutableDictionary dictionary];
    [md setValue:[self errorDecriptionForCode:errorCode] forKey:NSLocalizedDescriptionKey];
    [md setValue:[self recoverySuggestionForCode:errorCode] forKey:NSLocalizedRecoverySuggestionErrorKey];
    
    if (userInfo)
    {
        [md addEntriesFromDictionary:userInfo];
    }
    
    return [NSError errorWithDomain:kUUCoreBluetoothErrorDomain code:errorCode userInfo:md];
}

+ (nonnull instancetype) uuOperationCompleteError:(NSError*)error
{
    if (error == nil)
    {
        return nil;
    }
    else if ([kUUCoreBluetoothErrorDomain isEqualToString:error.domain])
    {
        return error;
    }
    else
    {
        return [self uuCoreBluetoothError:UUCoreBluetoothErrorCodeOperationFailed inner:error];
    }
}

+ (nonnull instancetype) uuConnectionFailedError:(NSError*)error
{
    if (error)
    {
        return [self uuCoreBluetoothError:UUCoreBluetoothErrorCodeConnectionFailed inner:error];
    }
    else
    {
        return nil;
    }
}

+ (nonnull instancetype) uuDisconnectedError:(NSError*)error
{
    if (error)
    {
        return [self uuCoreBluetoothError:UUCoreBluetoothErrorCodeDisconnected inner:error];
    }
    else
    {
        return nil;
    }
}

+ (nonnull instancetype) uuInvalidParamError:(nonnull NSString*)param reason:(nonnull NSString*)reason
{
    NSMutableDictionary* md = [NSMutableDictionary dictionary];
    [md setValue:param forKey:@"param"];
    [md setValue:reason forKey:@"reason"];
    
    return [self uuCoreBluetoothError:UUCoreBluetoothErrorCodeInvalidParam userInfo:md];
}

+ (nonnull instancetype) uuExpectNonNilParamError:(nonnull NSString*)param
{
    NSString* reason = [NSString stringWithFormat:@"%@ must not be nil.", param];
    return [self uuInvalidParamError:param reason:reason];
}

+ (NSString*) errorDecriptionForCode:(UUCoreBluetoothErrorCode)errorCode
{
    switch (errorCode)
    {
        case UUCoreBluetoothErrorCodeTimeout:
            return @"Timeout";
            
        case UUCoreBluetoothErrorCodeNotConnected:
            return @"NotConnected";
            
        case UUCoreBluetoothErrorCodeOperationFailed:
            return @"OperationFailed";
            
        case UUCoreBluetoothErrorCodeConnectionFailed:
            return @"ConnectionFailed";
            
        case UUCoreBluetoothErrorCodeDisconnected:
            return @"Disconnected";
            
        case UUCoreBluetoothErrorCodeInvalidParam:
            return @"InvalidParam";
            
        case UUCoreBluetoothErrorCodeCentralNotReady:
            return @"CentralNotReady";
            
        default:
            return [NSString stringWithFormat:@"UUCoreBluetoothErrorCode-%@", @(errorCode)];
    }
}

+ (NSString*) recoverySuggestionForCode:(UUCoreBluetoothErrorCode)errorCode
{
    switch (errorCode)
    {
        case UUCoreBluetoothErrorCodeTimeout:
            return @"Make sure the peripheral is connected and in range, and try again.";
            
        case UUCoreBluetoothErrorCodeNotConnected:
            return @"Connect to the peripheral and try the operation again.";
            
        case UUCoreBluetoothErrorCodeOperationFailed:
            return @"Inspect inner error for more details.";
            
        case UUCoreBluetoothErrorCodeConnectionFailed:
            return @"Connection attempt failed.";
            
        case UUCoreBluetoothErrorCodeDisconnected:
            return @"Peripheral disconnected.";
            
        case UUCoreBluetoothErrorCodeInvalidParam:
            return @"An invalid parameter was passed in.";
            
        case UUCoreBluetoothErrorCodeCentralNotReady:
            return @"Core Bluetooth is not ready to accept commands.";
            
            
        default:
            return @"";
    }
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - UUCoreBluetooth - C Helper Methods
////////////////////////////////////////////////////////////////////////////////

NSString* _Nonnull UUCBManagerStateToString(CBManagerState state)
{
    switch (state)
    {
        case CBManagerStateUnknown:
            return @"Unknown";
            
        case CBManagerStateResetting:
            return @"Resetting";
            
        case CBManagerStateUnsupported:
            return @"Unsupported";
            
        case CBManagerStateUnauthorized:
            return @"Unauthorized";
            
        case CBManagerStatePoweredOff:
            return @"PoweredOff";
            
        case CBManagerStatePoweredOn:
            return @"PoweredOn";
            
        default:
            return [NSString stringWithFormat:@"CBManagerState-%@", @(state)];
    }
}

NSString* _Nonnull UUCBPeripheralStateToString(CBPeripheralState state)
{
    switch (state)
    {
        case CBPeripheralStateDisconnected:
            return @"Disconnected";
            
        case CBPeripheralStateConnecting:
            return @"Connecting";
            
        case CBPeripheralStateConnected:
            return @"Connected";
            
        case CBPeripheralStateDisconnecting:
            return @"Disconnecting";
            
        default:
            return [NSString stringWithFormat:@"CBPeripheralState-%@", @(state)];
    }
}

BOOL UUIsCBCharacteristicPropertySet(CBCharacteristicProperties props, CBCharacteristicProperties check)
{
    return ((props & check) == check);
}

NSString* _Nonnull UUCBCharacteristicPropertiesToString(CBCharacteristicProperties props)
{
    NSMutableArray* parts = [NSMutableArray array];
    
    if (UUIsCBCharacteristicPropertySet(props, CBCharacteristicPropertyBroadcast))
    {
        [parts addObject:@"Broadcast"];
    }
    
    if (UUIsCBCharacteristicPropertySet(props, CBCharacteristicPropertyRead))
    {
        [parts addObject:@"Read"];
    }
    
    if (UUIsCBCharacteristicPropertySet(props, CBCharacteristicPropertyWriteWithoutResponse))
    {
        [parts addObject:@"WriteWithoutResponse"];
    }
    
    if (UUIsCBCharacteristicPropertySet(props, CBCharacteristicPropertyWrite))
    {
        [parts addObject:@"Write"];
    }
    
    if (UUIsCBCharacteristicPropertySet(props, CBCharacteristicPropertyNotify))
    {
        [parts addObject:@"Notify"];
    }
    
    if (UUIsCBCharacteristicPropertySet(props, CBCharacteristicPropertyIndicate))
    {
        [parts addObject:@"Indicate"];
    }
    
    if (UUIsCBCharacteristicPropertySet(props, CBCharacteristicPropertyAuthenticatedSignedWrites))
    {
        [parts addObject:@"AuthenticatedSignedWrites"];
    }
    
    if (UUIsCBCharacteristicPropertySet(props, CBCharacteristicPropertyExtendedProperties))
    {
        [parts addObject:@"ExtendedProperties"];
    }
    if (UUIsCBCharacteristicPropertySet(props, CBCharacteristicPropertyNotifyEncryptionRequired))
    {
        [parts addObject:@"NotifyEncryptionRequired"];
    }
    
    if (UUIsCBCharacteristicPropertySet(props, CBCharacteristicPropertyIndicateEncryptionRequired))
    {
        [parts addObject:@"IndicateEncryptionRequired"];
    }
    
    return [parts componentsJoinedByString:@", "];
}

dispatch_queue_t UUCoreBluetoothQueue()
{
    static dispatch_queue_t theSharedCoreBluetoothQueue = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once (&onceToken, ^
    {
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0);
        theSharedCoreBluetoothQueue = dispatch_queue_create(kUUCoreBluetoothQueueName, attr);
    });
    
    return theSharedCoreBluetoothQueue;
    
    
}

////////////////////////////////////////////////////////////////////////////////
// UUPeripheral
////////////////////////////////////////////////////////////////////////////////

@interface UUPeripheral ()

@property (nonnull, nonatomic, strong, readwrite) CBPeripheral* peripheral;
@property (nonnull, nonatomic, strong, readwrite) NSDictionary<NSString*, id>* advertisementData;
@property (nonnull, nonatomic, strong, readwrite) NSNumber* rssi;
@property (nonnull, nonatomic, strong, readwrite) NSDate* firstAdvertisementTime;
@property (nonnull, nonatomic, strong, readwrite) NSDate* lastAdvertisementTime;
@property (nonnull, nonatomic, strong, readwrite) NSDate* lastRssiUpdateTime;

@end

@implementation UUPeripheral

- (void) parseManufacturingData
{
    
}

- (void) updateFromScan:(nonnull CBPeripheral*)peripheral
      advertisementData:(nullable NSDictionary<NSString*, id>* )advertisementData
                   rssi:(nullable NSNumber*)rssi
{
    self.peripheral = peripheral;
    self.advertisementData = advertisementData;
    
    NSDate* now = [NSDate date];
    if (self.firstAdvertisementTime == nil)
    {
        self.firstAdvertisementTime = now;
    }
    
    self.lastAdvertisementTime = now;
    
    [self updateRssi:rssi];
    [self parseManufacturingData];
}

- (void) updateRssi:(nonnull NSNumber*)rssi
{
    // Per CoreBluetooth documentation, a value of 127 indicates the RSSI
    // reading is not available
    if (rssi.integerValue != 127)
    {
        self.rssi = rssi;
        self.lastRssiUpdateTime = [NSDate date];
    }
}

- (nonnull NSString*) identifier
{
    return [self.peripheral.identifier UUIDString];
}

- (nullable NSString*) name
{
    return self.peripheral.name;
}

- (CBPeripheralState) peripheralState
{
    return self.peripheral.state;
}

- (BOOL) isConnectable
{
    return [[self.advertisementData uuSafeGetNumber:CBAdvertisementDataIsConnectable defaultValue:@(NO)] boolValue];
}

- (nullable NSData*) manufacturingData
{
    return [self.advertisementData uuSafeGetData:CBAdvertisementDataManufacturerDataKey];
}

@end


////////////////////////////////////////////////////////////////////////////////
// Common Filters
////////////////////////////////////////////////////////////////////////////////
@implementation UURssiPeripheralFilter

+ (nonnull instancetype) filterWithRssi:(nonnull NSNumber*)rssiThreshold
{
    UURssiPeripheralFilter* filter = [UURssiPeripheralFilter new];
    filter.rssiThreshold = rssiThreshold;
    return filter;
}

- (BOOL) shouldDiscoverPeripheral:(nonnull UUPeripheral*)peripheral
{
    return (peripheral.rssi.integerValue > self.rssiThreshold.integerValue);
}

@end


////////////////////////////////////////////////////////////////////////////////
#pragma mark - UUPeripheralDelegate
////////////////////////////////////////////////////////////////////////////////

@interface UUPeripheralDelegate : NSObject<CBPeripheralDelegate>

@end

@interface UUPeripheralDelegate ()

@property (nonnull, nonatomic, strong, readwrite) CBPeripheral* peripheral;

@property (nullable, copy, readwrite) UUPeripheralNameUpdatedBlock peripheralNameUpdatedBlock;
@property (nullable, copy, readwrite) UUDidModifyServicesBlock didModifyServicesBlock;
@property (nullable, copy, readwrite) UUDidReadRssiBlock didReadRssiBlock;
@property (nullable, copy, readwrite) UUDiscoverServicesBlock discoverServicesBlock;
@property (nullable, copy, readwrite) UUDiscoverIncludedServicesBlock discoverIncludedServicesBlock;
@property (nullable, copy, readwrite) UUDiscoverCharacteristicsBlock discoverCharacteristicsBlock;
@property (nullable, nonatomic, strong, readwrite) NSMutableDictionary<NSString*, UUUpdateValueForCharacteristicsBlock>* updateValueForCharacteristicBlocks;
@property (nullable, nonatomic, strong, readwrite) NSMutableDictionary<NSString*, UUUpdateValueForCharacteristicsBlock>* readValueForCharacteristicBlocks;
@property (nullable, nonatomic, strong, readwrite) NSMutableDictionary<NSString*, UUWriteValueForCharacteristicsBlock>* writeValueForCharacteristicBlocks;
@property (nullable, copy, readwrite) UUSetNotifyValueForCharacteristicsBlock setNotifyValueForCharacteristicBlock;
@property (nullable, copy, readwrite) UUDiscoverDescriptorsBlock discoverDescriptorsBlock;
@property (nullable, copy, readwrite) UUUpdateValueForDescriptorBlock updateValueForDescriptorBlock;
@property (nullable, copy, readwrite) UUWriteValueForDescriptorBlock writeValueForDescriptorBlock;

@end

@implementation UUPeripheralDelegate

- (nonnull id) initWithPeripheral:(nonnull CBPeripheral*)peripheral
{
    self = [super init];
    
    if (self)
    {
        self.peripheral = peripheral;
        peripheral.delegate = self;
        
        self.updateValueForCharacteristicBlocks = [NSMutableDictionary dictionary];
        self.readValueForCharacteristicBlocks = [NSMutableDictionary dictionary];
        self.writeValueForCharacteristicBlocks = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)registerUpdateHandler:(nullable UUUpdateValueForCharacteristicsBlock)handler
            forCharacteristic:(nonnull CBCharacteristic*)characteristic
{
    [self.updateValueForCharacteristicBlocks uuSafeSetValue:handler forKey:[[characteristic UUID] UUIDString]];
}

- (void)removeUpdateHandlerForCharacteristic:(nonnull CBCharacteristic*)characteristic
{
    [self.updateValueForCharacteristicBlocks uuSafeRemove:[[characteristic UUID] UUIDString]];
}

- (void)registerReadHandler:(nullable UUReadValueForCharacteristicsBlock)handler
            forCharacteristic:(nonnull CBCharacteristic*)characteristic
{
    [self.readValueForCharacteristicBlocks uuSafeSetValue:handler forKey:[[characteristic UUID] UUIDString]];
}

- (void)removeReadHandlerForCharacteristic:(nonnull CBCharacteristic*)characteristic
{
    [self.readValueForCharacteristicBlocks uuSafeRemove:[[characteristic UUID] UUIDString]];
}

- (void)registerWriteHandler:(nullable UUWriteValueForCharacteristicsBlock)handler
          forCharacteristic:(nonnull CBCharacteristic*)characteristic
{
    [self.writeValueForCharacteristicBlocks uuSafeSetValue:handler forKey:[[characteristic UUID] UUIDString]];
}

- (void)removeWriteHandlerForCharacteristic:(nonnull CBCharacteristic*)characteristic
{
    [self.writeValueForCharacteristicBlocks uuSafeRemove:[[characteristic UUID] UUIDString]];
}

- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral
{
    if (self.peripheralNameUpdatedBlock)
    {
        self.peripheralNameUpdatedBlock(peripheral);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices
{
    if (self.didModifyServicesBlock)
    {
        self.didModifyServicesBlock(peripheral, invalidatedServices);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
       didReadRSSI:(NSNumber *)RSSI
             error:(nullable NSError *)error
{
    UUDidReadRssiBlock block = self.didReadRssiBlock;
    self.didReadRssiBlock = nil;
    if (block)
    {
        block(peripheral, RSSI, error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error
{
    UUDiscoverServicesBlock block = self.discoverServicesBlock;
    self.discoverServicesBlock = nil;
    if (block)
    {
        block(peripheral, error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(nullable NSError *)error
{
    UUDiscoverIncludedServicesBlock block = self.discoverIncludedServicesBlock;
    self.discoverIncludedServicesBlock = nil;
    if (block)
    {
        block(peripheral, service, error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error
{
    UUDiscoverCharacteristicsBlock block = self.discoverCharacteristicsBlock;
    self.discoverCharacteristicsBlock = nil;
    if (block)
    {
        block(peripheral, service, error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    UUUpdateValueForCharacteristicsBlock updateBlock = [self.updateValueForCharacteristicBlocks uuSafeGet:[characteristic.UUID UUIDString]];
    if (updateBlock)
    {
        updateBlock(peripheral, characteristic, error);
    }
    
    UUReadValueForCharacteristicsBlock readBlock = [self.readValueForCharacteristicBlocks uuSafeGet:[characteristic.UUID UUIDString]];
    if (readBlock)
    {
        readBlock(peripheral, characteristic, error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    UUWriteValueForCharacteristicsBlock writeBlock = [self.writeValueForCharacteristicBlocks uuSafeGet:[characteristic.UUID UUIDString]];
    if (writeBlock)
    {
        writeBlock(peripheral, characteristic, error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    UUSetNotifyValueForCharacteristicsBlock block = self.setNotifyValueForCharacteristicBlock;
    self.setNotifyValueForCharacteristicBlock = nil;
    if (block)
    {
        block(peripheral, characteristic, error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    UUDiscoverDescriptorsBlock block = self.discoverDescriptorsBlock;
    self.discoverDescriptorsBlock = nil;
    if (block)
    {
        block(peripheral, characteristic, error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error
{
    if (self.updateValueForDescriptorBlock)
    {
        self.updateValueForDescriptorBlock(peripheral, descriptor, error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error
{
    UUWriteValueForDescriptorBlock block = self.writeValueForDescriptorBlock;
    self.writeValueForDescriptorBlock = nil;
    if (block)
    {
        block(peripheral, descriptor, error);
    }
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - CBCharacteristic (UUCoreBluetooth)
////////////////////////////////////////////////////////////////////////////////

@implementation CBCharacteristic (UUCoreBluetooth)

- (BOOL) uuCanToggleNotify
{
    return (UUIsCBCharacteristicPropertySet(self.properties, CBCharacteristicPropertyNotify) ||
            UUIsCBCharacteristicPropertySet(self.properties, CBCharacteristicPropertyIndicate));
}

- (BOOL) uuCanReadData
{
    return UUIsCBCharacteristicPropertySet(self.properties, CBCharacteristicPropertyRead);
}

- (BOOL) uuCanWriteData
{
    return UUIsCBCharacteristicPropertySet(self.properties, CBCharacteristicPropertyWrite);
}

- (BOOL) uuCanWriteWithoutResponse
{
    return UUIsCBCharacteristicPropertySet(self.properties, CBCharacteristicPropertyWriteWithoutResponse);
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSUUID (UUCoreBluetooth)
////////////////////////////////////////////////////////////////////////////////

@implementation CBUUID (UUCoreBluetooth)

- (nonnull NSString*) uuCommonName
{
    NSString* name = [NSString stringWithFormat:@"%@", self];
    NSString* uuid = [self UUIDString];
    if ([name isEqualToString:uuid])
    {
        return @"Unknown";
    }
    else
    {
        return name;
    }
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - CBPeripheral (UUCoreBluetooth)
////////////////////////////////////////////////////////////////////////////////

@implementation CBPeripheral (UUCoreBluetooth)

- (nonnull NSString*) uuIdentifier
{
    return [self.identifier UUIDString];
}

+ (nonnull NSMutableDictionary<NSString*, UUPeripheralDelegate*>*) uuSharedDelegates
{
    static NSMutableDictionary* theSharedDelegatesDictionary = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once (&onceToken, ^
    {
        theSharedDelegatesDictionary = [NSMutableDictionary dictionary];
    });
    
    return theSharedDelegatesDictionary;
}

+ (nonnull UUPeripheralDelegate*) uuDelegateForPeripheral:(nonnull CBPeripheral*)peripheral
{
    UUPeripheralDelegate* delegate = [[self uuSharedDelegates] uuSafeGet:peripheral.uuIdentifier forClass:[UUPeripheralDelegate class]];
    if (!delegate)
    {
        delegate = [[UUPeripheralDelegate alloc] initWithPeripheral:peripheral];
        [self addDelegate:delegate];
    }
    
    return delegate;
}

+ (void) addDelegate:(nonnull UUPeripheralDelegate*)delegate
{
    NSMutableDictionary* d = [self uuSharedDelegates];
    
    @synchronized (d)
    {
        [d uuSafeSetValue:delegate forKey:delegate.peripheral.uuIdentifier];
    }
}

+ (void) removeDelegate:(nonnull UUPeripheralDelegate*)delegate
{
    NSMutableDictionary* d = [self uuSharedDelegates];
    
    @synchronized (d)
    {
        [d uuSafeRemove:delegate.peripheral.uuIdentifier];
    }
}

- (nonnull NSString*) formatTimerId:(nonnull NSString*)bucket
{
    return [NSString stringWithFormat:@"%@__%@", self.uuIdentifier, bucket];
}

- (nonnull NSString*) uuConnectWatchdogTimerId
{
    return [self formatTimerId:kUUCoreBluetoothConnectWatchdogBucket];
}

- (nonnull NSString*) uuDisconnectWatchdogTimerId
{
    return [self formatTimerId:kUUCoreBluetoothDisconnectWatchdogBucket];
}

- (nonnull NSString*) uuServiceDiscoveryWatchdogTimerId
{
    return [self formatTimerId:kUUCoreBluetoothServiceDiscoveryWatchdogBucket];
}

- (nonnull NSString*) uuCharacteristicDiscoveryWatchdogTimerId
{
    return [self formatTimerId:kUUCoreBluetoothCharacteristicDiscoveryWatchdogBucket];
}

- (nonnull NSString*) uuIncludedServicesDiscoveryWatchdogTimerId
{
    return [self formatTimerId:kUUCoreBluetoothIncludedServicesDiscoveryWatchdogBucket];
}

- (nonnull NSString*) uuDescriptorDiscoveryWatchdogTimerId
{
    return [self formatTimerId:kUUCoreBluetoothDescriptorDiscoveryWatchdogBucket];
}

- (nonnull NSString*) uuCharacteristicNotifyStateWatchdogTimerId
{
    return [self formatTimerId:kUUCoreBluetoothCharacteristicNotifyStateWatchdogBucket];
}

- (nonnull NSString*) uuReadCharacteristicValueWatchdogTimerId
{
    return [self formatTimerId:kUUCoreBluetoothReadCharacteristicValueWatchdogBucket];
}

- (nonnull NSString*) uuWriteCharacteristicValueWatchdogTimerId
{
    return [self formatTimerId:kUUCoreBluetoothWriteCharacteristicValueWatchdogBucket];
}

- (nonnull NSString*) uuReadRssiWatchdogTimerId
{
    return [self formatTimerId:kUUCoreBluetoothReadRssiWatchdogBucket];
}

- (nonnull NSString*) uuPollRssiTimerId
{
    return [self formatTimerId:kUUCoreBluetoothPollRssiBucket];
}

- (void) uuCancelAllTimers
{
    NSArray<UUTimer*>* list = [UUTimer listActiveTimers];
    for (UUTimer* t in list)
    {
        if ([t.timerId uuStartsWithSubstring:self.uuIdentifier])
        {
            [t cancel];
        }
    }
}

- (void) startTimer:(nonnull NSString*)timerId
            timeout:(NSTimeInterval)timeout
              block:(nonnull void(^)(CBPeripheral* _Nonnull peripheral))block
{
    UUCoreBluetoothLog(@"Starting timer %@ with timeout: %@", timerId, @(timeout));
    
    [UUCoreBluetooth startWatchdogTimer:timerId
                                timeout:timeout
                               userInfo:self
                                  block:^(id  _Nullable userInfo)
    {
        if (block)
        {
            block((CBPeripheral*)userInfo);
        }
    }];
}

- (nullable NSError*) canAttemptOperation
{
    if (![[UUCoreBluetooth sharedInstance].centralManager uuIsPoweredOn])
    {
        return [NSError uuCoreBluetoothError:UUCoreBluetoothErrorCodeCentralNotReady];
    }
    
    if (self.state != CBPeripheralStateConnected)
    {
        return [NSError uuCoreBluetoothError:UUCoreBluetoothErrorCodeNotConnected];
    }
    
    return nil;
}

- (void) uuDiscoverServices:(nullable NSArray<CBUUID*>*)serviceUuidList
                    timeout:(NSTimeInterval)timeout
                 completion:(nonnull UUDiscoverServicesBlock)completion
{
    UUCoreBluetoothLog(@"Discovering services for %@ - %@, timeout: %@, service list: %@",
                       self.uuIdentifier, self.name, @(timeout), serviceUuidList);
    
    NSString* timerId = [self uuServiceDiscoveryWatchdogTimerId];
    
    UUPeripheralDelegate* delegate = [[self class] uuDelegateForPeripheral:self];
    self.delegate = delegate;
    delegate.discoverServicesBlock = ^(CBPeripheral* _Nonnull peripheral, NSError* _Nullable error)
    {
        error = [NSError uuOperationCompleteError:error];
        
        UUCoreBluetoothLog(@"Service discovery finished for %@ - %@, error: %@, services: %@",
                           peripheral.uuIdentifier, peripheral.name, error, peripheral.services);
        
        [UUCoreBluetooth cancelWatchdogTimer:timerId];
        completion(peripheral, error);
    };
    
    [self startTimer:timerId
             timeout:timeout
               block:^(CBPeripheral* _Nonnull peripheral)
     {
         UUCoreBluetoothLog(@"Service discovery timeout for %@ - %@", peripheral.uuIdentifier, peripheral.name);
         
         NSError* err = [NSError uuCoreBluetoothError:UUCoreBluetoothErrorCodeTimeout];
         [delegate peripheral:peripheral didDiscoverServices:err];
     }];
    
    NSError* err  = [self canAttemptOperation];
    if (err)
    {
        dispatch_async(UUCoreBluetoothQueue(), ^
        {
            [delegate peripheral:self didDiscoverServices:err];
        });
    }
    else
    {
        [self discoverServices:serviceUuidList];
    }
}

- (void) uuDiscoverCharacteristics:(nullable NSArray<CBUUID*>*)characteristicUuidList
                        forService:(nonnull CBService*)service
                           timeout:(NSTimeInterval)timeout
                        completion:(nonnull UUDiscoverCharacteristicsBlock)completion
{
    UUCoreBluetoothLog(@"Discovering characteristics for %@ - %@, timeout: %@, service: %@, characteristic list: %@",
                       self.uuIdentifier, self.name, @(timeout), service, characteristicUuidList);
    
    NSString* timerId = [self uuCharacteristicDiscoveryWatchdogTimerId];
    
    UUPeripheralDelegate* delegate = [[self class] uuDelegateForPeripheral:self];
    self.delegate = delegate;
    delegate.discoverCharacteristicsBlock = ^(CBPeripheral* _Nonnull peripheral, CBService* _Nonnull service, NSError* _Nullable error)
    {
        error = [NSError uuOperationCompleteError:error];
        
        UUCoreBluetoothLog(@"Characteristic discovery finished for %@ - %@, service: %@, error: %@, characteristics: %@",
                           peripheral.uuIdentifier, peripheral.name, service, error, service.characteristics);
        
        [UUCoreBluetooth cancelWatchdogTimer:timerId];
        completion(peripheral, service, error);
    };
    
    [self startTimer:timerId
             timeout:timeout
            block:^(CBPeripheral* _Nonnull peripheral)
     {
         UUCoreBluetoothLog(@"Characteristic discovery timeout for %@ - %@", peripheral.uuIdentifier, peripheral.name);
         
         NSError* err = [NSError uuCoreBluetoothError:UUCoreBluetoothErrorCodeTimeout];
         [delegate peripheral:peripheral didDiscoverCharacteristicsForService:service error:err];
     }];
    
    NSError* err  = [self canAttemptOperation];
    if (err)
    {
        dispatch_async(UUCoreBluetoothQueue(), ^
        {
            [delegate peripheral:self didDiscoverCharacteristicsForService:service error:err];
        });
    }
    else if (service == nil)
    {
        dispatch_async(UUCoreBluetoothQueue(), ^
        {
            NSError* err = [NSError uuExpectNonNilParamError:@"service"];
            [delegate peripheral:self didDiscoverCharacteristicsForService:service error:err];
        });
    }
    else
    {
        [self discoverCharacteristics:characteristicUuidList forService:service];
    }
}

- (void) uuDiscoverIncludedServices:(nullable NSArray<CBUUID*>*)serviceUuidList
                         forService:(nonnull CBService*)service
                            timeout:(NSTimeInterval)timeout
                         completion:(nonnull UUDiscoverIncludedServicesBlock)completion
{
    UUCoreBluetoothLog(@"Discovering included services for %@ - %@, timeout: %@, service: %@, service list: %@",
                       self.uuIdentifier, self.name, @(timeout), service, serviceUuidList);
    
    NSString* timerId = [self uuIncludedServicesDiscoveryWatchdogTimerId];
    
    UUPeripheralDelegate* delegate = [[self class] uuDelegateForPeripheral:self];
    self.delegate = delegate;
    delegate.discoverIncludedServicesBlock = ^(CBPeripheral* _Nonnull peripheral, CBService* _Nonnull service, NSError* _Nullable error)
    {
        error = [NSError uuOperationCompleteError:error];
        
        UUCoreBluetoothLog(@"Included services discovery finished for %@ - %@, service: %@, error: %@, includedServices: %@",
                           peripheral.uuIdentifier, peripheral.name, service, error, service.includedServices);
        
        [UUCoreBluetooth cancelWatchdogTimer:timerId];
        completion(peripheral, service, error);
    };
    
    [self startTimer:timerId
             timeout:timeout
            block:^(CBPeripheral* _Nonnull peripheral)
     {
         UUCoreBluetoothLog(@"Included services discovery timeout for %@ - %@", peripheral.uuIdentifier, peripheral.name);
         
         NSError* err = [NSError uuCoreBluetoothError:UUCoreBluetoothErrorCodeTimeout];
         [delegate peripheral:peripheral didDiscoverIncludedServicesForService:service error:err];
     }];
    
    NSError* err  = [self canAttemptOperation];
    if (err)
    {
        dispatch_async(UUCoreBluetoothQueue(), ^
        {
            [delegate peripheral:self didDiscoverCharacteristicsForService:service error:err];
        });
    }
    else if (service == nil)
    {
        dispatch_async(UUCoreBluetoothQueue(), ^
        {
            NSError* err = [NSError uuExpectNonNilParamError:@"service"];
            [delegate peripheral:self didDiscoverCharacteristicsForService:service error:err];
        });
    }
    else
    {
        [self discoverIncludedServices:serviceUuidList forService:service];
    }
}

- (void) uuDiscoverDescriptorsForCharacteristic:(nonnull CBCharacteristic*)characteristic
                                        timeout:(NSTimeInterval)timeout
                                     completion:(nonnull UUDiscoverDescriptorsBlock)completion
{
    UUCoreBluetoothLog(@"Discovering descriptors for %@ - %@, timeout: %@, characteristic: %@",
                       self.uuIdentifier, self.name, @(timeout), characteristic);
    
    NSString* timerId = [self uuDescriptorDiscoveryWatchdogTimerId];
    
    UUPeripheralDelegate* delegate = [[self class] uuDelegateForPeripheral:self];
    self.delegate = delegate;
    delegate.discoverDescriptorsBlock = ^(CBPeripheral* _Nonnull peripheral, CBCharacteristic* _Nonnull characteristic, NSError* _Nullable error)
    {
        error = [NSError uuOperationCompleteError:error];
        
        UUCoreBluetoothLog(@"Descriptor discovery finished for %@ - %@, characteristic: %@, error: %@, descriptors: %@",
                           peripheral.uuIdentifier, peripheral.name, characteristic, error, characteristic.descriptors);
        
        [UUCoreBluetooth cancelWatchdogTimer:timerId];
        completion(peripheral, characteristic, error);
    };
    
    [self startTimer:timerId
             timeout:timeout
            block:^(CBPeripheral* _Nonnull peripheral)
     {
         UUCoreBluetoothLog(@"Descriptor discovery timeout for %@ - %@", peripheral.uuIdentifier, peripheral.name);
         
         NSError* err = [NSError uuCoreBluetoothError:UUCoreBluetoothErrorCodeTimeout];
         [delegate peripheral:peripheral didDiscoverDescriptorsForCharacteristic:characteristic error:err];
     }];
    
    NSError* err  = [self canAttemptOperation];
    if (err)
    {
        dispatch_async(UUCoreBluetoothQueue(), ^
        {
            [delegate peripheral:self didDiscoverDescriptorsForCharacteristic:characteristic error:err];
        });
    }
    else if (characteristic == nil)
    {
        dispatch_async(UUCoreBluetoothQueue(), ^
        {
            NSError* err = [NSError uuExpectNonNilParamError:@"characteristic"];
            [delegate peripheral:self didDiscoverDescriptorsForCharacteristic:characteristic error:err];
        });
    }
    else
    {
        [self discoverDescriptorsForCharacteristic:characteristic];
    }
}

- (void) uuSetNotifyValue:(BOOL)enabled
        forCharacteristic:(nonnull CBCharacteristic*)characteristic
                  timeout:(NSTimeInterval)timeout
            notifyHandler:(nullable UUUpdateValueForCharacteristicsBlock)notifyHandler
               completion:(nonnull UUSetNotifyValueForCharacteristicsBlock)completion
{
    UUCoreBluetoothLog(@"Set Notify State for %@ - %@, enabled: %@, timeout: %@, characateristic: %@",
                       self.uuIdentifier, self.name, @(enabled), @(timeout), characteristic);
    
    NSString* timerId = [self uuCharacteristicNotifyStateWatchdogTimerId];
    
    UUPeripheralDelegate* delegate = [[self class] uuDelegateForPeripheral:self];
    self.delegate = delegate;
    delegate.setNotifyValueForCharacteristicBlock = ^(CBPeripheral* _Nonnull peripheral, CBCharacteristic* _Nonnull characteristic, NSError* _Nullable error)
    {
        error = [NSError uuOperationCompleteError:error];
        
        UUCoreBluetoothLog(@"Set Notify State finished for %@ - %@, characteristic: %@, error: %@",
                           peripheral.uuIdentifier, peripheral.name, characteristic, error);
        
        [UUCoreBluetooth cancelWatchdogTimer:timerId];
        completion(peripheral, characteristic, error);
    };
    
    if (enabled && notifyHandler)
    {
        [delegate registerUpdateHandler:notifyHandler forCharacteristic:characteristic];
    }
    else
    {
        [delegate removeUpdateHandlerForCharacteristic:characteristic];
    }
    
    [self startTimer:timerId
             timeout:timeout
               block:^(CBPeripheral* _Nonnull peripheral)
     {
         UUCoreBluetoothLog(@"Set Notify State timeout for %@ - %@", peripheral.uuIdentifier, peripheral.name);
         
         NSError* err = [NSError uuCoreBluetoothError:UUCoreBluetoothErrorCodeTimeout];
         [delegate peripheral:peripheral didUpdateNotificationStateForCharacteristic:characteristic error:err];
     }];
    
    NSError* err  = [self canAttemptOperation];
    if (err)
    {
        dispatch_async(UUCoreBluetoothQueue(), ^
        {
            [delegate peripheral:self didUpdateNotificationStateForCharacteristic:characteristic error:err];
        });
    }
    else if (characteristic == nil)
    {
        dispatch_async(UUCoreBluetoothQueue(), ^
        {
            NSError* err = [NSError uuExpectNonNilParamError:@"characteristic"];
            [delegate peripheral:self didUpdateNotificationStateForCharacteristic:characteristic error:err];
        });
    }
    else
    {
        [self setNotifyValue:enabled forCharacteristic:characteristic];
    }
}

- (void) uuReadValueForCharacteristic:(nonnull CBCharacteristic*)characteristic
                              timeout:(NSTimeInterval)timeout
                           completion:(nonnull UUReadValueForCharacteristicsBlock)completion
{
    UUCoreBluetoothLog(@"Read value for %@ - %@, characteristic: %@, timeout: %@",
                       self.uuIdentifier, self.name, characteristic, @(timeout));
    
    NSString* timerId = [self uuReadCharacteristicValueWatchdogTimerId];
    
    UUPeripheralDelegate* delegate = [[self class] uuDelegateForPeripheral:self];
    self.delegate = delegate;
    
    [delegate registerReadHandler:^(CBPeripheral * _Nonnull peripheral, CBCharacteristic * _Nonnull characteristic, NSError * _Nullable error)
    {
        error = [NSError uuOperationCompleteError:error];
        
        UUCoreBluetoothLog(@"Read value finished for %@ - %@, characteristic: %@, error: %@",
                           peripheral.uuIdentifier, peripheral.name, characteristic, error);
        
        [UUCoreBluetooth cancelWatchdogTimer:timerId];
        [delegate removeReadHandlerForCharacteristic:characteristic];
        completion(peripheral, characteristic, error);
    }
    forCharacteristic:characteristic];
    
    [self startTimer:timerId
             timeout:timeout
               block:^(CBPeripheral* _Nonnull peripheral)
     {
         UUCoreBluetoothLog(@"Read value timeout for %@ - %@", peripheral.uuIdentifier, peripheral.name);
         
         NSError* err = [NSError uuCoreBluetoothError:UUCoreBluetoothErrorCodeTimeout];
         [delegate peripheral:peripheral didUpdateValueForCharacteristic:characteristic error:err];
     }];
    
    NSError* err  = [self canAttemptOperation];
    if (err)
    {
        dispatch_async(UUCoreBluetoothQueue(), ^
        {
            [delegate peripheral:self didUpdateValueForCharacteristic:characteristic error:err];
        });
    }
    else if (characteristic == nil)
    {
        dispatch_async(UUCoreBluetoothQueue(), ^
        {
            NSError* err = [NSError uuExpectNonNilParamError:@"characteristic"];
            [delegate peripheral:self didUpdateValueForCharacteristic:characteristic error:err];
        });
    }
    else
    {
        [self readValueForCharacteristic:characteristic];
    }
}

- (void) uuWriteValue:(nonnull NSData*)data
    forCharacteristic:(nonnull CBCharacteristic*)characteristic
              timeout:(NSTimeInterval)timeout
           completion:(nonnull UUWriteValueForCharacteristicsBlock)completion
{
    UUCoreBluetoothLog(@"Write value %@, for %@ - %@, characteristic: %@, timeout: %@",
                       [data uuToHexString], self.uuIdentifier, self.name, characteristic, @(timeout));
    
    NSString* timerId = [self uuWriteCharacteristicValueWatchdogTimerId];
    
    UUPeripheralDelegate* delegate = [[self class] uuDelegateForPeripheral:self];
    self.delegate = delegate;
    
    [delegate registerWriteHandler:^(CBPeripheral * _Nonnull peripheral, CBCharacteristic * _Nonnull characteristic, NSError * _Nullable error)
     {
         error = [NSError uuOperationCompleteError:error];
         
         UUCoreBluetoothLog(@"Write value finished for %@ - %@, characteristic: %@, error: %@",
                            peripheral.uuIdentifier, peripheral.name, characteristic, error);
         
         [UUCoreBluetooth cancelWatchdogTimer:timerId];
         [delegate removeWriteHandlerForCharacteristic:characteristic];
         completion(peripheral, characteristic, error);
     }
    forCharacteristic:characteristic];
    
    [self startTimer:timerId
             timeout:timeout
            block:^(CBPeripheral* _Nonnull peripheral)
     {
         UUCoreBluetoothLog(@"Write value timeout for %@ - %@", peripheral.uuIdentifier, peripheral.name);
         
         NSError* err = [NSError uuCoreBluetoothError:UUCoreBluetoothErrorCodeTimeout];
         [delegate peripheral:peripheral didWriteValueForCharacteristic:characteristic error:err];
     }];
    
    NSError* err  = [self canAttemptOperation];
    if (err)
    {
        dispatch_async(UUCoreBluetoothQueue(), ^
        {
            [delegate peripheral:self didWriteValueForCharacteristic:characteristic error:err];
        });
    }
    else if (characteristic == nil)
    {
        dispatch_async(UUCoreBluetoothQueue(), ^
        {
            NSError* err = [NSError uuExpectNonNilParamError:@"characteristic"];
            [delegate peripheral:self didWriteValueForCharacteristic:characteristic error:err];
        });
    }
    else
    {
        [self writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }
}

- (void) uuWriteValueWithoutResponse:(nonnull NSData*)data
                   forCharacteristic:(nonnull CBCharacteristic*)characteristic
                          completion:(nonnull UUWriteValueForCharacteristicsBlock)completion
{
    UUCoreBluetoothLog(@"Write value without response %@, for %@ - %@, characteristic: %@",
                       [data uuToHexString], self.uuIdentifier, self.name, characteristic);
    
    NSError* err = [self canAttemptOperation];
    
    if (characteristic == nil)
    {
        err = [NSError uuExpectNonNilParamError:@"characteristic"];
    }
    
    if (!err)
    {
        [self writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
    }
    
    dispatch_async(UUCoreBluetoothQueue(), ^
    {
        completion(self, characteristic, err);
    });
}

- (void) uuReadRssi:(NSTimeInterval)timeout
         completion:(nonnull UUDidReadRssiBlock)completion
{
    UUCoreBluetoothLog(@"Reading RSSI for %@ - %@, timeout: %@", self.uuIdentifier, self.name, @(timeout));
    
    NSString* timerId = [self uuReadRssiWatchdogTimerId];
    
    UUPeripheralDelegate* delegate = [[self class] uuDelegateForPeripheral:self];
    self.delegate = delegate;
    delegate.didReadRssiBlock = ^(CBPeripheral* _Nonnull peripheral, NSNumber* _Nonnull rssi, NSError* _Nullable error)
    {
        error = [NSError uuOperationCompleteError:error];
        
        UUCoreBluetoothLog(@"Read RSSI finished for %@ - %@, rssi: %@, error: %@",
                           peripheral.uuIdentifier, peripheral.name, rssi, error);
        
        [UUCoreBluetooth cancelWatchdogTimer:timerId];
        completion(peripheral, rssi, error);
    };
    
    [self startTimer:timerId
             timeout:timeout
               block:^(CBPeripheral* _Nonnull peripheral)
     {
         UUCoreBluetoothLog(@"Read RSSI timeout for %@ - %@", peripheral.uuIdentifier, peripheral.name);
         
         NSError* err = [NSError uuCoreBluetoothError:UUCoreBluetoothErrorCodeTimeout];
         [delegate peripheral:self didReadRSSI:@(127) error:err];
     }];
    
    NSError* err  = [self canAttemptOperation];
    if (err)
    {
        dispatch_async(UUCoreBluetoothQueue(), ^
        {
            [delegate peripheral:self didReadRSSI:@(127) error:err];
        });
    }
    else
    {
        [self readRSSI];
    }
}

- (void) uuDiscoverCharactertistics:(nullable NSArray<CBUUID*>*)characteristicUuidList
                     forServiceUuid:(nonnull CBUUID*)serviceUuid
                            timeout:(NSTimeInterval)timeout
                         completion:(nonnull UUDiscoverCharacteristicsForServiceUuidBlock)completion
{
    
     NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    [self uuDiscoverServices:@[ serviceUuid ]
                     timeout:timeout
                  completion:^(CBPeripheral * _Nonnull peripheral, NSError * _Nullable error)
    {
        if (error != nil)
        {
            completion(peripheral, nil, error);
        }
        else
        {
            CBService* foundService = nil;
            
            for (CBService* service in peripheral.services)
            {
                if ([[service.UUID UUIDString] isEqualToString:[serviceUuid UUIDString]])
                {
                    foundService = service;
                    break;
                }
            }
            
            if (foundService == nil)
            {
                completion(peripheral, nil, nil);
            }
            else
            {
                NSTimeInterval duration = [NSDate timeIntervalSinceReferenceDate] - start;
                NSTimeInterval remainingTimeout = timeout - duration;
                
                [self uuDiscoverCharacteristics:characteristicUuidList
                                     forService:foundService
                                        timeout:remainingTimeout
                                     completion:^(CBPeripheral * _Nonnull peripheral, CBService * _Nonnull service, NSError * _Nullable error)
                {
                    completion(peripheral, service, error);
                }];
            }
            
        }
    }];
}

@end






////////////////////////////////////////////////////////////////////////////////
#pragma mark - UUCentralManagerDelegate
////////////////////////////////////////////////////////////////////////////////

@interface UUCentralManagerDelegate : NSObject<CBCentralManagerDelegate>

@end

@interface UUCentralManagerDelegate ()

@property (nonnull, nonatomic, strong, readwrite) CBCentralManager* centralManager;
@property (nullable, nonatomic, copy) UUCentralStateChangedBlock centralStateChangedBlock;
@property (nullable, nonatomic, copy) UUPeripheralFoundBlock peripheralFoundBlock;
@property (nullable, nonatomic, strong) NSMutableDictionary< NSString*, UUPeripheralConnectedBlock >* connectBlocks;
@property (nullable, nonatomic, strong) NSMutableDictionary< NSString*, UUPeripheralDisconnectedBlock >* disconnectBlocks;


@end

@implementation UUCentralManagerDelegate

- (nonnull id) init
{
    self = [super init];
    
    if (self)
    {
        self.connectBlocks = [NSMutableDictionary dictionary];
        self.disconnectBlocks = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    UUCoreBluetoothLog(@"Central state changed to %@ (%@)", UUCBManagerStateToString(central.state), @(central.state));
    
    UUCentralStateChangedBlock block = self.centralStateChangedBlock;
    if (block)
    {
        block(central.state);
    }
}

//- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *, id> *)dict
//{
//    UUCoreBluetoothLog(@"Restoring state, dict: %@", dict);
//
//}

 - (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral
      advertisementData:(NSDictionary<NSString *, id> *)advertisementData
                   RSSI:(NSNumber *)RSSI
 {
     UUCoreBluetoothLog(@"peripheral: %@, RSSI: %@, advertisement: %@", peripheral, RSSI, advertisementData);
 
     UUPeripheralFoundBlock block = self.peripheralFoundBlock;
     if (block)
     {
         block(peripheral, advertisementData, RSSI);
     }
 }

- (void)centralManager:(CBCentralManager*)central didConnectPeripheral:(CBPeripheral*)peripheral
{
    UUPeripheralConnectedBlock block = [self.connectBlocks uuSafeGet:peripheral.uuIdentifier];
    [self.connectBlocks uuSafeRemove:peripheral.uuIdentifier];
    
    if (block)
    {
        block(peripheral);
    }
}

- (void)centralManager:(CBCentralManager*)central didFailToConnectPeripheral:(CBPeripheral*)peripheral error:(nullable NSError *)error
{
    UUPeripheralDisconnectedBlock block = [self.disconnectBlocks uuSafeGet:peripheral.uuIdentifier];
    [self.disconnectBlocks uuSafeRemove:peripheral.uuIdentifier];
    [self.connectBlocks uuSafeRemove:peripheral.uuIdentifier];
    
    if (block)
    {
        error = [NSError uuConnectionFailedError:error];
        block(peripheral, error);
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    UUPeripheralDisconnectedBlock block = [self.disconnectBlocks uuSafeGet:peripheral.uuIdentifier];
    [self.disconnectBlocks uuSafeRemove:peripheral.uuIdentifier];
    [self.connectBlocks uuSafeRemove:peripheral.uuIdentifier];
    
    if (block)
    {
        error = [NSError uuDisconnectedError:error];
        block(peripheral, error);
    }
}


@end





////////////////////////////////////////////////////////////////////////////////
#pragma mark - CBCentralManager (UUCoreBluetooth)
////////////////////////////////////////////////////////////////////////////////

@implementation CBCentralManager (UUCoreBluetooth)

- (nullable UUCentralManagerDelegate*) uuCentralManagerDelegate
{
    if ([self.delegate isKindOfClass:[UUCentralManagerDelegate class]])
    {
        return (UUCentralManagerDelegate*)self.delegate;
    }
    else
    {
        return nil;
    }
}

- (BOOL) uuIsPoweredOn
{
    return (self.state == CBManagerStatePoweredOn);
}

- (void) uuScanForPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs
                                  options:(nullable NSDictionary<NSString *, id> *)options
                  peripheralFoundCallback:(nonnull UUPeripheralFoundBlock)peripheralFoundBlock
{
    UUCoreBluetoothLog(@"Starting BTLE scan, serviceUUIDs: %@, options: %@, state: %@", serviceUUIDs, options, UUCBManagerStateToString(self.state));
    
    if (![self uuIsPoweredOn])
    {
        UUCoreBluetoothLog(@"Central is not powered on, cannot start scanning now!");
        return;
    }
    
    UUCentralManagerDelegate* delegate = [self uuCentralManagerDelegate];
    delegate.peripheralFoundBlock = peripheralFoundBlock;
    [self scanForPeripheralsWithServices:serviceUUIDs options:options];
}

- (void) uuStopScanning
{
    UUCoreBluetoothLog(@"Stopping BTLE scan, state: %@", UUCBManagerStateToString(self.state));
    
    UUCentralManagerDelegate* delegate = [self uuCentralManagerDelegate];
    delegate.peripheralFoundBlock = nil;
    
    if (![self uuIsPoweredOn])
    {
        UUCoreBluetoothLog(@"Central is not powered on, cannot stop scanning now!");
        return;
    }
    
    [self stopScan];
}

- (void) uuConnectPeripheral:(nonnull CBPeripheral*)peripheral
                     options:(nullable NSDictionary<NSString *, id> *)options
                     timeout:(NSTimeInterval)timeout
           disconnectTimeout:(NSTimeInterval)disconnectTimeout
                   connected:(nonnull UUPeripheralConnectedBlock)connected
                disconnected:(nonnull UUPeripheralDisconnectedBlock)disconnected
{
    UUCoreBluetoothLog(@"Connecting to %@ - %@, timeout: %@", peripheral.identifier, peripheral.name, @(timeout));
    
    if (![self uuIsPoweredOn])
    {
        NSError* err = [NSError uuCoreBluetoothError:UUCoreBluetoothErrorCodeCentralNotReady];
        disconnected(peripheral, err);
        return;
    }
    
    NSString* timerId = [peripheral uuConnectWatchdogTimerId];
    
    UUCentralManagerDelegate* delegate = [self uuCentralManagerDelegate];
    
    UUPeripheralConnectedBlock connectedBlock = ^(CBPeripheral* _Nonnull peripheral)
    {
        UUCoreBluetoothLog(@"Connected to %@ - %@", peripheral.identifier, peripheral.name);
        
        [UUCoreBluetooth cancelWatchdogTimer:timerId];
        connected(peripheral);
    };
    
    UUPeripheralDisconnectedBlock disconnectedBlock = ^(CBPeripheral* _Nonnull peripheral, NSError* _Nullable error)
    {
        UUCoreBluetoothLog(@"Disconnected from %@ - %@, error: %@", peripheral.identifier, peripheral.name, error);
        
        [UUCoreBluetooth cancelWatchdogTimer:timerId];
        disconnected(peripheral, error);
    };
    
    [delegate.connectBlocks uuSafeSetValue:connectedBlock forKey:peripheral.uuIdentifier];
    [delegate.disconnectBlocks uuSafeSetValue:disconnectedBlock forKey:peripheral.uuIdentifier];
    
    [peripheral startTimer:timerId
                   timeout:timeout
                     block:^(CBPeripheral* _Nonnull peripheral)
     {
         UUCoreBluetoothLog(@"Connect timeout for %@ - %@", peripheral.uuIdentifier, peripheral.name);
         
         [delegate.connectBlocks uuSafeRemove:peripheral.uuIdentifier];
         [delegate.disconnectBlocks uuSafeRemove:peripheral.uuIdentifier];
         
         // Issue the disconnect but disconnect any delegate's.  In the case of
         // CBCentralManager being off or reset when this happens, immediately
         // calling the disconnected block ensures there is not an infinite
         // timeout situation.
         [self uuDisconnectPeripheral:peripheral timeout:disconnectTimeout];
         
         NSError* err = [NSError uuCoreBluetoothError:UUCoreBluetoothErrorCodeTimeout];
         [UUCoreBluetooth cancelWatchdogTimer:timerId];
         disconnected(peripheral, err);
     }];
    
    [self connectPeripheral:peripheral options:options];
}

- (void) uuDisconnectPeripheral:(nonnull CBPeripheral*)peripheral timeout:(NSTimeInterval)timeout;
{
    UUCoreBluetoothLog(@"Cancelling connection to peripheral %@ - %@, timeout: %@", peripheral.uuIdentifier, peripheral.name, @(timeout));
    
    if (![self uuIsPoweredOn])
    {
        UUCoreBluetoothLog(@"Central is not powered on, cannot cancel a connection!");
        return;
    }
    
    NSString* timerId = [peripheral uuDisconnectWatchdogTimerId];
    
    [peripheral startTimer:timerId timeout:timeout block:^(CBPeripheral * _Nonnull peripheral)
    {
        UUCoreBluetoothLog(@"Disconnect timeout for %@ - %@", peripheral.uuIdentifier, peripheral.name);
        
        UUCentralManagerDelegate* delegate = [self uuCentralManagerDelegate];
        UUPeripheralDisconnectedBlock block = [delegate.disconnectBlocks uuSafeGet:peripheral.uuIdentifier];
        [delegate.disconnectBlocks uuSafeRemove:peripheral.uuIdentifier];
        [delegate.connectBlocks uuSafeRemove:peripheral.uuIdentifier];
        [UUCoreBluetooth cancelWatchdogTimer:timerId];
        
        if (block)
        {
            NSError* err = [NSError uuCoreBluetoothError:UUCoreBluetoothErrorCodeTimeout];
            block(peripheral, err);
        }
        else
        {
            UUCoreBluetoothLog(@"No delegate to notify disconnected");
        }
        
        // Just in case the timeout fires and a real disconnect is needed, this is the last
        // ditch effort to close the connection
        [self cancelPeripheralConnection:peripheral];
    }];
    
    [self cancelPeripheralConnection:peripheral];
}

@end






////////////////////////////////////////////////////////////////////////////////
#pragma mark - UUCoreBluetooth
////////////////////////////////////////////////////////////////////////////////

@interface UUCoreBluetooth ()

@property (nonnull, nonatomic, strong, readwrite) UUCentralManagerDelegate* delegate;
@property (nonnull, nonatomic, strong, readwrite) CBCentralManager* centralManager;

@property (nullable, nonatomic, strong) NSMutableDictionary< NSString*, UUPeripheral* >* peripherals;

@property (nullable, nonatomic, strong) NSArray< CBUUID* >* scanUuidList;
@property (nonnull, assign) Class peripheralClass;
@property (nullable, nonatomic, strong) NSDictionary<NSString*, id>* scanOptions;
@property (nullable, nonatomic, strong) NSArray< NSObject<UUPeripheralFilter>* >* scanFilters;
@property (assign, readwrite) BOOL isScanning;

@property (nullable, copy, readwrite) UUPeripheralFoundBlock peripheralFoundBlock;
@property (nullable, copy, readwrite) UUCentralStateChangedBlock centralStateChangedBlock;

@property (nullable, nonatomic, strong) NSMutableDictionary< NSString*, UUPeripheralBlock >* rssiPollingBlocks;

@end

@implementation UUCoreBluetooth

+ (nonnull instancetype) sharedInstance
{
    static id theSharedObject = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once (&onceToken, ^
    {
        NSMutableDictionary* opts = [NSMutableDictionary dictionary];
        [opts setValue:@(NO) forKey:CBCentralManagerOptionShowPowerAlertKey];
        //[opts setValue:@"UUCoreBluetooth" forKey:CBCentralManagerOptionRestoreIdentifierKey];
        
        UUCoreBluetooth* obj = [[UUCoreBluetooth alloc] initWithCentralOptions:opts];
        theSharedObject = obj;
    });
    
    return theSharedObject;
}

- (id) initWithCentralOptions:(nullable NSDictionary<NSString*, id>*)options
{
    self = [super init];
    
    if (self)
    {
        self.delegate = [[UUCentralManagerDelegate alloc] init];
        
        dispatch_queue_t centralDispatchQueue = UUCoreBluetoothQueue();
        
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self.delegate queue:centralDispatchQueue options:options];
        self.delegate.centralManager = self.centralManager;
        
        self.peripherals = [NSMutableDictionary dictionary];
        self.rssiPollingBlocks = [NSMutableDictionary dictionary];
        
        __weak UUCoreBluetooth* weakSelf = self;
        self.delegate.centralStateChangedBlock = ^(CBManagerState state)
        {
            [weakSelf handleCentralStateChanged:state];
        };
    }
    
    return self;
}

- (CBManagerState) centralState
{
    return self.centralManager.state;
}

- (void) registerForCentralStateChanges:(nullable UUCentralStateChangedBlock)block
{
    self.centralStateChangedBlock = block;
}

- (void) handleCentralStateChanged:(CBManagerState)state
{
    for (UUPeripheral* p in self.peripherals.allValues)
    {
        UUCoreBluetoothLog(@"Peripheral %@-%@, state is %@ (%@) when central state changed to %@ (%@)",
                           p.identifier, p.name, UUCBPeripheralStateToString(p.peripheralState), @(p.peripheralState),
                           UUCBManagerStateToString(state), @(state));
    }
    
    switch (state)
    {
        case CBManagerStatePoweredOn:
        {
            [self handleCentralStatePoweredOn];
            break;
        }
            
        case CBManagerStateResetting:
        {
            [self handleCentralReset];
            break;
        }
            
        case CBManagerStatePoweredOff:
        {
            break;
        }
            
        case CBManagerStateUnsupported:
        case CBManagerStateUnauthorized:
        default:
        {
            break;
            
        }
    }
    
    if (self.centralStateChangedBlock)
    {
        self.centralStateChangedBlock(state);
    }
}

- (void) handleCentralStatePoweredOn
{
    if (self.isScanning)
    {
        [self resumeScanning];
    }
}

- (void) handleCentralReset
{
    UUCoreBluetoothLog(@"Central is resetting");
}

- (void) startScanForServices:(nullable NSArray<CBUUID *> *)serviceUUIDs
              allowDuplicates:(BOOL)allowDuplicates
              peripheralClass:(nullable Class)peripheralClass
                      filters:(nullable NSArray< NSObject<UUPeripheralFilter>* >*)filters
      peripheralFoundCallback:(nonnull UUPeripheralBlock)peripheralFoundBlock
{
    NSMutableDictionary* opts = [NSMutableDictionary dictionary];
    [opts setValue:@(allowDuplicates) forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
    
    if (peripheralClass == nil)
    {
        peripheralClass = [UUPeripheral class];
    }
    
    self.scanUuidList = serviceUUIDs;
    self.peripheralClass = peripheralClass;
    self.scanOptions = opts;
    self.scanFilters = filters;
    self.isScanning = YES;
    
    __weak typeof(self) weakSelf = self;
    self.peripheralFoundBlock = ^(CBPeripheral * _Nonnull peripheral, NSDictionary<NSString *,id> * _Nullable advertisementData, NSNumber * _Nonnull rssi)
    {
        UUPeripheral* uuPeripheral = [weakSelf updatedPeripheralFromScan:peripheral advertisementData:advertisementData rssi:rssi];
        
        UUCoreBluetoothLog(@"Updated peripheral after scan. peripheral: %@, rssi: %@, advertisement: %@",
                           uuPeripheral.peripheral, uuPeripheral.rssi, uuPeripheral.advertisementData);
        
        if ([weakSelf shouldDiscoverPeripheral:uuPeripheral])
        {
            peripheralFoundBlock(uuPeripheral);
        }
    };
    
    [self.centralManager uuScanForPeripheralsWithServices:serviceUUIDs
                                                  options:opts
                                  peripheralFoundCallback:self.peripheralFoundBlock];
}

- (void) resumeScanning
{
    UUCoreBluetoothLog(@"Resuming scan with last scan settings");
    
    [self.centralManager uuScanForPeripheralsWithServices:self.scanUuidList
                                                  options:self.scanOptions
                                  peripheralFoundCallback:self.peripheralFoundBlock];
}

- (BOOL) shouldDiscoverPeripheral:(nonnull UUPeripheral*)peripheral
{
    if (self.scanFilters != nil)
    {
        for (NSObject<UUPeripheralFilter>* filter in self.scanFilters)
        {
            if (![filter shouldDiscoverPeripheral:peripheral])
            {
                return NO;
            }
        }
        
        return YES;
    }
    else
    {
        return YES;
    }
}

- (void) stopScanning
{
    self.isScanning = NO;
    self.peripheralFoundBlock = nil;
    [self.centralManager uuStopScanning];
}

- (void) connectPeripheral:(nonnull UUPeripheral*)peripheral
                   timeout:(NSTimeInterval)timeout
         disconnectTimeout:(NSTimeInterval)disconnectTimeout
                 connected:(nonnull UUPeripheralBlock)connected
              disconnected:(nonnull UUPeripheralErrorBlock)disconnected
{
    [self.centralManager uuConnectPeripheral:peripheral.peripheral
                                     options:nil
                                     timeout:timeout
                           disconnectTimeout:disconnectTimeout
                                   connected:^(CBPeripheral * _Nonnull peripheral)
    {
        UUPeripheral* uuPeripheral = [self updatedPeripheralFromCbPeripheral:peripheral];
        connected(uuPeripheral);
        
    }
    disconnected:^(CBPeripheral * _Nonnull peripheral, NSError * _Nullable error)
    {
        [peripheral uuCancelAllTimers];
        
        UUPeripheral* uuPeripheral = [self updatedPeripheralFromCbPeripheral:peripheral];
        disconnected(uuPeripheral, error);
    }];
}

- (void) disconnectPeripheral:(nonnull UUPeripheral*)peripheral timeout:(NSTimeInterval)timeout;
{
    [self.centralManager uuDisconnectPeripheral:peripheral.peripheral timeout:timeout];
}

// Begins polling RSSI for a peripheral.  When the RSSI is successfully
// retrieved, the peripheralFoundBlock is called.  This method is useful to
// perform a crude 'ranging' logic when already connected to a peripheral
- (void) startRssiPolling:(nonnull UUPeripheral*)peripheral
                 interval:(NSTimeInterval)interval
        peripheralUpdated:(nonnull UUPeripheralBlock)peripheralUpdated
{
    [self.rssiPollingBlocks uuSafeSetValue:peripheralUpdated forKey:peripheral.identifier];
    
    NSString* timerId = [peripheral.peripheral uuPollRssiTimerId];
    [UUCoreBluetooth cancelWatchdogTimer:timerId];
    
    [peripheral.peripheral uuReadRssi:kUUCoreBluetoothTimeoutDisabled
                           completion:^(CBPeripheral * _Nonnull cbPeripheral, NSNumber * _Nonnull rssi, NSError * _Nullable error)
    {
        UUCoreBluetoothLog(@"RSSI Updated for %@-%@, %@, error: %@", cbPeripheral.uuIdentifier, cbPeripheral.name, rssi, error);
        
        UUPeripheralBlock block = [self.rssiPollingBlocks uuSafeGet:cbPeripheral.uuIdentifier];

        if (!error)
        {
            UUPeripheral* peripheral = [self updatedPeripheralFromRssiRead:cbPeripheral rssi:rssi];
            
            if (block)
            {
                block(peripheral);
            }
        }
        else
        {
            UUCoreBluetoothLog(@"Error while reading RSSI: %@", error);
        }
        
        if (block)
        {
            [UUCoreBluetooth startWatchdogTimer:timerId
                                        timeout:interval
                                       userInfo:peripheral
                                          block:^(id  _Nullable userInfo)
             {
                 UUPeripheral* peripheral = userInfo;
                 UUCoreBluetoothLog(@"RSSI Polling timer %@ - %@", peripheral.identifier, peripheral.name);
                 
                 UUPeripheralBlock block = [self.rssiPollingBlocks uuSafeGet:peripheral.identifier];
                 if (!block)
                 {
                     UUCoreBluetoothLog(@"Peripheral %@-%@ not polling anymore", peripheral.identifier, peripheral.name);
                 }
                 else if (peripheral.peripheralState == CBPeripheralStateConnected)
                 {
                     [self startRssiPolling:peripheral interval:interval peripheralUpdated:peripheralUpdated];
                 }
                 else
                 {
                     UUCoreBluetoothLog(@"Peripheral %@-%@ is not connected anymore, cannot poll for RSSI", peripheral.identifier, peripheral.name);
                 }
             }];
        }
        
    }];
}

- (void) stopRssiPolling:(nonnull UUPeripheral*)peripheral
{
    [self.rssiPollingBlocks uuSafeRemove:peripheral.identifier];
}

- (BOOL) isPollingForRssi:(nonnull UUPeripheral*)peripheral
{
    return ([self.rssiPollingBlocks uuSafeGet:peripheral.identifier] != nil);
}

- (nullable UUPeripheral*) findPeripheralFromCbPeripheral:(CBPeripheral*)peripheral
{
    UUPeripheral* uuPeripheral = nil;
    
    @synchronized (self.peripherals)
    {
        uuPeripheral = [self.peripherals uuSafeGet:peripheral.uuIdentifier forClass:self.peripheralClass];
    }
    
    if (uuPeripheral == nil)
    {
        uuPeripheral = [[self.peripheralClass alloc] init];
    }
    
    return uuPeripheral;
}

- (nonnull UUPeripheral*) updatedPeripheralFromCbPeripheral:(nonnull CBPeripheral*)peripheral
{
    UUPeripheral* uuPeripheral = [self findPeripheralFromCbPeripheral:peripheral];
    uuPeripheral.peripheral = peripheral;
    [self updatePeripheral:uuPeripheral];
    return uuPeripheral;
}

- (nonnull UUPeripheral*) updatedPeripheralFromScan:(nonnull CBPeripheral*)peripheral
                                  advertisementData:(nullable NSDictionary<NSString*, id>* )advertisementData
                                               rssi:(nullable NSNumber*)rssi
{
    UUPeripheral* uuPeripheral = [self findPeripheralFromCbPeripheral:peripheral];
    [uuPeripheral updateFromScan:peripheral advertisementData:advertisementData rssi:rssi];
    [self updatePeripheral:uuPeripheral];
    return uuPeripheral;
}

- (nonnull UUPeripheral*) updatedPeripheralFromRssiRead:(nonnull CBPeripheral*)peripheral
                                                   rssi:(nullable NSNumber*)rssi
{
    UUPeripheral* uuPeripheral = [self findPeripheralFromCbPeripheral:peripheral];
    
    NSNumber* oldRssi = uuPeripheral.rssi;
    
    [uuPeripheral updateRssi:rssi];
    
    UUCoreBluetoothLog(@"peripheralRssiChanged, %@ - %@, from: %@ to %@", uuPeripheral.identifier, uuPeripheral.name, oldRssi, rssi);
    
    [self updatePeripheral:uuPeripheral];
    
    return uuPeripheral;
}

- (void) updatePeripheral:(nonnull UUPeripheral*)peripheral
{
    @synchronized (self.peripherals)
    {
        [self.peripherals uuSafeSetValue:peripheral forKey:peripheral.identifier];
    }
}

- (void) removePeripheral:(nonnull UUPeripheral*)peripheral
{
    @synchronized (self.peripherals)
    {
        [self.peripherals uuSafeRemove:peripheral.identifier];
    }
}

+ (void) startWatchdogTimer:(nonnull NSString*)timerId
                    timeout:(NSTimeInterval)timeout
                   userInfo:(nullable id)userInfo
                      block:(nonnull void (^)(id _Nullable userInfo))block
{
    [self cancelWatchdogTimer:timerId];
    
    if (timeout > 0)
    {
        UUTimer* t = [[UUTimer alloc] initWithId:timerId
                                        interval:timeout
                                        userInfo:userInfo
                                          repeat:NO
                                           queue:UUCoreBluetoothQueue()
                                           block:^(UUTimer * _Nonnull timer)
        {
            if (block)
            {
                block(timer.userInfo);
            }
        }];
        
        [t start];
    }
}

+ (void) cancelWatchdogTimer:(nonnull NSString*)timerId
{
    UUTimer* t = [UUTimer findActiveTimer:timerId];
    [t cancel];
}

@end
