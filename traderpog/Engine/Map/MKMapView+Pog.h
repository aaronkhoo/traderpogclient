//
//  MKMapView+Pog.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 5/16/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface MKMapView (Pog)
+ (MKMapRect) boundingRectForCoordinateA:(CLLocationCoordinate2D)coordA coordinateB:(CLLocationCoordinate2D)coordB;
+ (CLLocationCoordinate2D) centerBetweenCoordinateA:(CLLocationCoordinate2D)coordA coordinateB:(CLLocationCoordinate2D)coordB;
+ (CLLocation*) centerOfLocationsInSet:(NSSet*)set;
+ (CLLocation*) farthestLocInSet:(NSSet*)set fromCoord:(CLLocationCoordinate2D)center;
+ (float) angleBetweenCoordinateA:(CLLocationCoordinate2D)coordA coordinateB:(CLLocationCoordinate2D)coordB;
@end
