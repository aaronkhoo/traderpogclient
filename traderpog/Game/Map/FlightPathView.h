//
//  FlightPathView.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 5/16/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <MapKit/MapKit.h>

@class FlightPathOverlay;
@interface FlightPathView : MKOverlayView
{
    __weak MKMapView* _mapView;
}
@property (nonatomic,weak) MKMapView* mapView;
@property (nonatomic,readonly) FlightPathOverlay* flightPathOverlay;
- (id) initWithFlightPathOverlay:(FlightPathOverlay*)flightPathOverlay;
@end
