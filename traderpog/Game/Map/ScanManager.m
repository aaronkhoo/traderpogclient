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
static const unsigned int kScanNumPosts = 3;

@interface ScanManager ()
{
    ScanCompletionBlock _completion;
    __weak MKMapView* _mapView;
}
@property (nonatomic,weak) MKMapView* mapView;
- (void) startLocate;
- (void) startScanAtCoord:(CLLocationCoordinate2D)scanCoord;
- (void) abortLocateScan;
- (MKMapPoint) createPointFromCenter:(CLLocationCoordinate2D)center atDistance:(double)meters angle:(float)radians;
@end

@implementation ScanManager
@synthesize state = _state;
@synthesize locator = _locator;
@synthesize mapView = _mapView;

- (id) init
{
    self = [super init];
    if(self)
    {
        _state = kScanStateIdle;
        _locator = [[HiAccuracyLocator alloc] init];
        _locator.delegate = self;
        _completion = nil;
        self.mapView = nil;
    }
    return self;
}

- (BOOL) locateAndScanInMap:(MKMapView*)mapView completion:(ScanCompletionBlock)completion
{
    BOOL success = NO;
    
    if(kScanStateIdle == [self state])
    {
        _completion = completion;
        self.mapView = mapView;
        [self startLocate];
    }
    
    return success;
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
    _state = kScanStateLocating;
}

- (void) startScanAtCoord:(CLLocationCoordinate2D)scanCoord
{
    // TODO: ask TradePostMgr to scan
    NSLog(@"scanning...");
    _state = kScanStateScanning;
    
    // retrieve existing posts
    NSMutableArray* posts = [[TradePostMgr getInstance] getTradePostsAtCoord:scanCoord radius:kScanRadius maxNum:kScanNumPosts];
    
    // generate new locations we there isn't enough existing posts
    if([posts count] < kScanNumPosts)
    {
        NSArray* itemTypes = [[TradeItemTypes getInstance] getItemTypesForTier:0];
        unsigned int numPosts = kScanNumPosts - [posts count];
        float curAngle = RandomFrac() * 2.0 * M_PI;
        float angleIncr = 2.0 * M_PI / ((float) numPosts);
        for(unsigned int i = 0; i < numPosts; ++i)
        {
            float randFrac = RandomFrac();
            double minDistance = kScanRadius * 0.35;
            double newDistance = minDistance + (randFrac * (kScanRadius - minDistance));
            
            MKMapPoint newPoint = [self createPointFromCenter:scanCoord atDistance:newDistance angle:curAngle];
            CLLocationCoordinate2D newCoord = MKCoordinateForMapPoint(newPoint);
            
            TradePost* newPost = [[TradePostMgr getInstance] newNPCTradePostAtCoord:newCoord
                                                                        sellingItem:[itemTypes objectAtIndex:0]];
            [posts addObject:newPost];
            
            curAngle = curAngle + angleIncr;
            if(curAngle >= (2.0 * M_PI))
            {
                curAngle = curAngle - (2.0 * M_PI);
            }
        }
    }
    
    // complete scan
    if(_completion)
    {
        NSLog(@"done");
        self.mapView = nil;
        _completion(YES, posts);
    }
    _state = kScanStateIdle;
}

- (void) abortLocateScan
{
    _state = kScanStateIdle;
    if(_completion)
    {
        self.mapView = nil;
        _completion(NO, nil);
    }    
}

#pragma mark - HiAccuracyLocatorDelegate
- (void) locator:(HiAccuracyLocator *)locator didLocateUser:(BOOL)didLocateUser
{
    if(didLocateUser)
    {
        // center map on my location
        if([self mapView])
        {
            [self.mapView setCenterCoordinate:locator.bestLocation.coordinate zoomLevel:kScanLocateZoomLevel animated:NO];
        }
        
        // start the scan
        [self startScanAtCoord:locator.bestLocation.coordinate];
    }
    else 
    {
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
