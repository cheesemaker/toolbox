 //
//  UUCoreBluetooth.h
//  Useful Utilities - CoreBluetooth wrapper to make scanning and connecting eaiser
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only
//  requirement is that you smile everytime you use it.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class UUPeripheral;
@protocol UUPeripheralFilter;

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Block Signatures
////////////////////////////////////////////////////////////////////////////////

typedef void (^UUCentralStateChangedBlock)(CBManagerState state);
typedef void (^UUPeripheralFoundBlock)(CBPeripheral* _Nonnull peripheral, NSDictionary<NSString*, id>* _Nullable advertisementData, NSNumber* _Nonnull rssi);
typedef void (^UUPeripheralConnectedBlock)(CBPeripheral* _Nonnull peripheral);
typedef void (^UUPeripheralDisconnectedBlock)(CBPeripheral* _Nonnull peripheral, NSError* _Nullable error);
typedef void (^UUPeripheralNameUpdatedBlock)(CBPeripheral* _Nonnull peripheral);
typedef void (^UUDidModifyServicesBlock)(CBPeripheral* _Nonnull peripheral, NSArray<CBService*>* _Nonnull invalidatedServices);
typedef void (^UUDidReadRssiBlock)(CBPeripheral* _Nonnull peripheral, NSNumber* _Nonnull rssi, NSError* _Nullable error);
typedef void (^UUDiscoverServicesBlock)(CBPeripheral* _Nonnull peripheral, NSError* _Nullable error);
typedef void (^UUDiscoverIncludedServicesBlock)(CBPeripheral* _Nonnull peripheral, CBService* _Nonnull service, NSError* _Nullable error);
typedef void (^UUDiscoverCharacteristicsBlock)(CBPeripheral* _Nonnull peripheral, CBService* _Nonnull service, NSError* _Nullable error);
typedef void (^UUDiscoverCharacteristicsForServiceUuidBlock)(CBPeripheral* _Nonnull peripheral, CBService* _Nullable service, NSError* _Nullable error);
typedef void (^UUUpdateValueForCharacteristicsBlock)(CBPeripheral* _Nonnull peripheral, CBCharacteristic* _Nonnull characteristic, NSError* _Nullable error);
typedef void (^UUReadValueForCharacteristicsBlock)(CBPeripheral* _Nonnull peripheral, CBCharacteristic* _Nonnull characteristic, NSError* _Nullable error);
typedef void (^UUWriteValueForCharacteristicsBlock)(CBPeripheral* _Nonnull peripheral, CBCharacteristic* _Nonnull characteristic, NSError* _Nullable error);
typedef void (^UUSetNotifyValueForCharacteristicsBlock)(CBPeripheral* _Nonnull peripheral, CBCharacteristic* _Nonnull characteristic, NSError* _Nullable error);
typedef void (^UUDiscoverDescriptorsBlock)(CBPeripheral* _Nonnull peripheral, CBCharacteristic* _Nonnull characteristic, NSError* _Nullable error);
typedef void (^UUUpdateValueForDescriptorBlock)(CBPeripheral* _Nonnull peripheral, CBDescriptor* _Nonnull descriptor, NSError* _Nullable error);
typedef void (^UUWriteValueForDescriptorBlock)(CBPeripheral* _Nonnull peripheral, CBDescriptor* _Nonnull descriptor, NSError* _Nullable error);

typedef void (^UUPeripheralBlock)(UUPeripheral* _Nonnull peripheral);
typedef void (^UUPeripheralErrorBlock)(UUPeripheral* _Nonnull peripheral, NSError* _Nullable error);

typedef void (^UUCentralStateChangedBlock)(CBManagerState state);

////////////////////////////////////////////////////////////////////////////////
#pragma mark - UUPeripheral
////////////////////////////////////////////////////////////////////////////////

// UUPeripheral is a convenience class that wraps a CBPeripheral and it's
// advertisement data into one object.
//
@interface UUPeripheral : NSObject

// Reference to the underlying CBPeripheral
@property (nonnull, nonatomic, strong, readonly) CBPeripheral* peripheral;

// The most recent advertisement data
@property (nonnull, nonatomic, strong, readonly) NSDictionary<NSString*, id>* advertisementData;

// Timestamp of when this peripheral was first seen
@property (nonnull, nonatomic, strong, readonly) NSDate* firstAdvertisementTime;

// Timestamp of when the last advertisement was seen
@property (nonnull, nonatomic, strong, readonly) NSDate* lastAdvertisementTime;

// Most recent signal strength
@property (nonnull, nonatomic, strong, readonly) NSNumber* rssi;

// Timestamp of when the RSSI was last updated
@property (nonnull, nonatomic, strong, readonly) NSDate* lastRssiUpdateTime;

