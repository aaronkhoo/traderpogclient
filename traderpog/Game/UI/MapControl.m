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
#import "FlightPathOverlay.h"
#import "FlightPathView.h"
#import "Flyer.h"
#import "BrowseArea.h"
#import "CalloutAnnotationView.h"
#import "FlyerAnnotationView.h"
#import "MKMapView+Pog.h"
#import "BrowsePan.h"
#import "BrowsePinch.h"
#import "PlayerPostCalloutView.h"

static const NSUInteger kDefaultZoomLevel = 15;
static NSString* const kKeyCoordinate = @"coordinate";

// TODO: Rationalize placement of these constants
static const float kScanRadius = 300.0f;    // meters
static const unsigned int kScanNumPosts = 3;
static const float kBrowseAreaRadius = 500.0f;

@interface MapControl ()
{
    BrowseArea* _browseArea;
    BOOL _regionSetFromCode;
    UIPinchGestureRecognizer* _pinchRecognizer;
    BrowsePinch* _pinchHandler;
    UIPanGestureRecognizer* _panRecognizer;
    BrowsePan* _panHandler;
}
@property (nonatomic,strong) BrowseArea* browseArea;
@property (nonatomic) BOOL regionSetFromCode;
@property (nonatomic,strong) UIPinchGestureRecognizer* pinchRecognizer;
@property (nonatomic,strong) BrowsePinch* pinchHandler;
@property (nonatomic,strong) UIPanGestureRecognizer* panRecognizer;
@property (nonatomic,strong) BrowsePan* panHandler;

- (void) internalInitWithMapView:(MKMapView*)mapView
                          center:(CLLocationCoordinate2D)initCoord
                       zoomLevel:(unsigned int)zoomLevel;
@end

@implementation MapControl
@synthesize view;
@synthesize browseArea = _browseArea;
@synthesize regionSetFromCode = _regionSetFromCode;
@synthesize pinchRecognizer = _pinchRecognizer;
@synthesize pinchHandler = _pinchHandler;
@synthesize panRecognizer = _panRecognizer;
@synthesize panHandler = _panHandler;
@synthesize trackedAnnotation;

- (void) internalInitWithMapView:(MKMapView *)mapView
                          center:(CLLocationCoordinate2D)initCoord
                       zoomLevel:(unsigned int)zoomLevel
{
    self.view = mapView;
    mapView.delegate = self;
    [mapView setCenterCoordinate:initCoord zoomLevel:zoomLevel animated:NO];
    
    _browseArea = [[BrowseArea alloc] initWithCenterLoc:initCoord radius:kBrowseAreaRadius];
    _regionSetFromCode = NO;
    self.pinchHandler = [[BrowsePinch alloc] initWithMap:self browseArea:_browseArea];
    self.pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:[self pinchHandler] action:@selector(handleGesture:)];
    self.pinchRecognizer.delegate = [self pinchHandler];
    [self.view addGestureRecognizer:[self pinchRecognizer]];
    
    self.panHandler = [[BrowsePan alloc] initWithMap:self browseArea:_browseArea];
    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:[self panHandler] action:@selector(handleGesture:)];
    self.panRecognizer.delegate = [self panHandler];
    [self.view addGestureRecognizer:[self panRecognizer]];
    
    self.trackedAnnotation = nil;
}

- (id) initWithMapView:(MKMapView *)mapView andCenter:(CLLocationCoordinate2D)initCoord
{
    self = [super init];
    if(self)
    {
        [self internalInitWithMapView:mapView
                               center:initCoord
                            zoomLevel:kDefaultZoomLevel];
    }
    return self;
}

- (id) initWithMapView:(MKMapView*)mapView
             andCenter:(CLLocationCoordinate2D)initCoord
           atZoomLevel:(unsigned int)zoomLevel
{
    self = [super init];
    if(self)
    {
        [self internalInitWithMapView:mapView
                               center:initCoord
                            zoomLevel:zoomLevel];
    }
    return self;
}


- (void) dealloc
{
    [self stopTrackingAnnotation];
    [self.view removeGestureRecognizer:[self panRecognizer]];
    [self.view removeGestureRecognizer:[self pinchRecognizer]];
}

- (void) addAnnotationForTradePost:(TradePost *)tradePost
{
    [self.view addAnnotation:tradePost];
}

- (void) addAnnotationForFlyer:(Flyer *)flyer
{
    [self.view addAnnotation:flyer];
}

- (void) addAnnotation:(NSObject<MKAnnotation> *)annotation
{
    [self.view addAnnotation:annotation];
}

