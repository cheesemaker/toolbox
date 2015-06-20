//
//  UULocation.m
//  Useful Utilities - CLLocationManager wrapper
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@silverpinesoftware.com

#import "UULocation.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UUSystemLocation
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface UUSystemLocation : NSObject<CLLocationManagerDelegate>
	+ (UUSystemLocation*) sharedLocation;
	- (id) init;

	@property (nonatomic, assign) CLLocationDistance distanceThreshold;	// Defaults to 10 meters
	@property (nonatomic, assign) NSTimeInterval timeThreshold;			// Defaults to 30 minutes (time is in seconds)
	@property (nonatomic, assign) BOOL monitorLocationName;             // Defaults to NO
	@property (nonatomic, assign) BOOL delayLocationUpdates;            // Defaults to NO
	@property (nonatomic, assign) NSTimeInterval locationUpdateDelay;   // Defaults to 1 second

	@property (atomic, strong) UULocation* lastReportedLocation;
	@property (atomic, strong) NSMutableArray* locationDelegates;
	@property (atomic, strong) NSTimer* notificationTimer;

	@property (nonatomic, strong) CLLocationManager* clLocationManager;
	@property (atomic, copy) void (^authorizationCallback)(BOOL authorized);

	- (void) startTracking;
	- (void) stopTracking;
	- (void) startTrackingSignificantLocationChanges;
	- (void) stopTrackingSignificantLocationChanges;

	- (void) addLocationChangedDelegate:(NSObject<UULocationMonitoringDelegate>*)delegate;
	- (void) removeLocationChangedDelegate:(NSObject<UULocationMonitoringDelegate>*)delegate;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UULocation
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


@interface UULocation()
	@property (nonatomic, strong) CLLocation* clLocation;
	@property (nonatomic, strong) NSString* currentLocationName;
	@property (nonatomic, strong) NSString* currentCityName;
	@property (nonatomic, strong) NSString* currentStateName;
@end

@implementation UULocation

+ (UULocation*) lastReportedLocation
{
	return [UUSystemLocation sharedLocation].lastReportedLocation;
}

- (id) init
{
	self = [super init];
	if (self)
	{
	}
	return self;
}

- (BOOL) isValid
{
    return ((self.clLocation != nil) && CLLocationCoordinate2DIsValid(self.clLocation.coordinate));
}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UULocationMonitoring
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation UULocationMonitoring

+ (void) addDelegate:(NSObject<UULocationMonitoringDelegate>*)delegate
{
	[[UUSystemLocation sharedLocation] addLocationChangedDelegate:delegate];
}

+ (void) removeDelegate:(NSObject<UULocationMonitoringDelegate>*)delegate
{
	[[UUSystemLocation sharedLocation] removeLocationChangedDelegate:delegate];
}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UULocationMonitoringConfiguration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation UULocationMonitoringConfiguration

+ (UULocation*) currentLocation
{
	return [[UUSystemLocation sharedLocation] lastReportedLocation];
}

