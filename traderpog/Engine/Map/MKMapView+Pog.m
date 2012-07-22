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

+ (float) angleBetweenCoordinateA:(CLLocationCoordinate2D)coordA coordinateB:(CLLocationCoordinate2D)coordB
{
    float angle = 0.0f;
    MKMapPoint pointA = MKMapPointForCoordinate(coordA);
    MKMapPoint pointB = MKMapPointForCoordinate(coordB);
    
    MKMapPoint routeVec = MKMapPointMake(pointB.x - pointA.x, pointB.y - pointA.y);
    double magnitude = sqrt(routeVec.x * routeVec.x + routeVec.y * routeVec.y);
    routeVec.x /= magnitude;
    routeVec.y /= magnitude;
    
    // MKMapPoint x-positive points to the right and y-positive points down
    // this is the same as CGAffineTransform, which is zero-angle at x-positive,
    // and positive angle is clockwise
    angle = atan2(routeVec.y, routeVec.x);
    
    return angle;
}

@end
