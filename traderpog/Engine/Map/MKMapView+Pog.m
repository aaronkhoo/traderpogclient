//
//  MKMapView+Pog.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 5/16/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "MKMapView+Pog.h"

@implementation MKMapView (Pog)

+ (MKMapRect) boundingRectForCoordinateA:(CLLocationCoordinate2D)coordA coordinateB:(CLLocationCoordinate2D)coordB
{
    MKMapPoint pointA = MKMapPointForCoordinate(coordA);
    MKMapPoint pointB = MKMapPointForCoordinate(coordB);
    
    MKMapRect boundingRect = MKMapRectMake(fmin(pointA.x, pointB.x), fmin(pointA.y, pointB.y),
                                           fabs(pointA.x - pointB.x), fabs(pointA.y - pointB.y));
    
    return boundingRect;
}

+ (CLLocationCoordinate2D) centerBetweenCoordinateA:(CLLocationCoordinate2D)coordA coordinateB:(CLLocationCoordinate2D)coordB
{
    MKMapPoint pointA = MKMapPointForCoordinate(coordA);
    MKMapPoint pointB = MKMapPointForCoordinate(coordB);

    MKMapPoint routeVec = MKMapPointMake(pointB.x - pointA.x, pointB.y - pointA.y);
    MKMapPoint midPoint = MKMapPointMake(pointA.x + (0.5f * routeVec.x), pointA.y + (0.5f * routeVec.y));
    
    CLLocationCoordinate2D midCoord = MKCoordinateForMapPoint(midPoint);
    return midCoord;
}
@end