+ (BOOL) isTrackingDenied
{
	return [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied;
}

+ (BOOL) canRequestTracking
{
	return [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined;
}

+ (BOOL) isAuthorizedToTrack
{
	return ([CLLocationManager locationServicesEnabled] && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse));
}

+ (void) requestStartTracking:(void(^)(BOOL authorized))callback
{
	[self requestTrackingWithSelector:@selector(requestAlwaysAuthorization) callback:callback];
}

+ (void)requestStartWhenInUseTracking:(void (^)(BOOL))callback
{
	[self requestTrackingWithSelector:@selector(requestWhenInUseAuthorization) callback:callback];
}

+ (void)requestTrackingWithSelector:(SEL)selector callback:(void (^)(BOOL))callback
{
	[UUSystemLocation sharedLocation].authorizationCallback = callback;
	
	CLLocationManager* locationManager = [UUSystemLocation sharedLocation].clLocationManager;
	if ([locationManager respondsToSelector:selector])
	{
		NSString* usageDescription = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"];
		NSAssert(usageDescription != nil, @"You must set a description in your plist for NSLocationAlwaysUsageDescription");
		
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[locationManager performSelector:selector];
#pragma clang diagnostic pop
	}
	else
	{
		[[UUSystemLocation sharedLocation] startTracking];
	}
}

+ (void) startTracking
{
	[[UUSystemLocation sharedLocation] startTracking];
}

+ (void) requestStopTracking
{
	[[UUSystemLocation sharedLocation] stopTracking];
}

+ (void) startTrackingSignificantLocationChanges
{
	[[UUSystemLocation sharedLocation] startTrackingSignificantLocationChanges];
}

+ (void) stopTrackingSignficantLocationChanges
{
	[[UUSystemLocation sharedLocation] stopTrackingSignificantLocationChanges];
}

+ (CLLocationDistance) distanceThreshold
{
	return [UUSystemLocation sharedLocation].distanceThreshold;
}

+ (void) setDistanceThreshold:(CLLocationDistance) distanceThreshold
{
	[UUSystemLocation sharedLocation].distanceThreshold = distanceThreshold;
}

+ (NSTimeInterval) minimumTimeThreshold
{
	return [UUSystemLocation sharedLocation].timeThreshold;
}

+ (void) setMinimumTimeThreshold:(NSTimeInterval)timeThreshold
{
	[UUSystemLocation sharedLocation].timeThreshold = timeThreshold;
}

+ (BOOL) locationNameReportingEnabled
{
	return [UUSystemLocation sharedLocation].monitorLocationName;
}

+ (void) setLocationNameReportingEnabled:(BOOL)enabled
{
	[UUSystemLocation sharedLocation].monitorLocationName = enabled;
}

+ (BOOL) delayLocationUpdates
{
	return [UUSystemLocation sharedLocation].delayLocationUpdates;
}

+ (void) setDelayLocationUpdates:(BOOL)delayUpdates
{
	[UUSystemLocation sharedLocation].delayLocationUpdates = delayUpdates;
}

+ (NSTimeInterval) locationUpdateDelay
{
	return [UUSystemLocation sharedLocation].locationUpdateDelay;
}

+ (void) setLocationUpdateDelay:(NSTimeInterval)updateDelay
{
	[UUSystemLocation sharedLocation].locationUpdateDelay = updateDelay;
}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UUSystemLocation
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation UUSystemLocation

+ (UUSystemLocation*) sharedLocation
{
	static dispatch_once_t createOnceToken;
    static UUSystemLocation* systemLocation = nil;
	dispatch_once(&createOnceToken, ^
	{
		systemLocation = [[UUSystemLocation alloc] init];
	});
	
	return systemLocation;
}

- (id) init
{
	self = [super init];
	if (self)
	{
		self.locationDelegates = [NSMutableArray array];
		
        self.distanceThreshold = 10.0f;		// 10 meters
        self.timeThreshold = 1800;			// 30 minutes
        self.monitorLocationName = NO;
        self.delayLocationUpdates = NO;
        self.locationUpdateDelay = 1.0f;	// 1 second
		
		// Initialize the locationManager
		self.clLocationManager = [[CLLocationManager alloc] init];
		self.clLocationManager.delegate = self;
		self.clLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
		self.clLocationManager.distanceFilter = 10.0f;
	}
	
	return self;
}

- (void) startTracking
{
	if ([UULocationMonitoringConfiguration isAuthorizedToTrack])
	{
		[self.clLocationManager startUpdatingLocation];
		
		if (self.clLocationManager.location)
		{
			[self checkForNewLocation:self.clLocationManager.location];
		}
	}
}

- (void) stopTracking
{
	[self.clLocationManager stopUpdatingLocation];
}

- (void) startTrackingSignificantLocationChanges
{
	if ([UULocationMonitoringConfiguration isAuthorizedToTrack])
	{
		[self.clLocationManager startMonitoringSignificantLocationChanges];
	}
}

- (void) stopTrackingSignificantLocationChanges
{
	[self.clLocationManager stopMonitoringSignificantLocationChanges];
}

- (void) addLocationChangedDelegate:(NSObject<UULocationMonitoringDelegate>*)delegate
{
	if (delegate)
	{
		[self.locationDelegates addObject:delegate];
	}
}

- (void) removeLocationChangedDelegate:(NSObject<UULocationMonitoringDelegate>*)delegate
{
	if (delegate)
	{
		[self.locationDelegates removeObject:delegate];
	}
}

- (void) checkForNewLocation:(CLLocation*)reportedLocation
{
    if ([self shouldUseLocationUpdate:reportedLocation])
	{
		UULocation* newLocation = [[UULocation alloc] init];
		newLocation.clLocation = reportedLocation;
		self.lastReportedLocation = newLocation;
		
        if (self.delayLocationUpdates)
        {
            [self.notificationTimer invalidate];
            self.notificationTimer = [NSTimer scheduledTimerWithTimeInterval:self.locationUpdateDelay target:self selector:@selector(postLocationChangedTimer:) userInfo:self.lastReportedLocation repeats:NO];
        }
        else
        {
			for (NSObject<UULocationMonitoringDelegate>* delegate in self.locationDelegates)
			{
				if ([delegate respondsToSelector:@selector(uuLocationChanged:)])
				{
					[delegate uuLocationChanged:self.lastReportedLocation];
				}
			}
		
            //[[NSNotificationCenter defaultCenter] postNotificationName:UULocationChangedNotification object:self.clLocation];
        }
	
        if (self.monitorLocationName)
        {
            [self queryLocationName:self.lastReportedLocation.clLocation];
        }
	}
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
	if (self.authorizationCallback != nil) {
		self.authorizationCallback(status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse);
		self.authorizationCallback = nil;
	}
}

- (BOOL) shouldUseLocationUpdate:(CLLocation*)reportedLocation
{
    if (!self.lastReportedLocation ||
		//!CLLocationCoordinate2DIsValid(self.clLocation.coordinate) ||
        [self.lastReportedLocation.clLocation distanceFromLocation:reportedLocation] > self.distanceThreshold ||
        [self.lastReportedLocation.clLocation.timestamp timeIntervalSinceDate:reportedLocation.timestamp] * -1.0 > self.timeThreshold ||
        reportedLocation.horizontalAccuracy < self.lastReportedLocation.clLocation.horizontalAccuracy)
	{
		return YES;
	}
	
	return NO;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
	[self checkForNewLocation:[locations lastObject]];
}

// For iOS 6
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)reportedLocation fromLocation:(CLLocation *)oldLocation;
{
	[self checkForNewLocation:reportedLocation];
}

