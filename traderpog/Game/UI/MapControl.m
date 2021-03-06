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
#import "SoundManager.h"
#import "GameManager.h"
#import "GameViewController.h"
#import "ObjectivesMgr.h"
#include "MathUtils.h"

const NSUInteger kDefaultZoomLevel = 15;
const NSUInteger kNoCalloutZoomLevel = kDefaultZoomLevel - 2;
static NSString* const kKeyCoordinate = @"coordinate";
static const NSTimeInterval kAmbientWindFlighttimeThreshold = 30.0;

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
    BOOL _isViewingRoute;

    // angle in which post is shifted to resolve collision
    // this angle rotates by PI/4 each time it's used (with a slight random offset)
    float _shiftAngle;
}
@property (nonatomic,strong) BrowseArea* browseArea;
@property (nonatomic) BOOL regionSetFromCode;
@property (nonatomic,strong) UIPinchGestureRecognizer* pinchRecognizer;
@property (nonatomic,strong) BrowsePinch* pinchHandler;

- (void) internalInitWithMapView:(MKMapView*)mapView
                          center:(CLLocationCoordinate2D)initCoord
                       zoomLevel:(unsigned int)zoomLevel
                       isPreview:(BOOL)isPreview;
- (void) zoom:(NSUInteger) zoomLevel centerOn:(CLLocationCoordinate2D)coord
    modifyMap:(BOOL)modifyMap
     animated:(BOOL)isAnimated
   changeZoom:(BOOL)changeZoom;
- (CGPoint) getShiftDir;
@end

@implementation MapControl
@synthesize view;
@synthesize browseArea = _browseArea;
@synthesize regionSetFromCode = _regionSetFromCode;
@synthesize pinchRecognizer = _pinchRecognizer;
@synthesize pinchHandler = _pinchHandler;
@synthesize trackedAnnotation;
@synthesize isPreviewMap = _isPreviewMap;

- (NSUInteger) zoomLevel
{
    return [self.view zoomLevel];
}

- (BOOL) isZoomEnabled
{
    return [self.view isZoomEnabled];
}

static const float kShiftAngleOffsetRange = M_PI_4 * 0.2f;
- (CGPoint) getShiftDir
{
    CGPoint result = CGPointMake(1.0f, 0.0f);
    float randOffset = ((RandomFrac() - 0.5f) * kShiftAngleOffsetRange);
    CGAffineTransform t = CGAffineTransformMakeRotation(randOffset + _shiftAngle);
    result = CGPointApplyAffineTransform(result, t);
    _shiftAngle += (kShiftAngleOffsetRange + randOffset + ((1.0f + RandomFrac()) * M_PI_2 * 0.3f));
    if((2.0f * M_PI) <= _shiftAngle)
    {
        _shiftAngle -= (2.0f * M_PI);
    }
    return result;
}

const float kNewPostNearMeters = 150.0f;
const float kNewPostOffsetMeters = 100.0f;
- (CLLocation*) availableLocationNearCoord:(CLLocationCoordinate2D)targetCoord visibleOnly:(BOOL)visibleOnly
{
    CLLocation* result = nil;
    NSSet* visibleSet = [self postAnnotationsNearCoord:targetCoord radius:kNewPostNearMeters visibleOnly:visibleOnly];
    if([visibleSet count])
    {
        NSMutableSet* locationsSet = [NSMutableSet setWithCapacity:[visibleSet count]];
        for(NSObject<MKAnnotation>* cur in visibleSet)
        {
            CLLocation* loc = [[CLLocation alloc] initWithLatitude:cur.coordinate.latitude longitude:cur.coordinate.longitude];
            [locationsSet addObject:loc];
        }
        CLLocation* center = [[CLLocation alloc] initWithLatitude:targetCoord.latitude longitude:targetCoord.longitude];//[MKMapView centerOfLocationsInSet:locationsSet];
        CLLocation* farthest = [MKMapView farthestLocInSet:locationsSet fromCoord:center.coordinate];
        CLLocationDistance farDist = [center distanceFromLocation:farthest];
        
        // note: use new coordinate's latitude but original target coordinate's longitude
        // so, we shift the original post to the right
        CLLocationCoordinate2D srcCoord = CLLocationCoordinate2DMake(center.coordinate.latitude, center.coordinate.longitude);
        MKMapPoint centerPoint = MKMapPointForCoordinate(srcCoord);
        CLLocationDistance offsetDist = farDist + kNewPostOffsetMeters;
        double offsetMapPoints = offsetDist * MKMapPointsPerMeterAtLatitude(center.coordinate.latitude);
        CGPoint shiftDir = [self getShiftDir];
        CGPoint shiftVec = CGPointMake(shiftDir.x * offsetMapPoints, shiftDir.y * offsetMapPoints);
        MKMapPoint newPoint = MKMapPointMake(centerPoint.x + shiftVec.x, centerPoint.y + shiftVec.y);
        CLLocationCoordinate2D newCoord = MKCoordinateForMapPoint(newPoint);
        
        result = [[CLLocation alloc] initWithLatitude:newCoord.latitude longitude:newCoord.longitude];
    }
    
    return result;
}