// Passthrough properties to read values directly from CBPeripheral
@property (nonnull, nonatomic, strong, readonly) NSString* identifier;
@property (nullable, nonatomic, strong, readonly) NSString* name;
@property (assign, readonly) CBPeripheralState peripheralState;

// Passthrough properties to read values directly from advertisement data

// Returns value of CBAdvertisementDataIsConnectable from advertisement data.  Default
// value is NO if value is not present. Per the CoreBluetooth documentation, this
// value indicates if the peripheral is connectable "right now", which implies
// it may change in the future.
@property (assign, readonly) BOOL isConnectable;

// Returns value of CBAdvertisementDataManufacturerDataKey from advertisement data.
@property (nullable, nonatomic, strong, readonly) NSData* manufacturingData;

// Hook for derived classes to parse custom manufacturing data during object creation.
- (void) parseManufacturingData;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - UUPeripheralFilter
////////////////////////////////////////////////////////////////////////////////

// UUPeripheralFilter is a way for calling code to post filter scanning results
// based on properties of the peripheral advertisement, such as RSSI, name,
// or other advertisement data.
@protocol UUPeripheralFilter <NSObject>

// Return YES if peripheral should be included in scanning callback.
- (BOOL) shouldDiscoverPeripheral:(nonnull UUPeripheral*)peripheral;

@end



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Common Filters
////////////////////////////////////////////////////////////////////////////////
@interface UURssiPeripheralFilter : NSObject<UUPeripheralFilter>

@property (nonnull, nonatomic, strong) NSNumber* rssiThreshold;

+ (nonnull instancetype) filterWithRssi:(nonnull NSNumber*)rssiThreshold;

@end



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Helper C Functions
////////////////////////////////////////////////////////////////////////////////

NSString* _Nonnull UUCBManagerStateToString(CBManagerState state);
NSString* _Nonnull UUCBPeripheralStateToString(CBPeripheralState state);
NSString* _Nonnull UUCBCharacteristicPropertiesToString(CBCharacteristicProperties props);

////////////////////////////////////////////////////////////////////////////////
#pragma mark - UUCoreBluetoothErrorCode
////////////////////////////////////////////////////////////////////////////////

typedef NS_ENUM(NSUInteger, UUCoreBluetoothErrorCode)
{
    // A operation attempt was manually timed out by UUCoreBluetooth
    UUCoreBluetoothErrorCodeTimeout = 1,
    
    // A method call was not attempted because the CBPeripheral was not connected.
    UUCoreBluetoothErrorCodeNotConnected = 2,
    
    // A CoreBluetooth operation failed for some reason. Check inner error for
    // more information.  This can be returned from any Core Bluetooth delegate
    // method that returns an NSError
    UUCoreBluetoothErrorCodeOperationFailed = 3,
    
    // didFailToConnectPeripheral was called
    UUCoreBluetoothErrorCodeConnectionFailed = 4,
    
    // didDisconnectPeripheral was called
    UUCoreBluetoothErrorCodeDisconnected = 5,
    
    // An operation was passed an invalid argument.  Inspect user info for
    // specific details
    UUCoreBluetoothErrorCodeInvalidParam = 6,
    
    // An operation was attempted while CBCentralManager was in a state other
    // that 'On'
    UUCoreBluetoothErrorCodeCentralNotReady = 7,
};

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Constants
////////////////////////////////////////////////////////////////////////////////

extern  NSString * _Nonnull const kUUCoreBluetoothErrorDomain;
extern  NSTimeInterval const kUUCoreBluetoothTimeoutDisabled;


////////////////////////////////////////////////////////////////////////////////
#pragma mark - CBCentralManager (UUCoreBluetooth)
////////////////////////////////////////////////////////////////////////////////

@interface CBCentralManager (UUCoreBluetooth)

// Returns a flag indicating whether the central state is powered on or not.
- (BOOL) uuIsPoweredOn;

// Block based wrapper around CBCentralManager scanForPeripheralsWithServices:options
- (void) uuScanForPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs
                                  options:(nullable NSDictionary<NSString *, id> *)options
                  peripheralFoundCallback:(nonnull UUPeripheralFoundBlock)peripheralFoundBlock;

// Convenience wrapper around CBCentralManager stopScan
- (void) uuStopScanning;

// Block based wrapper around CBCentralManager connectPeripheral:options with a
// timeout value.  If a negative timeout is passed there will be no timeout used.
// The connected block is only invoked upon successfully connection.  The
// disconnected block is invoked in the case of a connection failure, timeout
// or disconnection.
//
// Each block will only be invoked at most one time.  After a successful
// connection, the disconnect block will be called back when the peripheral
// is disconnected from the phone side, or if the remote device disconnects
// from the phone
- (void) uuConnectPeripheral:(nonnull CBPeripheral*)peripheral
                     options:(nullable NSDictionary<NSString *, id> *)options
                     timeout:(NSTimeInterval)timeout
                   connected:(nonnull UUPeripheralConnectedBlock)connected
                disconnected:(nonnull UUPeripheralDisconnectedBlock)disconnected;

