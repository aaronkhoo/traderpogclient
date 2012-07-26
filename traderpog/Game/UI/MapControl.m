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
#import "BrowseArea.h"

static const NSUInteger kDefaultZoomLevel = 15;

// TODO: Rationalize placement of these constants
static const float kScanRadius = 300.0f;    // meters
static const unsigned int kScanNumPosts = 3;
static const float kBrowseAreaRadius = 900.0f;

@interface MapControl ()
{
    BrowseArea* _browseArea;
    BOOL _regionSetFromCode;
    UIPinchGestureRecognizer* _pinchRecognizer;
}
@property (nonatomic,strong) BrowseArea* browseArea;
@property (nonatomic) BOOL regionSetFromCode;
@property (nonatomic,strong) UIPinchGestureRecognizer* pinchRecognizer;
@end

@implementation MapControl
@synthesize view;
@synthesize browseArea = _browseArea;
@synthesize regionSetFromCode = _regionSetFromCode;
@synthesize pinchRecognizer = _pinchRecognizer;

- (id) initWithMapView:(MKMapView *)mapView andCenter:(CLLocationCoordinate2D)initCoord
{
    self = [super init];
    if(self)
    {
        self.view = mapView;
        mapView.delegate = self;
        [mapView setCenterCoordinate:initCoord zoomLevel:kDefaultZoomLevel animated:NO];

        _browseArea = [[BrowseArea alloc] initWithCenterLoc:initCoord radius:kBrowseAreaRadius];
        _regionSetFromCode = NO;
        self.pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
        self.pinchRecognizer.delegate = self;
        [self.view addGestureRecognizer:[self pinchRecognizer]];
    }
    return self;
}

- (void) dealloc
{
    [self.pinchRecognizer removeTarget:self action:@selector(handleGesture:)];
    [self.view removeGestureRecognizer:[self pinchRecognizer]];
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

- (void) centerOn:(CLLocationCoordinate2D)coord animated:(BOOL)isAnimated
{
    [self.view setCenterCoordinate:coord animated:isAnimated];
    [self.browseArea setCenterCoord:coord];
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

#pragma mark - UIPinchGestureRecognizer

- (void) handleGesture:(UIGestureRecognizer*)gestureRecognizer
{
    if(UIGestureRecognizerStateBegan == [gestureRecognizer state])
    {
    }
    else if(UIGestureRecognizerStateChanged == [gestureRecognizer state])
    {
    }
    else if(UIGestureRecognizerStateEnded == [gestureRecognizer state])
    {
        NSLog(@"pinch ended");
        if(![self regionSetFromCode])
        {
            if([self browseArea])
            {
                double fMinZoom = (double)[self.browseArea minZoom];
                double fZoomLevel = [self.view fZoomLevel];
                if(fZoomLevel < fMinZoom)
                {
                    // enforce bounds
                    CLLocationCoordinate2D curCenter = [self.view centerCoordinate];
                    CLLocationCoordinate2D snapCoord = curCenter;
                    if(![self.browseArea isInBounds:curCenter])
                    {
                        snapCoord = [self.browseArea snapCoord:curCenter];
                    }
                    [self.view setCenterCoordinate:snapCoord zoomLevel:[self.browseArea minZoom] animated:YES];
                    NSLog(@"rubberband started");
                    self.regionSetFromCode = YES;
                    dispatch_time_t scrollLockTimeout = dispatch_time(DISPATCH_TIME_NOW, 0.5f * NSEC_PER_SEC);
                    dispatch_after(scrollLockTimeout, dispatch_get_main_queue(), ^(void){
                        // unset set-from-code after a delay to prevent
                        // infinite loop in setCenterCoordiate and regionDidChange
                        self.regionSetFromCode = NO;
                        NSLog(@"rubberband done");
                    });
                }
            }
        }
    }
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}


@end
