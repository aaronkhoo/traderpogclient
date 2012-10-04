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
#import "FlyerMgr.h"
#import "BrowseArea.h"
#import "CalloutAnnotationView.h"
#import "FlyerAnnotationView.h"
#import "MKMapView+Pog.h"
#import "BrowsePinch.h"
#import "MapGestureHandler.h"
#import "PlayerPostCalloutView.h"

const NSUInteger kDefaultZoomLevel = 15;
const NSUInteger kNoCalloutZoomLevel = kDefaultZoomLevel - 2;
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
    
    MapGestureHandler* _gestureHandler;
    UIPanGestureRecognizer* _panRecognizer;
}
@property (nonatomic,strong) BrowseArea* browseArea;
@property (nonatomic) BOOL regionSetFromCode;
@property (nonatomic,strong) UIPinchGestureRecognizer* pinchRecognizer;
@property (nonatomic,strong) BrowsePinch* pinchHandler;

- (void) internalInitWithMapView:(MKMapView*)mapView
                          center:(CLLocationCoordinate2D)initCoord
                       zoomLevel:(unsigned int)zoomLevel;
- (void) zoom:(NSUInteger) zoomLevel centerOn:(CLLocationCoordinate2D)coord modifyMap:(BOOL)modifyMap animated:(BOOL)isAnimated;
@end

@implementation MapControl
@synthesize view;
@synthesize browseArea = _browseArea;
@synthesize regionSetFromCode = _regionSetFromCode;
@synthesize pinchRecognizer = _pinchRecognizer;
@synthesize pinchHandler = _pinchHandler;
@synthesize trackedAnnotation;

- (NSUInteger) zoomLevel
{
    return [self.view zoomLevel];
}

- (BOOL) isZoomEnabled
{
    return [self.view isZoomEnabled];
}

#pragma mark - public methods

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
    
    _gestureHandler = [[MapGestureHandler alloc] initWithMap:self];
    _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:_gestureHandler action:@selector(handlePanGesture:)];
    _panRecognizer.delegate = _gestureHandler;
    [self.view addGestureRecognizer:_panRecognizer];
    
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
    [self.view removeGestureRecognizer:[self pinchRecognizer]];
    [self.view removeGestureRecognizer:_panRecognizer];
}

- (void) addAnnotationForTradePost:(TradePost *)tradePost
{
    NSArray* existingAnnotations = [self.view annotations];
    if(![existingAnnotations containsObject:tradePost])
    {
        [self.view addAnnotation:tradePost];
    }
}

- (void) addAnnotationForFlyer:(Flyer *)flyer
{
    NSArray* existingAnnotations = [self.view annotations];
    if(![existingAnnotations containsObject:flyer])
    {
        [self.view addAnnotation:flyer];
    }
}

- (void) addAnnotation:(NSObject<MKAnnotation> *)annotation
{
    NSArray* existingAnnotations = [self.view annotations];
    if(![existingAnnotations containsObject:annotation])
    {
        [self.view addAnnotation:annotation];
    }
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
    
    FlyerAnnotationView* flyerAnnotView = (FlyerAnnotationView*)[self.view viewForAnnotation:flyer];
    if(flyerAnnotView)
    {
        [flyerAnnotView showCountdown:NO];
    }
}

- (void) dismissAllFlightPaths
{
    for(Flyer* cur in [[FlyerMgr getInstance] playerFlyers])
    {
        [self dismissFlightPathForFlyer:cur];
    }
}

- (void) showFlightPathForFlyer:(Flyer *)flyer
{
    if([flyer flightPathRender])
    {
        [self.view addOverlay:[flyer flightPathRender]];
    }
    FlyerAnnotationView* flyerAnnotView = (FlyerAnnotationView*)[self.view viewForAnnotation:flyer];
    if(flyerAnnotView)
    {
        [flyerAnnotView showCountdown:YES];
    }
}

- (void) showAllFlightPaths
{
    for(Flyer* cur in [[FlyerMgr getInstance] playerFlyers])
    {
        [self showFlightPathForFlyer:cur];
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
    [self defaultZoomCenterOn:coord modifyMap:YES animated:isAnimated];
}
static const NSTimeInterval kFlightPathsDelay = 1.0;

- (void) defaultZoomCenterOn:(CLLocationCoordinate2D)coord modifyMap:(BOOL)modifyMap animated:(BOOL)isAnimated
{
    [self zoom:kDefaultZoomLevel centerOn:coord modifyMap:modifyMap animated:isAnimated];
}

- (void) prescanZoomCenterOn:(CLLocationCoordinate2D)coord modifyMap:(BOOL)modifyMap animated:(BOOL)isAnimated
{
    [self zoom:kDefaultZoomLevel-2 centerOn:coord modifyMap:modifyMap animated:isAnimated];
}

- (void) zoom:(NSUInteger) zoomLevel centerOn:(CLLocationCoordinate2D)coord modifyMap:(BOOL)modifyMap animated:(BOOL)isAnimated
{
    // stop any ongoing tracking
    [self stopTrackingAnnotation];
    
    // center the map and browse area
    if(modifyMap)
    {
        [self dismissAllFlightPaths];
        [self.view setCenterCoordinate:coord zoomLevel:zoomLevel animated:isAnimated];
        dispatch_time_t flightPathsDelay = dispatch_time(DISPATCH_TIME_NOW, kFlightPathsDelay * NSEC_PER_SEC);
        dispatch_after(flightPathsDelay, dispatch_get_main_queue(), ^(void){
            [self showAllFlightPaths];
        });
    }
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

- (void) deselectAnnotation:(NSObject<MKAnnotation> *)annotation animated:(BOOL)animated
{
    if([[self.view selectedAnnotations] containsObject:annotation])
    {
        [self.view deselectAnnotation:annotation animated:animated];
    }
}

- (void) deselectAllAnnotations
{
    for(NSObject<MKAnnotation>* cur in [self.view selectedAnnotations])
    {
        [self.view deselectAnnotation:cur animated:NO];
    }
}

- (void) removeAllAnnotations
{
    for(NSObject<MKAnnotation>* cur in [self.view annotations])
    {
        [self.view removeAnnotation:cur];
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

- (void) forceRefreshAnnotationForTradePost:(TradePost *)tradePost
{
    // remove and re-add to force a redraw
    // this seems to be the only reliable way that works
    [self.view removeAnnotation:tradePost];
    [self addAnnotationForTradePost:tradePost];
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
    // do nothing
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
            [flyerAnnotView setRenderTransformWithAngle:[flyer angle]];
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
