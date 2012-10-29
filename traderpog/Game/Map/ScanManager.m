//
//  ScanManager.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/19/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "ScanManager.h"
#import "HiAccuracyLocator.h"
#import "MKMapView+ZoomLevel.h"
#import "TradePostMgr.h"
#import "TradeItemTypes.h"
#import "TradeItemType.h"
#import "MapControl.h"
#import "Player.h"
#import <MapKit/MapKit.h>
#include "MathUtils.h"

enum kScanStates
{
    kScanStateIdle = 0,
    kScanStateLocating,
    kScanStateScanning,
    
    kScanStateNum
};

static const NSUInteger kScanLocateZoomLevel = 15;
static const float kScanRadius = 300.0f;    // meters
static const float kScanRadiusMinFactor = 0.25f;
static const unsigned int kScanNumPosts = 2;
static const unsigned int kMaxNumPosts = 7;
static const NSTimeInterval kScanDurationMin = 2.0f;    // minimum amount of time for Scan
                                                        // so that the player has a chance to observe
                                                        // their own location
static const unsigned int kNumOverlapTrials = 3;
static const float kRetryAngleIncr = M_PI_2 * 0.5f;

@interface ScanManager ()
{
    ScanCompletionBlock _completion;
    __weak MapControl* _map;
    
    NSDate* _scanBegin;
    CLLocation* _scanLoc;
}
@property (nonatomic,weak) MapControl* map;
- (void) startLocate;
- (void) startScanAtCoord:(CLLocationCoordinate2D)scanCoord;
- (void) abortLocateScan;
- (MKMapPoint) createPointFromCenter:(CLLocationCoordinate2D)center atDistance:(double)meters angle:(float)radians;
- (void) completeScanWithPosts:(NSMutableArray*)posts;
@end

@implementation ScanManager
@synthesize state = _state;
@synthesize locator = _locator;
@synthesize map = _map;

- (id) init
{
    self = [super init];
    if(self)
    {
        _state = kScanStateIdle;
        _locator = [[HiAccuracyLocator alloc] initWithAccuracy:kCLLocationAccuracyHundredMeters];
        _locator.delegate = self;
        _completion = nil;
        self.map = nil;
        _scanBegin = nil;
        _scanLoc = nil;
    }
    return self;
}

- (BOOL) locateAndScanInMap:(MapControl*)map completion:(ScanCompletionBlock)completion
{
    BOOL success = NO;
    
    if(kScanStateIdle == [self state])
    {
        _completion = completion;
        self.map = map;
        [self startLocate];
    }
    
    return success;
}

// called prior to quit-game to remove any retention on game objects
- (void) clearForQuitGame
{
    _completion = nil;
    self.map = nil;
}

- (MKMapPoint) createPointFromCenter:(CLLocationCoordinate2D)center atDistance:(double)meters angle:(float)radians
{
    CGMutablePathRef path = CGPathCreateMutable();
    MKMapPoint mapPoint = MKMapPointForCoordinate(center);
    CGPoint centerPoint = CGPointMake(mapPoint.x, mapPoint.y);
    CGFloat radius = MKMapPointsPerMeterAtLatitude(center.latitude) * meters;
    CGPathAddArc(path, NULL, centerPoint.x, centerPoint.y, radius, 0, radians, false);
    CGPoint pathPoint = CGPathGetCurrentPoint(path);
    MKMapPoint result = MKMapPointMake(pathPoint.x, pathPoint.y);
    
    CGPathRelease(path);
    
    return result;
}


#pragma mark - scan state processing
- (void) startLocate
{
    [self.locator startUpdatingLocation];
    self.map.view.showsUserLocation = YES;
    //self.map.view.userTrackingMode = MKUserTrackingModeFollow;
    _state = kScanStateLocating;
}

