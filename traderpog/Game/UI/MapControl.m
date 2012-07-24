//
//  MapControl.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "MapControl.h"
#import "MKMapView+ZoomLevel.h"
#import "TradePostMgr.h"
#import "TradePost.h"
#import "TradePostAnnotation.h"
#import "FlightPathOverlay.h"
#import "FlightPathView.h"
#import "Flyer.h"
#import "FlyerAnnotation.h"

static const NSUInteger kDefaultZoomLevel = 15;

// TODO: Rationalize placement of these constants
static const float kScanRadius = 300.0f;    // meters
static const unsigned int kScanNumPosts = 3;

@implementation MapControl
@synthesize view;

- (id) initWithMapView:(MKMapView *)mapView andCenter:(CLLocationCoordinate2D)initCoord
{
    self = [super init];
    if(self)
    {
        self.view = mapView;
        mapView.delegate = self;
        [mapView setCenterCoordinate:initCoord zoomLevel:kDefaultZoomLevel animated:NO];
    }
    return self;
}

#pragma mark - annotations
- (void) refreshMap:(CLLocationCoordinate2D)coord 
{
    // Start by removing all annotations on the map
    [view removeAnnotations:view.annotations];
    
    // Get the array of posts in the vicinity
    NSArray* postsArray = [[TradePostMgr getInstance] getTradePostsAtCoord:coord radius:kScanRadius maxNum:kScanNumPosts];
    
    // Create an array of annotations from posts
    NSMutableArray* postsAnnotationArray = [[NSMutableArray alloc] init];
    for (TradePost* post in postsArray)
    {
        TradePostAnnotation* annotation = [[TradePostAnnotation alloc] initWithTradePost:post];
        [postsAnnotationArray addObject:annotation];
    }
    
    // Put the posts onto the map
    [view addAnnotations:postsAnnotationArray];
}

- (void) addAnnotationForTradePost:(TradePost *)tradePost
{
    if(![tradePost annotation])
    {
        TradePostAnnotation* annotation = [[TradePostAnnotation alloc] initWithTradePost:tradePost];
        [self.view addAnnotation:annotation];
    }
}

- (void) addAnnotationForFlyer:(Flyer *)flyer
{
    if(![flyer annotation])
    {
        FlyerAnnotation* annotation = [[FlyerAnnotation alloc] initWithFlyer:flyer];
        [self.view addAnnotation:annotation];
        flyer.annotation = annotation;
    }
}

- (void) dismissAnnotationForFlyer:(Flyer *)flyer
{
    if([flyer annotation])
    {
        [self.view removeAnnotation:[flyer annotation]];
        flyer.annotation = nil;
    }
}

- (void) dismissFlightPathForFlyer:(Flyer*)flyer
{
    if([flyer flightPathRender])
    {
        [self.view removeOverlay:[flyer flightPathRender]];
    }
}

- (void) showFlightPathForFlyer:(Flyer *)flyer
{
    if([flyer flightPathRender])
    {
        [self.view addOverlay:[flyer flightPathRender]];
    }
}

#pragma mark MKMapViewDelegate
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    // do nothing
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
}


- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
}

- (void)mapView:(MKMapView*)mapView didSelectAnnotationView:(MKAnnotationView *)annotationView
{
    if([annotationView conformsToProtocol:@protocol(MapAnnotationViewProtocol)])
    {
        [((NSObject<MapAnnotationViewProtocol>*)annotationView) didSelectAnnotationViewInMap:mapView];
    }
}

- (void)mapView:(MKMapView*)mapView didDeselectAnnotationView:(MKAnnotationView *)annotationView
{
    if([annotationView conformsToProtocol:@protocol(MapAnnotationViewProtocol)])
    {
        [((NSObject<MapAnnotationViewProtocol>*)annotationView) didDeselectAnnotationViewInMap:mapView];
    }
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    for(MKAnnotationView* cur in views) 
    {
        if([[cur annotation] isKindOfClass:[FlyerAnnotation class]])
        {
            // from Flyer annotation to the front
            [[cur superview] bringSubviewToFront:cur];
            break;
        }
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    MKAnnotationView* result = nil;
    if([annotation conformsToProtocol:@protocol(MapAnnotationProtocol)])
    {
        result = [((NSObject<MapAnnotationProtocol>*)annotation) annotationViewInMap:mapView];
    }
    return result;
}


- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay 
{
	MKOverlayView *result = nil;
    
    FlightPathView* pathView = [[FlightPathView alloc] initWithFlightPathOverlay:overlay];
    pathView.mapView = mapView;
    result = pathView;
    
	return result;
}


@end