- (void) postLocationChangedTimer:(NSTimer*)timer
{
    UULocation* location = timer.userInfo;
	for (NSObject<UULocationMonitoringDelegate>* delegate in self.locationDelegates)
	{
		if ([delegate respondsToSelector:@selector(uuLocationChanged:)])
		{
			[delegate uuLocationChanged:location];
		}
	}

    //[[NSNotificationCenter defaultCenter] postNotificationName:UULocationChangedNotification object:location];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	for (NSObject<UULocationMonitoringDelegate>* delegate in self.locationDelegates)
	{
		if ([delegate respondsToSelector:@selector(uuLocationUpdateFailed:)])
		{
			[delegate uuLocationUpdateFailed:error];
		}
	}

    //[[NSNotificationCenter defaultCenter] postNotificationName:UULocationErrorNotification object:error];
}

- (void) queryLocationName:(CLLocation*)location
{
    CLGeocoder* geoCoder = [[CLGeocoder alloc] init];
    [geoCoder reverseGeocodeLocation:location completionHandler:^(NSArray* placemarks, NSError* error)
     {
         if (error == nil && placemarks != nil && placemarks.count > 0)
         {
             CLPlacemark* info = [placemarks objectAtIndex:0];
             
             NSMutableString* sb = [NSMutableString string];
             if (info.locality != nil)
             {
                 [sb appendString:info.locality];
                 self.lastReportedLocation.currentCityName = info.locality;
             }
             
             if (info.administrativeArea != nil)
             {
                 if (sb.length > 0)
                 {
                     [sb appendString:@", "];
                 }
                 [sb appendString:info.administrativeArea];
                 self.lastReportedLocation.currentStateName = info.administrativeArea;
             }
             
             self.lastReportedLocation.currentLocationName = sb;
			 
			 for (NSObject<UULocationMonitoringDelegate>* delegate in self.locationDelegates)
			 {
			 	 if ([delegate respondsToSelector:@selector(uuLocationResolved:)])
				 {
					 [delegate uuLocationResolved:self.lastReportedLocation];
				 }
			 }
			 
             //[[NSNotificationCenter defaultCenter] postNotificationName:UULocationNameChangedNotification object:sb];
         }
     }];
}

@end

