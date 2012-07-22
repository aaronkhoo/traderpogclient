//
//  FlightPathOverlay.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 5/16/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlightPathOverlay.h"
#import "MKMapView+Pog.h"

@interface FlightPathOverlay ()
{
    unsigned int _segmentBegin;
    CLLocationCoordinate2D _prevCoord;  // previous curCoord; for computing bounding rect purposes;
}
@end

@implementation FlightPathOverlay

- (id) initWithSrcCoord:(CLLocationCoordinate2D)src destCoord:(CLLocationCoordinate2D)dest
{
    self = [super init];
    if(self)
    {
        _srcCoord = src;
        _destCoord = dest;
        _curCoord = src;
        _prevCoord = src;
        
        _segmentBegin = 0;

        // initialize read-write lock for drawing and updates
        pthread_rwlock_init(&rwLock, NULL);
    }
    return self;
}

- (void) dealloc
{
    pthread_rwlock_destroy(&rwLock);
}

- (CLLocationCoordinate2D) srcCoord
{
    return _srcCoord;
}

- (void) setSrcCoord:(CLLocationCoordinate2D)srcCoord
{
    _srcCoord = srcCoord;
}

- (CLLocationCoordinate2D) destCoord
{
    return _destCoord;
}

- (void) setDestCoord:(CLLocationCoordinate2D)destCoord
{
    _destCoord = destCoord;
}

- (CLLocationCoordinate2D) curCoord
{
    return _curCoord;
}

- (void) setCurCoord:(CLLocationCoordinate2D)curCoord
{
    _prevCoord = _curCoord;
    _curCoord = curCoord;
}

- (MKMapPoint) midMapPoint
{
    CLLocationCoordinate2D midCoord = [MKMapView centerBetweenCoordinateA:[self srcCoord] coordinateB:[self destCoord]];
    return MKMapPointForCoordinate(midCoord);
}

- (MKMapRect) addCoordinate:(CLLocationCoordinate2D)coord atZoomLevel:(NSUInteger)zoomLevel
{
    [self setCurCoord:coord];
    MKMapRect updateRect = MKMapRectNull;
    
    return updateRect;
}

static double minWidth = 10.0;
static double minHeight = 10.0;

- (MKMapRect) curUpdateRect
{
    MKMapPoint pointA = MKMapPointForCoordinate(_prevCoord);
    MKMapPoint pointB = MKMapPointForCoordinate(_curCoord);
    
    double minX = MIN(pointA.x, pointB.x);
    double minY = MIN(pointA.y, pointB.y);
    double maxX = MAX(pointA.x, pointB.x);
    double maxY = MAX(pointA.y, pointB.y);
    
    //NSLog(@"update (%lf, %lf) (%lf, %lf)", minX, minY, maxX, maxY);
    if((maxX - minX) <= minWidth)
    {
        minX -= 0.5 * minWidth;
        maxX += 0.5 * minWidth;
        //NSLog(@"adjustedX (%lf, %lf) (%lf, %lf)", minX, minY, maxX - minX, maxY - minY);
    }
    if((maxY - minY) <= minHeight)
    {
        minY -= 0.5 * minHeight;
        maxY += 0.5 * minHeight;
        //NSLog(@"adjustedY (%lf, %lf) (%lf, %lf)", minX, minY, maxX - minX, maxY - minY);
    }
    
    MKMapRect updateRect = MKMapRectMake(minX, minY, maxX - minX, maxY - minY);

    //NSLog(@"updateRect (%lf, %lf, %lf, %lf)", updateRect.origin.x, updateRect.origin.y, updateRect.size.width, updateRect.size.height);
    //NSLog(@"");
    return updateRect;
}

- (void)lockForReading
{
    pthread_rwlock_rdlock(&rwLock);
}

- (void)unlockForReading
{
    pthread_rwlock_unlock(&rwLock);
}

- (void)lockForWriting
{
    pthread_rwlock_wrlock(&rwLock);
}

- (void)unlockForWriting
{
    pthread_rwlock_unlock(&rwLock);
}

#pragma mark - MKOverlay

- (CLLocationCoordinate2D) coordinate
{
    return [MKMapView centerBetweenCoordinateA:[self srcCoord] coordinateB:[self destCoord]];
}

- (MKMapRect) boundingMapRect
{
    MKMapRect routeRect = [MKMapView boundingRectForCoordinateA:[self srcCoord] 
                                                    coordinateB:[self destCoord]];
    return routeRect;
}

@end
