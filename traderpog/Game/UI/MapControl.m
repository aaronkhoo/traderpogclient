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

static const NSUInteger kDefaultZoomLevel = 15;
static NSString* const kKeyCoordinate = @"coordinate";

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

- (void) internalInitWithMapView:(MKMapView*)mapView
                          center:(CLLocationCoordinate2D)initCoord
                       zoomLevel:(unsigned int)zoomLevel;
@end

@implementation MapControl
@synthesize view;
@synthesize browseArea = _browseArea;
@synthesize regionSetFromCode = _regionSetFromCode;
@synthesize pinchRecognizer = _pinchRecognizer;
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
    self.pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    self.pinchRecognizer.delegate = self;
    [self.view addGestureRecognizer:[self pinchRecognizer]];
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
    [self.pinchRecognizer removeTarget:self action:@selector(handleGesture:)];
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
}

- (void) defaultZoomCenterOn:(CLLocationCoordinate2D)coord animated:(BOOL)isAnimated
{
    // stop any ongoing tracking
    [self stopTrackingAnnotation];
    
    // center the map and browse area
    [self.view setCenterCoordinate:coord zoomLevel:kDefaultZoomLevel animated:isAnimated];
    [self.browseArea setCenterCoord:coord];
}

- (void) centerOnFlyer:(Flyer *)flyer animated:(BOOL)isAnimated
{
    if([flyer isEnroute])
    {
        // focus map on the route
        CLLocationCoordinate2D srcCoord = [flyer srcCoord];
        CLLocationCoordinate2D destCoord = [flyer destCoord];
        
        MKMapRect routeRect = [MKMapView boundingRectForCoordinateA:srcCoord coordinateB:destCoord];
        UIEdgeInsets padding = UIEdgeInsetsMake(20.0f, 5.0f, 20.0f, 5.0f);
        [self.view setVisibleMapRect:routeRect edgePadding:padding animated:YES];
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
            Flyer* flyer = (Flyer*)[cur annotation];
            [[cur superview] bringSubviewToFront:cur];
            [cur setTransform:[flyer transform]];
        }
        else if([cur isKindOfClass:[CalloutAnnotationView class]])
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