// Wrapper around CBCentralManager cancelPeripheralConnection.  After calling this
// method, the disconnected block passed in at connect time will be invoked.
- (void) uuDisconnectPeripheral:(nonnull CBPeripheral*)peripheral;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - CBPeripheral (UUCoreBluetooth)
////////////////////////////////////////////////////////////////////////////////

@interface CBPeripheral (UUCoreBluetooth)

// Block based wrapper around CBPeripheral discoverServices, with an optional
// timeout value.  A negative timeout value will disable the timeout.
- (void) uuDiscoverServices:(nullable NSArray<CBUUID*>*)serviceUuidList
                    timeout:(NSTimeInterval)timeout
                 completion:(nonnull UUDiscoverServicesBlock)completion;

// Block based wrapper around CBPeripheral discoverCharacteristics:forService,
// with an optional timeout value.  A negative timeout value will disable the timeout.
- (void) uuDiscoverCharacteristics:(nullable NSArray<CBUUID*>*)characteristicUuidList
                        forService:(nonnull CBService*)service
                           timeout:(NSTimeInterval)timeout
                        completion:(nonnull UUDiscoverCharacteristicsBlock)completion;

// Block based wrapper around CBPeripheral discoverIncludedServices:forService,
// with an optional timeout value.  A negative timeout value will disable the timeout.
- (void) uuDiscoverIncludedServices:(nullable NSArray<CBUUID*>*)serviceUuidList
                         forService:(nonnull CBService*)service
                            timeout:(NSTimeInterval)timeout
                         completion:(nonnull UUDiscoverIncludedServicesBlock)completion;

// Block based wrapper around CBPeripheral discoverDescriptorsForCharacteristic,
// with an optional timeout value.  A negative timeout value will disable the timeout.
- (void) uuDiscoverDescriptorsForCharacteristic:(nonnull CBCharacteristic*)characteristic
                                        timeout:(NSTimeInterval)timeout
                                     completion:(nonnull UUDiscoverDescriptorsBlock)completion;

// Block based wrapper around CBPeripheral setNotifyValue, with an optional
// timeout value.  A negative timeout value will disable the timeout.
- (void) uuSetNotifyValue:(BOOL)enabled
        forCharacteristic:(nonnull CBCharacteristic*)characteristic
                  timeout:(NSTimeInterval)timeout
            notifyHandler:(nullable UUUpdateValueForCharacteristicsBlock)notifyHandler
               completion:(nonnull UUSetNotifyValueForCharacteristicsBlock)completion;

// Block based wrapper around CBPeripheral readValue:forCharacteristic, with an
// optional timeout value.  A negative timeout value will disable the timeout.
- (void) uuReadValueForCharacteristic:(nonnull CBCharacteristic*)characteristic
                              timeout:(NSTimeInterval)timeout
                           completion:(nonnull UUReadValueForCharacteristicsBlock)completion;

// Block based wrapper around CBPeripheral writeValue:forCharacteristic:type with type
// CBCharacteristicWriteWithResponse, with an optional timeout value.  A negative
// timeout value will disable the timeout.
- (void) uuWriteValue:(nonnull NSData*)data
    forCharacteristic:(nonnull CBCharacteristic*)characteristic
              timeout:(NSTimeInterval)timeout
           completion:(nonnull UUWriteValueForCharacteristicsBlock)completion;

// Block based wrapper around CBPeripheral writeValue:forCharacteristic:type with type
// CBCharacteristicWriteWithoutResponse.  Block callback is invoked after sending.
// Per CoreBluetooth documentation, there is no garauntee of delivery.
- (void) uuWriteValueWithoutResponse:(nonnull NSData*)data
                   forCharacteristic:(nonnull CBCharacteristic*)characteristic
                          completion:(nonnull UUWriteValueForCharacteristicsBlock)completion;

// Block based wrapper around CBPeripheral readRssi, with an optional
// timeout value.  A negative timeout value will disable the timeout.
- (void) uuReadRssi:(NSTimeInterval)timeout
         completion:(nonnull UUDidReadRssiBlock)completion;

// Convenience wrapper to perform both service and characteristic discovery at
// one time.  This method is useful when you know both service and characteristic
// UUID's ahead of time.
- (void) uuDiscoverCharactertistics:(nullable NSArray<CBUUID*>*)characteristicUuidList
                     forServiceUuid:(nonnull CBUUID*)serviceUuid
                            timeout:(NSTimeInterval)timeout
                         completion:(nonnull UUDiscoverCharacteristicsForServiceUuidBlock)completion;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - CBCharacteristic (UUCoreBluetooth)
////////////////////////////////////////////////////////////////////////////////