- (NPCTradePost*) generateSinglePostAtCoordAndAngle:(CLLocationCoordinate2D)scanCoord curAngle:(float)curAngle randFrac:(float)randFrac
{
    double minDistance = kScanRadius * kScanRadiusMinFactor;
    double newDistance = minDistance + (randFrac * (kScanRadius - minDistance));
    
    MKMapPoint newPoint = [self createPointFromCenter:scanCoord atDistance:newDistance angle:curAngle];
    CLLocationCoordinate2D newCoord = MKCoordinateForMapPoint(newPoint);
    
    unsigned int numTrials = kNumOverlapTrials;
    NSSet* overlaps = [self.map visiblePostAnnotationsNearCoord:newCoord radius:kNewPostNearMeters];
    while(([overlaps count]) && numTrials)
    {
        curAngle = curAngle + (kRetryAngleIncr * (1.0f - (0.5f * RandomFrac())));
        double tryDist = minDistance + (RandomFrac() * (kScanRadius - minDistance));
        newPoint = [self createPointFromCenter:scanCoord atDistance:tryDist angle:curAngle];
        newCoord = MKCoordinateForMapPoint(newPoint);
        NSLog(@"retry %d: tryDist %f curAngle %f; newCoord (%f, %f)", numTrials, tryDist, curAngle, newCoord.latitude, newCoord.longitude);
        overlaps = [self.map visiblePostAnnotationsNearCoord:newCoord radius:kNewPostNearMeters];
        --numTrials;
    }
    
    unsigned int playerBucks = [[Player getInstance] bucks];
    NPCTradePost* newPost = [[TradePostMgr getInstance] newNPCTradePostAtCoord:newCoord
                                                                         bucks:playerBucks];
    return newPost;
}

- (void) startScanAtCoord:(CLLocationCoordinate2D)scanCoord
{
    NSLog(@"scanning...");
    _state = kScanStateScanning;
    _scanBegin = [NSDate date];
    
    // retire posts excluding the visible ones
    NSSet* visible = [self.map.view annotationsInMapRect:[self.map.view visibleMapRect]];
    NSMutableSet* excludeSet = [NSMutableSet setWithCapacity:[visible count]];
    for(NSObject<MKAnnotation>* cur in visible)
    {
        if([cur isKindOfClass:[TradePost class]])
        {
            [excludeSet addObject:cur];
        }
    }
    NSArray* retiredPosts = [[TradePostMgr getInstance] retireTradePostsWithExcludeSet:excludeSet];
    for(TradePost* cur in retiredPosts)
    {
        [self.map.view removeAnnotation:cur];
    }
    
    // retrieve existing posts
    NSMutableArray* posts = [[TradePostMgr getInstance] getTradePostsAtCoord:scanCoord radius:kScanRadius maxNum:kMaxNumPosts];
    
    // generate new locations if there isn't enough existing posts
    // first put one at scanCoord if there isn't a post there
    unsigned int scanNumPosts = kScanNumPosts;
    if([posts count] < kMaxNumPosts)
    {
        NSSet* scanLocPosts = [self.map visiblePostAnnotationsNearCoord:scanCoord radius:kNewPostNearMeters];
        if(![scanLocPosts count])
        {
            unsigned int playerBucks = [[Player getInstance] bucks];
            NPCTradePost* newPost = [[TradePostMgr getInstance] newNPCTradePostAtCoord:scanCoord
                                                                                 bucks:playerBucks];
            [posts addObject:newPost];
            --scanNumPosts;
        }
    }
    
    // then fill in the rest around it
    if([posts count] < kMaxNumPosts)
    {
        float angleIncr = 1.5 * M_PI / ((float) scanNumPosts);
        float startAngle = RandomFrac() * 2.0f * M_PI;
        NSLog(@"startAngle %f", startAngle);
        unsigned int numPosts = MIN(scanNumPosts, (kMaxNumPosts - [posts count]));
        float curAngle = startAngle;
        float randFrac = RandomFrac();
        for(unsigned int i = 0; i < numPosts; ++i)
        {
            NPCTradePost* newPost = [self generateSinglePostAtCoordAndAngle:scanCoord curAngle:curAngle randFrac:randFrac];
            [posts addObject:newPost];
            
            curAngle = curAngle + (angleIncr * (1.0f - (0.5f * RandomFrac())));
            if(curAngle >= (2.0 * M_PI))
            {
                curAngle = curAngle - (2.0 * M_PI);
            }
        }
    }
    
    // complete scan
    NSLog(@"scan ready to return");
    NSTimeInterval elapsed = kScanDurationMin;
    if(_scanBegin)
    {
        elapsed = -[_scanBegin timeIntervalSinceNow];
    }
    if(elapsed < kScanDurationMin)
    {
        // if not enough time has elapsed, explicitly introduce a delay for user
        // so that they get to observe their location a little bit before the posts pop up
        NSTimeInterval delay = kScanDurationMin - elapsed;
        NSLog(@"delay is %f", delay);
        dispatch_time_t completionDelay = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
        dispatch_after(completionDelay, dispatch_get_main_queue(), ^(void){
            [self completeScanWithPosts:posts];
        });
    }
    else
    {
        [self completeScanWithPosts:posts];
    }
}

