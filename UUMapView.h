//
//  UUMapView.h
//  ZDaySurvivor
//
//  Created by Jonathan on 3/4/13.
//  Copyright (c) 2013 3Jacks Software. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface MKMapView (UUFramework)
	- (void) zoomToAnnotations:(bool)animated;
@end
