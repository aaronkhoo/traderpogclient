//
//  BrowseArea.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 6/8/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "BrowseArea.h"
#import <MapKit/MapKit.h>

static const unsigned int kDefaultMinZoom = 8;

@implementation BrowseArea
@synthesize center = _center;
@synthesize radius = _radius;
@synthesize minZoom = _minZoom;

- (id) initWithCenterLoc:(CLLocationCoordinate2D)centerCoord radius:(CLLocationDistance)radius
{
    self = [super init];
    if(self)
    {
        _center = [[CLLocation alloc] initWithLatitude:centerCoord.latitude longitude:centerCoord.longitude];
        _radius = radius;
        _minZoom = kDefaultMinZoom;
    }
    return self;
}

- (void) setCenterCoord:(CLLocationCoordinate2D)coord
{
    self.center = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
}

#pragma mark - out of bounds queries
- (CLLocationCoordinate2D) snapCoord:(CLLocationCoordinate2D)coord
{
    CLLocationCoordinate2D snapCoord = [self snapCoord:coord withBufferMeters:0.0f];
    return snapCoord;
}

- (CLLocationCoordinate2D) snapCoord:(CLLocationCoordinate2D)coord withBufferMeters:(float)bufferMeters
{
    CLLocation* queryLoc = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
    CLLocationDistance distMeters = [self.center distanceFromLocation:queryLoc];
    
    CLLocationCoordinate2D snapCoord = coord;
    if([self radius] < distMeters)
    {
        MKMapPoint srcPoint = MKMapPointForCoordinate([self.center coordinate]);
        MKMapPoint destPoint = MKMapPointForCoordinate(coord);
        MKMapPoint routeVec = MKMapPointMake(destPoint.x - srcPoint.x, destPoint.y - srcPoint.y);
        double distPoints = sqrt((routeVec.x * routeVec.x) + (routeVec.y * routeVec.y));
        MKMapPoint routeVecNormalized = MKMapPointMake(routeVec.x / distPoints, routeVec.y / distPoints);
        double snapDistPoints = (([self radius] - bufferMeters) / distMeters) * distPoints;
        MKMapPoint snapPoint = MKMapPointMake(srcPoint.x + (snapDistPoints * routeVecNormalized.x),
                                              srcPoint.y + (snapDistPoints * routeVecNormalized.y));
        snapCoord = MKCoordinateForMapPoint(snapPoint);
    }
    
    return snapCoord;
}

- (BOOL) isInBounds:(CLLocationCoordinate2D)coord
{
    BOOL result = YES;
    result = [self isInBounds:coord withBufferMeters:0.0f];
    return result;
}

- (BOOL) isInBounds:(CLLocationCoordinate2D)coord withBufferMeters:(float)bufferMeters
{
    BOOL result = YES;
    CLLocation* queryLoc = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
    CLLocationDistance distMeters = [self.center distanceFromLocation:queryLoc];
    if(([self radius] + bufferMeters) < distMeters)
    {
        result = NO;
    }
    return result;
}

@end
