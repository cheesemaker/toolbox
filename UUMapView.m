//
//  UUMapView.m
//  ZDaySurvivor
//
//  Created by Jonathan on 3/4/13.
//  Copyright (c) 2013 3Jacks Software. All rights reserved.
//

#import "UUMapView.h"

@implementation MKMapView (UUFramework)

+ (BOOL) findBoundingBox:(NSArray*)annotations bounds:(MKCoordinateRegion*)boundingBox
{
    CLLocationDegrees minLat = INT_MAX;
    CLLocationDegrees maxLat = INT_MIN;
    CLLocationDegrees minLng = INT_MAX;
    CLLocationDegrees maxLng = INT_MIN;
    
    BOOL foundMinLat = NO;
    BOOL foundMinLng = NO;
    BOOL foundMaxLat = NO;
    BOOL foundMaxLng = NO;
    
    for (NSObject<MKAnnotation>* annotation in annotations)
    {
        CLLocationDegrees lat = annotation.coordinate.latitude;
        CLLocationDegrees lng = annotation.coordinate.longitude;
        
        if (lat < minLat)
        {
            minLat = lat;
            foundMinLat = YES;
        }
        
        if (lat > maxLat)
        {
            maxLat = lat;
            foundMaxLat = YES;
        }
        
        if (lng < minLng)
        {
            minLng = lng;
            foundMinLng = YES;
        }
        
        if (lng > maxLng)
        {
            maxLng = lng;
            foundMaxLng = YES;
        }
    }
    
    if (foundMinLat && foundMinLng && foundMaxLat && foundMaxLng)
    {
        (*boundingBox).center.latitude = minLat + ((maxLat - minLat) / 2.0f);
        (*boundingBox).center.longitude = minLng + ((maxLng - minLng) / 2.0f);
        (*boundingBox).span.latitudeDelta = fabs(maxLat - minLat);
        (*boundingBox).span.longitudeDelta = fabs(maxLng - minLng);
        return YES;
    }
    else
    {
        return NO;
    }
}

- (void) zoomToAnnotations:(bool)animated
{
	MKCoordinateRegion region;
	if ([MKMapView findBoundingBox:self.annotations bounds:&region])
	{
		region = [self regionThatFits:region];
		[self setRegion:region animated:animated];
	}
}

@end
