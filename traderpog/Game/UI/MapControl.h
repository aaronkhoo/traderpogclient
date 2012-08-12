//
//  MapControl.h
//  traderpog
//
//  This object controls the logic of a mapview.
//  It is used for organizing all the mapview related code in one place.
//  It is not to be confused with a UIViewController as it does not manage view hierarchy etc.
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class TradePost;
@class Flyer;
@interface MapControl : NSObject<MKMapViewDelegate,UIGestureRecognizerDelegate>
@property (nonatomic,strong) MKMapView* view;
@property (nonatomic,strong) NSObject<MKAnnotation>* trackedAnnotation;

- (id) initWithMapView:(MKMapView*)mapView andCenter:(CLLocationCoordinate2D)initCoord;
- (id) initWithMapView:(MKMapView*)mapView
             andCenter:(CLLocationCoordinate2D)initCoord
           atZoomLevel:(unsigned int)zoomLevel;
- (void) addAnnotationForTradePost:(TradePost*)tradePost;
- (void) addAnnotationForFlyer:(Flyer*)flyer;
- (void) addAnnotation:(NSObject<MKAnnotation>*)annotation;
- (void) dismissAnnotationForFlyer:(Flyer*)flyer;
- (void) dismissFlightPathForFlyer:(Flyer*)flyer;
- (void) showFlightPathForFlyer:(Flyer*)flyer;
- (void) centerOn:(CLLocationCoordinate2D)coord animated:(BOOL)isAnimated;
- (void) startTrackingAnnotation:(NSObject<MKAnnotation>*)annotation;
- (void) stopTrackingAnnotation;
@end
