//
//  UULocationManager.h
//  Useful Utilities - CLLocationManager wrapper
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com


#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

extern NSString * const UULocationChangedNotification;
extern NSString * const UULocationNameChangedNotification;
extern NSString * const UULocationAuthChangedNotification;
extern NSString * const UULocationErrorNotification;

@interface UULocationManager : NSObject<CLLocationManagerDelegate>


//Call startTracking to begin location services. If you do not explicitly call startTracking,
//the first time you access the sharedInstance, it will be called internally.
+ (void) startTracking;
+ (UULocationManager*) sharedInstance;


// Cached results
- (CLLocation*) currentLocation;
- (NSString*)	currentLocationName;
- (NSString*)	currentCityName;
- (NSString*)	currentStateName;

- (bool) hasValidLocation;

- (void) startTracking;
- (void) stopTracking;
- (void) startTrackingSignificantLocationChanges;
- (void) stopTrackingSignificantLocationChanges;

// Configuration Properties
@property (assign, setter = setDistsanceThreshold:) CLLocationDistance distanceThreshold;	// Defaults to 10 meters
@property (assign) NSTimeInterval timeThreshold;			// Defaults to 30 minutes (time is in seconds)
@property (assign) bool monitorLocationName;                // Defaults to NO
@property (assign) bool delayLocationUpdates;               // Defaults to NO
@property (assign) NSTimeInterval locationUpdateDelay;      // Defaults to 1 second

@end