- (void) abortLocateScan
{
    _state = kScanStateIdle;
    _scanLoc = nil;
    if(_completion)
    {
        self.map = nil;
        _completion(NO, nil, nil);
    }
}

- (void) completeScanWithPosts:(NSMutableArray *)posts
{
    NSLog(@"complete scan");
    self.map.view.showsUserLocation = NO;
    self.map.view.userTrackingMode = MKUserTrackingModeNone;
    self.map = nil;
    _scanBegin = nil;
    if(_completion)
    {
        _completion(YES, posts, _scanLoc);
    }
    _state = kScanStateIdle;
    _scanLoc = nil;
}

#pragma mark - HttpCallbackDelegate
- (void) didCompleteHttpCallback:(NSString*)callName, BOOL success
{
    if (success)
    {
        NSLog(@"Scanning for tradeposts from the server succeeded");
    }
    else
    {
        NSLog(@"Scanning for tradeposts from the server FAILED");
    }
    
    // either way, return the tradeposts for the current location that we have
//    [self startScanAtCoord:[[Player getInstance] lastKnownLocation]];
    [self startScanAtCoord:_scanLoc.coordinate];
}

#pragma mark - HiAccuracyLocatorDelegate
- (void) locator:(HiAccuracyLocator *)locator didLocateUser:(BOOL)didLocateUser
{
    if(didLocateUser)
    {
        // center map on my location;
        // this is the first of two centers; it zooms out a little bit and then
        // after the scan completes, the second center zooms back in to defaultZoomLevel
        // this is necessary to force the mapView to refresh; otherwise, between the
        // retirement-removeAnnotations and scan-addAnnotations, the annotationViews could disappear and not
        // get redrawn until the user does a zoom/pinch
        if([self map])
        {
            [self.map prescanZoomCenterOn:locator.bestLocation.coordinate modifyMap:YES animated:YES];
        }
        // Store up the last known player location
        _scanLoc = locator.bestLocation;
        [Player getInstance].lastKnownLocation = locator.bestLocation.coordinate;
        [Player getInstance].lastKnownLocationValid = TRUE;
        NSLog(@"Located myself (%f, %f)", locator.bestLocation.coordinate.latitude, locator.bestLocation.coordinate.longitude);
        
        // Now that we know where the player's location is, request any posts in the vicinity
        [[TradePostMgr getInstance] scanForTradePosts:locator.bestLocation.coordinate];
    }
    else 
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot determine current location"
                                                        message:@"TraderPog requires location services to discover trade posts. Please try again later"
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        [alert show];
        
        // location failed
        [self abortLocateScan];
    }
}

#pragma mark - Singleton
static ScanManager* singleton = nil;
+ (ScanManager*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
			singleton = [[ScanManager alloc] init];
		}
	}
	return singleton;
}

+ (void) destroyInstance
{
	@synchronized(self)
	{
		singleton = nil;
	}
}


@end