- (void) dismissAnnotationForFlyer:(Flyer *)flyer
{
    [self.view removeAnnotation:flyer];
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
    // stop any ongoing tracking
    [self stopTrackingAnnotation];
    
    // center the map and browse area
    [self.view setCenterCoordinate:coord animated:isAnimated];
    [self.browseArea setCenterCoord:coord];
    [self.browseArea setRadius:kBrowseAreaRadius];

    // enable zoom in case we previously viewed a non-zoomable mode
    self.view.zoomEnabled = YES;
    self.pinchRecognizer.enabled = YES;
}

- (void) defaultZoomCenterOn:(CLLocationCoordinate2D)coord animated:(BOOL)isAnimated
{
    // stop any ongoing tracking
    [self stopTrackingAnnotation];
    
    // center the map and browse area
    [self.view setCenterCoordinate:coord zoomLevel:kDefaultZoomLevel animated:isAnimated];
    [self.browseArea setCenterCoord:coord];
    [self.browseArea setRadius:kBrowseAreaRadius];

    // enable zoom in case we previously viewed a non-zoomable mode
    self.view.zoomEnabled = YES;
    self.pinchRecognizer.enabled = YES;
}

- (void) centerOnFlyer:(Flyer *)flyer animated:(BOOL)isAnimated
{
    if([[flyer path] isEnroute])
    {
        // focus map on the route
        CLLocationCoordinate2D srcCoord = [[flyer path] srcCoord];
        CLLocationCoordinate2D destCoord = [[flyer path] destCoord];
        
        MKMapRect routeRect = [MKMapView boundingRectForCoordinateA:srcCoord coordinateB:destCoord];
        UIEdgeInsets padding = UIEdgeInsetsMake(20.0f, 5.0f, 20.0f, 5.0f);
        [self.view setVisibleMapRect:routeRect edgePadding:padding animated:YES];
        
        // center browse area on center of the rectangle with radius equal to
        // half of the height of the rectangle
        MKMapPoint rectCenter = MKMapPointMake(routeRect.origin.x + (0.5f * routeRect.size.width),
                                               routeRect.origin.y + (0.5f * routeRect.size.height));
        CLLocationCoordinate2D centerCoord = MKCoordinateForMapPoint(rectCenter);
        [self.browseArea setCenterCoord:centerCoord];
        MKMapPoint rectBL = MKMapPointMake(routeRect.origin.x,
                                           routeRect.origin.y + routeRect.size.height);
        CLLocationDistance heightMeters = MKMetersBetweenMapPoints(routeRect.origin, rectBL);
        [self.browseArea setRadius:heightMeters * 0.5f];

        // disable zoom for enroute Flyer
        self.view.zoomEnabled = NO;
        self.pinchRecognizer.enabled = NO;
    }
    else
    {
        [self defaultZoomCenterOn:[flyer coordinate] animated:isAnimated];
    }
}

- (void) startTrackingAnnotation:(NSObject<MKAnnotation> *)annotation
{
    if([self trackedAnnotation] != annotation)
    {
        [self stopTrackingAnnotation];
        
        NSLog(@"start tracking");
        [annotation addObserver:self forKeyPath:kKeyCoordinate options:0 context:nil];
        self.trackedAnnotation = annotation;
    }
}

- (void) stopTrackingAnnotation
{
    if([self trackedAnnotation])
    {
        NSLog(@"stop tracking");
        [self.trackedAnnotation removeObserver:self forKeyPath:kKeyCoordinate];
        self.trackedAnnotation = nil;
    }
}

- (void) deselectAllAnnotations
{
    for(NSObject<MKAnnotation>* cur in [self.view selectedAnnotations])
    {
        [self.view deselectAnnotation:cur animated:NO];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
    if(([keyPath isEqualToString:kKeyCoordinate]) &&
       ([object isMemberOfClass:[Flyer class]]))
    {
        NSObject<MKAnnotation>* annotation = (NSObject<MKAnnotation>*)object;
        [self.view setCenterCoordinate:[annotation coordinate] animated:NO];
        [self.browseArea setCenterCoord:[annotation coordinate]];
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
    if([self.panHandler isPanEnding])
    {
        [self.panHandler enforceBrowseArea];
    }
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
        if([[cur annotation] isKindOfClass:[Flyer class]])
        {
            [[cur superview] bringSubviewToFront:cur];

            Flyer* flyer = (Flyer*)[cur annotation];
            FlyerAnnotationView* flyerAnnotView = (FlyerAnnotationView*)cur;
            [flyerAnnotView setRenderTransform:[flyer transform]];
        }
        else if(([cur isKindOfClass:[CalloutAnnotationView class]]) ||
                ([cur isKindOfClass:[PlayerPostCalloutView class]]))
        {
            [[cur superview] bringSubviewToFront:cur];
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
