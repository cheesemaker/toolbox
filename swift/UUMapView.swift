//
//  UUMapView.swift
//  Useful Utilities - Helpful methods for MKMapView
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

import UIKit
import MapKit

public extension MKMapView
{
    public static func uuFindBoundingBox(annotations: [MKAnnotation]) -> MKCoordinateRegion?
    {
        var minLat : CLLocationDegrees = CLLocationDegrees(Int.max)
        var maxLat : CLLocationDegrees = CLLocationDegrees(Int.min)
        var minLng : CLLocationDegrees = CLLocationDegrees(Int.max)
        var maxLng : CLLocationDegrees = CLLocationDegrees(Int.min)
        
        var foundMinLat : Bool = false
        var foundMinLng : Bool  = false
        var foundMaxLat : Bool  = false
        var foundMaxLng : Bool  = false
        
        for annotation in annotations
        {
            if (annotation.isKind(of: MKUserLocation.classForCoder()))
            {
                continue
            }
            
            let lat = annotation.coordinate.latitude
            let lng = annotation.coordinate.longitude
            
            if (lat != 0.0 || lng != 0.0)
            {
                if (lat < minLat)
                {
                    minLat = lat
                    foundMinLat = true
                }
                
                if (lat > maxLat)
                {
                    maxLat = lat
                    foundMaxLat = true
                }
                
                if (lng < minLng)
                {
                    minLng = lng
                    foundMinLng = true
                }
                
                if (lng > maxLng)
                {
                    maxLng = lng
                    foundMaxLng = true
                }
            }
        }
        
        if (foundMinLat && foundMinLng && foundMaxLat && foundMaxLng)
        {
            var boundingBox : MKCoordinateRegion = MKCoordinateRegion()
            boundingBox.center.latitude = minLat + ((maxLat - minLat) / 2.0)
            boundingBox.center.longitude = minLng + ((maxLng - minLng) / 2.0)
            boundingBox.span.latitudeDelta = fabs(maxLat - minLat)
            boundingBox.span.longitudeDelta = fabs(maxLng - minLng)
            return boundingBox
        }
        else
        {
            return nil
        }
    }
    
    public func uuZoomToAnnotations(animated: Bool, center: CLLocationCoordinate2D? = nil)
    {
        var region = MKMapView.uuFindBoundingBox(annotations: annotations)
        if (region != nil)
        {
            if (center != nil && CLLocationCoordinate2DIsValid(center!))
            {
                region!.center.latitude = center!.latitude
                region!.center.longitude = center!.longitude
            }
            
            let adjustedRegion = regionThatFits(region!)
            setRegion(adjustedRegion, animated: animated)
        }
    }
}
