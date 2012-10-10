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

extern const NSUInteger kDefaultZoomLevel;
extern const NSUInteger kNoCalloutZoomLevel;

@class TradePost;
@class Flyer;
@interface MapControl : NSObject<MKMapViewDelegate>
@property (nonatomic,strong) MKMapView* view;
@property (nonatomic,strong) NSObject<MKAnnotation>* trackedAnnotation;

// queries
- (NSUInteger) zoomLevel;
- (BOOL) isZoomEnabled;
- (CLLocation*) availabelLocationNearCoord:(CLLocationCoordinate2D)targetCoord;
- (NSSet*) visiblePostAnnotationsNearCoord:(CLLocationCoordinate2D)queryCoord radius:(float)radiusMeters;

// creation
- (id) initWithMapView:(MKMapView*)mapView andCenter:(CLLocationCoordinate2D)initCoord;
- (id) initWithMapView:(MKMapView*)mapView
             andCenter:(CLLocationCoordinate2D)initCoord
           atZoomLevel:(unsigned int)zoomLevel;

// setters
- (void) addAnnotationForTradePost:(TradePost*)tradePost;
- (void) addAnnotationForFlyer:(Flyer*)flyer;
- (void) addAnnotation:(NSObject<MKAnnotation>*)annotation;
- (void) dismissAnnotationForFlyer:(Flyer*)flyer;
- (void) dismissFlightPathForFlyer:(Flyer*)flyer;
- (void) dismissAllFlightPaths;
- (void) showFlightPathForFlyer:(Flyer*)flyer;
- (void) showAllFlightPaths;
- (void) centerOn:(CLLocationCoordinate2D)coord animated:(BOOL)isAnimated;
- (void) defaultZoomCenterOn:(CLLocationCoordinate2D)coord animated:(BOOL)isAnimated;
- (void) defaultZoomCenterOn:(CLLocationCoordinate2D)coord modifyMap:(BOOL)modifyMap animated:(BOOL)isAnimated;
- (void) prescanZoomCenterOn:(CLLocationCoordinate2D)coord modifyMap:(BOOL)modifyMap animated:(BOOL)isAnimated;
- (void) startTrackingAnnotation:(NSObject<MKAnnotation>*)annotation;
- (void) stopTrackingAnnotation;
- (void) centerOnFlyer:(Flyer*)flyer animated:(BOOL)isAnimated;

// deselect given annotation if it is selected;
- (void) deselectAnnotation:(NSObject<MKAnnotation>*)annotation animated:(BOOL)animated;

// deselect all annotations
- (void) deselectAllAnnotations;
- (void) removeAllAnnotations;
@end
