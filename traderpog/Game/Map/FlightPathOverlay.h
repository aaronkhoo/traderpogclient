//
//  FlightPathOverlay.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 5/16/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <pthread.h>

@interface FlightPathOverlay : NSObject<MKOverlay>
{
    CLLocationCoordinate2D _srcCoord;
    CLLocationCoordinate2D _destCoord;
    CLLocationCoordinate2D _curCoord;
    
    pthread_rwlock_t rwLock;
}
@property (atomic) CLLocationCoordinate2D srcCoord;
@property (atomic) CLLocationCoordinate2D destCoord;
@property (atomic) CLLocationCoordinate2D curCoord;

- (id) initWithSrcCoord:(CLLocationCoordinate2D)src destCoord:(CLLocationCoordinate2D)dest;
- (MKMapPoint) midMapPoint;

- (MKMapRect) addCoordinate:(CLLocationCoordinate2D)coord atZoomLevel:(NSUInteger)zoomLevel;
- (MKMapRect) curUpdateRect;

- (void) lockForReading;
- (void) unlockForReading;
- (void) lockForWriting;
- (void) unlockForWriting;
@end