- (NSSet*) visiblePostAnnotationsNearCoord:(CLLocationCoordinate2D)queryCoord radius:(float)radiusMeters
{
    return [self postAnnotationsNearCoord:queryCoord radius:radiusMeters visibleOnly:YES];
}

- (NSSet*) postAnnotationsNearCoord:(CLLocationCoordinate2D)queryCoord radius:(float)radiusMeters visibleOnly:(BOOL)visibleOnly
{
    NSMutableSet* result = [NSMutableArray arrayWithCapacity:10];
    CLLocation* queryLoc = [[CLLocation alloc] initWithLatitude:queryCoord.latitude longitude:queryCoord.longitude];
    NSSet* domainAnnotations = nil;
    domainAnnotations = [NSSet setWithArray:[self.view annotations]];
    for(NSObject<MKAnnotation>* cur in domainAnnotations)
    {
        if([cur isKindOfClass:[TradePost class]])
        {
            CLLocation* postLoc = [[CLLocation alloc] initWithLatitude:cur.coordinate.latitude longitude:cur.coordinate.longitude];
            CLLocationDistance dist = [postLoc distanceFromLocation:queryLoc];
            if(radiusMeters >= dist)
            {
                [result addObject:cur];
            }
        }
    }
    
    return result;
}

#pragma mark - public methods

- (void) internalInitWithMapView:(MKMapView *)mapView
                          center:(CLLocationCoordinate2D)initCoord
                       zoomLevel:(unsigned int)zoomLevel
                       isPreview:(BOOL)isPreview
{
    self.view = mapView;
    mapView.delegate = self;
    
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
    _isViewingRoute = NO;
    _isPreviewMap = isPreview;
    _shiftAngle = 0.0f;

    [mapView setCenterCoordinate:initCoord zoomLevel:zoomLevel animated:NO];
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
                            zoomLevel:zoomLevel isPreview:NO];
    }
    return self;
}

- (id) initWithPreviewMapView:(MKMapView*)mapView
             andCenter:(CLLocationCoordinate2D)initCoord
           atZoomLevel:(unsigned int)zoomLevel
{
    self = [super init];
    if(self)
    {
        [self internalInitWithMapView:mapView
                               center:initCoord
                            zoomLevel:zoomLevel isPreview:YES];
    }
    return self;
}


- (void) dealloc
{
    [self.view removeGestureRecognizer:[self pinchRecognizer]];
    [self.view removeGestureRecognizer:_panRecognizer];
}