@interface CBCharacteristic (UUCoreBluetooth)

// Returns true if properties contains CBCharacteristicPropertyNotify or
// CBCharacteristicPropertyIndicate
- (BOOL) uuCanToggleNotify;

// Returns true if properties contains CBCharacteristicPropertyRead
- (BOOL) uuCanReadData;

// Returns true if properties contains CBCharacteristicPropertyWrite
- (BOOL) uuCanWriteData;

// Returns true if properties contains CBCharacteristicPropertyWriteWithoutResponse
- (BOOL) uuCanWriteWithoutResponse;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSUUID (UUCoreBluetooth)
////////////////////////////////////////////////////////////////////////////////

@interface CBUUID (UUCoreBluetooth)

// Some UUID's have a common name, if UUIDString does not match, it is returned,
// otherwise 'Unknown'.
- (nonnull NSString*) uuCommonName;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - UUCoreBluetooth
////////////////////////////////////////////////////////////////////////////////

// UUCoreBluetooth provides a small set of convenience wrappers around the
// CoreBluetooth block based extensions defined above.  Additionally, all of
// the UUCoreBluetooth methods operate on the UUPeripheral wrapper object
// instead of CBPeripheral directly.
@interface UUCoreBluetooth : NSObject

// Singleton instance
+ (nonnull instancetype) sharedInstance;

// Reference to the underlying central
@property (nonnull, nonatomic, strong, readonly) CBCentralManager* centralManager;

// Returns current CBCentralManager.state value
- (CBManagerState) centralState;

// Register a listener for central state changes
- (void) registerForCentralStateChanges:(nullable UUCentralStateChangedBlock)block;

// Initiates a CoreBluetooth scan for nearby peripherals
//
// serviceUUIDs - list of service's to scan for.
//
// allowDuplicates controls how the CBCentralManagerScanOptionAllowDuplicatesKey
// scanning option is initialized.
//
// peripheralClass allows callers to pass in their custom UUPeripheral derived
// class so that peripheral objects returned from scan are already thier
// custom object.  If nil, UUPeripheral is used.
//
// filters - An array of UUPeripheralFilter objects to narrow down which
// objects are returned in the peripheralFoundBlock.  The peripheral filtering
// logic is an AND algorithm, meaning that a peripheral is only returned if it
// passes ALL filters.
//
// peripheralFoundBlock - block used to notify callers of new peripherals
//
- (void) startScanForServices:(nullable NSArray<CBUUID *> *)serviceUUIDs
              allowDuplicates:(BOOL)allowDuplicates
              peripheralClass:(nullable Class)peripheralClass
                      filters:(nullable NSArray< NSObject<UUPeripheralFilter>* >*)filters
      peripheralFoundCallback:(nonnull UUPeripheralBlock)peripheralFoundBlock;

// Stop an ongoing scan
- (void) stopScanning;

// Flag indicating if UUCoreBluetooth is currently scanning.  This does NOT map
// directly to the CBCentralManager.isScanning flag.  This flag is used internally
// to resume scanning if the central manager has to go through a restart.
@property (assign, readonly) BOOL isScanning;

// Convenience wrapper around CBCentralManager uuConnectPeripheral that uses nil
// for the connect options
- (void) connectPeripheral:(nonnull UUPeripheral*)peripheral
                   timeout:(NSTimeInterval)timeout
                 connected:(nonnull UUPeripheralBlock)connected
              disconnected:(nonnull UUPeripheralErrorBlock)disconnected;

// Convenience wrapper around CBCentralManager uuDisconnectPeripheral
- (void) disconnectPeripheral:(nonnull UUPeripheral*)peripheral;

// Begins polling RSSI for a peripheral.  When the RSSI is successfully
// retrieved, the peripheralFoundBlock is called.  This method is useful to
// perform a crude 'ranging' logic when already connected to a peripheral
- (void) startRssiPolling:(nonnull UUPeripheral*)peripheral
                 interval:(NSTimeInterval)interval
        peripheralUpdated:(nonnull UUPeripheralBlock)peripheralUpdated;

// Stop RSSI polling for a peripheral
- (void) stopRssiPolling:(nonnull UUPeripheral*)peripheral;

// Returns a flag indicating if RSSI polling is active
- (BOOL) isPollingForRssi:(nonnull UUPeripheral*)peripheral;

// Cancels any existing timer with this ID, and kicks off a new timer
// on the UUCoreBluetooth queue. If the timeout value is negative, the
// new timer will not be started.
+ (void) startWatchdogTimer:(nonnull NSString*)timerId
                    timeout:(NSTimeInterval)timeout
                   userInfo:(nullable id)userInfo
                      block:(nonnull void (^)(id _Nullable userInfo))block;

+ (void) cancelWatchdogTimer:(nonnull NSString*)timerId;

@end
