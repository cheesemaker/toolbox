//
//  UULocation.h
//  Useful Utilities - CLLocationManager wrapper
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@silverpinesoftware.com


#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface UULocation : NSObject
	//The last reported location. If no location reported, this will be nil
	+ (UULocation*) lastReportedLocation;

	//Query location information. If the location name hasn't resolved, then the names will be nil
	@property (nonatomic, readonly) CLLocation* clLocation;
	@property (nonatomic, readonly) NSString* currentLocationName;
	@property (nonatomic, readonly) NSString* currentCityName;
	@property (nonatomic, readonly) NSString* currentStateName;
	- (BOOL) isValid;
@end


@protocol UULocationMonitoringDelegate <NSObject>
	@optional
		- (void) uuLocationChanged:(UULocation*)newLocation;
		- (void) uuLocationResolved:(UULocation*)resolvedLocation;
		- (void) uuLocationUpdateFailed:(NSError*)error;
@end


@interface UULocationMonitoring : NSObject
	+ (void) addDelegate:(NSObject<UULocationMonitoringDelegate>*)delegate;
	+ (void) removeDelegate:(NSObject<UULocationMonitoringDelegate>*)delegate;
@end


@interface UULocationMonitoringConfiguration : NSObject

	//Global settings interface.
	+ (BOOL) isAuthorizedToTrack;
	+ (BOOL) isTrackingDenied;
	+ (BOOL) canRequestTracking; // Returns NO if status is anything but kCLAuthorizationStatusNotDetermined, which will result in nothing happening when tracking is requested

	+ (void) requestStartTracking:(void(^)(BOOL authorized))callback;
	+ (void) requestStartWhenInUseTracking:(void (^)(BOOL))callback;
	+ (void) startTracking; // You should call this in your requestStartTracking handler (or when isAuthorizedToTrack) to turn on full location monitoring (heavy battery use)
	+ (void) requestStopTracking;
	+ (void) startTrackingSignificantLocationChanges; // You should call this in your requestStartTracking handler (or when isAuthorizedToTrack) to turn on sporadic location monitoring (light battery use)
	+ (void) stopTrackingSignficantLocationChanges;

	+ (CLLocationDistance) distanceThreshold;
	+ (void) setDistanceThreshold:(CLLocationDistance) distanceThreshold;

	+ (NSTimeInterval) minimumTimeThreshold;
	+ (void) setMinimumTimeThreshold:(NSTimeInterval)timeThreshold;

	+ (BOOL) locationNameReportingEnabled;
	+ (void) setLocationNameReportingEnabled:(BOOL)enabled;

	+ (BOOL) delayLocationUpdates;
	+ (void) setDelayLocationUpdates:(BOOL)delayUpdates;

	+ (NSTimeInterval) locationUpdateDelay;
	+ (void) setLocationUpdateDelay:(NSTimeInterval)updateDelay;

@end