- (void) addAnnotationForTradePost:(TradePost *)tradePost isScan:(BOOL)isScan
{
    NSArray* existingAnnotations = [self.view annotations];
    if(![existingAnnotations containsObject:tradePost])
    {
        BOOL visibleOnly = NO;
        if(isScan)
        {
            // if tradepost added from a scan, then need to check against visible posts only
            visibleOnly = YES;
        }
        CLLocation* newLoc = [self availableLocationNearCoord:tradePost.coordinate visibleOnly:visibleOnly];
        if(newLoc)
        {
            NSLog(@"Post %@ shifted from (%f, %f) to (%f, %f)", [tradePost postId],
              tradePost.coord.latitude, tradePost.coord.longitude,
              newLoc.coordinate.latitude, newLoc.coordinate.longitude);
            tradePost.coord = newLoc.coordinate;
        }
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
        FlyerAnnotationView* flyerAnnotView = (FlyerAnnotationView*)[self.view viewForAnnotation:flyer];
        if(flyerAnnotView)
        {
            [flyerAnnotView showCountdown:YES];
        }
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
    BOOL changeZoom = YES;
    if(kDefaultZoomLevel <= [self zoomLevel])
    {
        changeZoom = NO;
    }
    [self zoom:kDefaultZoomLevel centerOn:coord modifyMap:modifyMap animated:isAnimated changeZoom:changeZoom];
}

- (void) prescanZoomCenterOn:(CLLocationCoordinate2D)coord modifyMap:(BOOL)modifyMap animated:(BOOL)isAnimated
{
    [self zoom:kDefaultZoomLevel-2 centerOn:coord modifyMap:modifyMap animated:isAnimated changeZoom:YES];
}

- (void) zoom:(NSUInteger) zoomLevel centerOn:(CLLocationCoordinate2D)coord
    modifyMap:(BOOL)modifyMap
     animated:(BOOL)isAnimated
   changeZoom:(BOOL)changeZoom
{
    // center the map and browse area
    if(modifyMap)
    {
        if(changeZoom)
        {
            if(![self isZoomEnabled])
            {
                // map is not zoom-able only if we are in flight-path view; so, dismiss flight-paths
                // as we are getting out of it
                [[GameManager getInstance].gameViewController.mapControl dismissAllFlightPaths];
            }
            [self.view setCenterCoordinate:coord zoomLevel:zoomLevel animated:isAnimated];
        }
        else
        {
            [self.view setCenterCoordinate:coord animated:isAnimated];
        }
    }
    [self.browseArea setCenterCoord:coord];
    [self.browseArea setRadius:kBrowseAreaRadius];

    if(_isViewingRoute)
    {
        // if coming out of viewing route, change background music back to default
        _isViewingRoute = NO;
        [[SoundManager getInstance] playMusic:@"background_default" doLoop:YES];
    }

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

        if([self isPreviewMap])
        {
            // in previewMap, center on the flyer
            [self.view setCenterCoordinate:[flyer coordinate] animated:YES];
        }
        else
        {
            // start ambient wind when we're entering route view and there's more than 30 seconds of flighttime left
            if([flyer timeTillDest] > kAmbientWindFlighttimeThreshold)
            {
                [[SoundManager getInstance] playMusic:@"ambient_wind" doLoop:YES];
                _isViewingRoute = YES;
            }
            [self dismissAllFlightPaths];
            [self showFlightPathForFlyer:flyer];
        }
        
        // disable zoom for enroute Flyer
        self.view.zoomEnabled = NO;
        self.pinchRecognizer.enabled = NO;
    }
    else
    {
        if([self isPreviewMap])
        {
            [self defaultZoomCenterOn:[flyer coordinate] animated:isAnimated];
        }
        else
        {
            CLLocationCoordinate2D centerCoord = [flyer coordinate];
            if([flyer.path curPostId])
            {
                // if flyer is at a post, use the post's coord because it may have been
                // shifted by mapControl to resolve overlaps
                TradePost* post = [[TradePostMgr getInstance] getTradePostWithId:flyer.path.curPostId];
                if(post)
                {
                    centerCoord = [post coord];
                }
            }
            [self defaultZoomCenterOn:centerCoord animated:isAnimated];
        }
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
    if(![self isPreviewMap])
    {
        [[ObjectivesMgr getInstance] playerDidChangeMapCenterTo:self.view.centerCoordinate];
    }
}

- (void)mapView:(MKMapView*)mapView didSelectAnnotationView:(MKAnnotationView *)annotationView
{
    if([annotationView conformsToProtocol:@protocol(MapAnnotationViewProtocol)])
    {
        [[[GameManager getInstance] gameViewController] dismissInfo];
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
        else if(([[cur annotation] isMemberOfClass:[MyTradePost class]]))
        {
            [[cur superview] bringSubviewToFront:cur];            
        }
        else if(([[cur annotation] isKindOfClass:[TradePost class]]))
        {
            [[cur superview] sendSubviewToBack:cur];
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
