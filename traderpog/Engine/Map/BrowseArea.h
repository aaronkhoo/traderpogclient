//
//  BrowseArea.h
//  traderpog
//
//  This is the area that bounds the player's pan and zoom on the map
//  Typically, a BrowseArea will be setup around a selected Beacon or 
//  player's flyer
//  
//  Created by Shu Chiun Cheah on 6/8/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface BrowseArea : NSObject
{
    CLLocation*             _center;
    CLLocationDistance      _radius;
    unsigned int            _minZoom;
    unsigned int            _maxZoom;
}
@property (nonatomic,strong) CLLocation* center;
@property (nonatomic) CLLocationDistance radius;
@property (nonatomic) unsigned int minZoom;
@property (nonatomic) unsigned int maxZoom;

- (id) initWithCenterLoc:(CLLocationCoordinate2D)center radius:(CLLocationDistance)radius;
- (void) setCenterCoord:(CLLocationCoordinate2D)coord;
- (CLLocationCoordinate2D) snapCoord:(CLLocationCoordinate2D)coord;
- (CLLocationCoordinate2D) snapCoord:(CLLocationCoordinate2D)coord withBufferMeters:(float)bufferMeters;
- (BOOL) isInBounds:(CLLocationCoordinate2D)coord;
- (BOOL) isInBounds:(CLLocationCoordinate2D)coord withBufferMeters:(float)bufferMeters;
@end
