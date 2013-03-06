//
//  UUMapView.m
//  ZDaySurvivor
//
//  Created by Jonathan on 3/4/13.
//  Copyright (c) 2013 3Jacks Software. All rights reserved.
//

#import "UUMapView.h"

@implementation MKMapView (UUFramework)

+ (bool) findBoundingBox:(NSArray*)annotations bounds:(MKCoordinateRegion*)boundingBox
{
    CLLocationDegrees minLat = INT_MAX;
    CLLocationDegrees maxLat = INT_MIN;
    CLLocationDegrees minLng = INT_MAX;
    CLLocationDegrees maxLng = INT_MIN;
    
    bool foundMinLat = false;
    bool foundMinLng = false;
    bool foundMaxLat = false;
    bool foundMaxLng = false;
    
    for (NSObject<MKAnnotation>* annotation in annotations)
    {
        CLLocationDegrees lat = annotation.coordinate.latitude;
        CLLocationDegrees lng = annotation.coordinate.longitude;
        if (lat != 0.0 || lng!= 0.0)
		{
			if (lat < minLat)
			{
				minLat = lat;
				foundMinLat = true;
			}
        
			if (lat > maxLat)
			{
				maxLat = lat;
				foundMaxLat = true;
			}
        
			if (lng < minLng)
			{
				minLng = lng;
				foundMinLng = true;
			}
        
			if (lng > maxLng)
			{
				maxLng = lng;
				foundMaxLng = true;
			}
		}
    }
    
    if (foundMinLat && foundMinLng && foundMaxLat && foundMaxLng)
    {
        (*boundingBox).center.latitude = minLat + ((maxLat - minLat) / 2.0f);
        (*boundingBox).center.longitude = minLng + ((maxLng - minLng) / 2.0f);
        (*boundingBox).span.latitudeDelta = fabs(maxLat - minLat);
        (*boundingBox).span.longitudeDelta = fabs(maxLng - minLng);
        return true;
    }
    else
    {
        return false;
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
