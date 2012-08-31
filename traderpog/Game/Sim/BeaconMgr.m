//
//  BeaconMgr.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AFClientManager.h"
#import "BeaconMgr.h"
#import "Beacon.h"
#import "WheelControl.h"
#import "WheelBubble.h"
#import "PogUIUtility.h"
#import "Player.h"
#import "TradePost.h"
#import "FlyerMgr.h"
#import "Flyer.h"
#import "NSArray+Pog.h"

static NSUInteger kBeaconPreviewZoomLevel = 8;
static double const refreshTime = -(60 * 15);

@interface BeaconMgr ()
{
    // for wheel
    MapControl* _previewMap;
}
@property (nonatomic,strong) MapControl* previewMap;
@end

@implementation BeaconMgr
@synthesize activeBeacons = _activeBeacons;
@synthesize previewMap = _previewMap;
@synthesize delegate = _delegate;

- (id) init
{
    self = [super init];
    if(self)
    {
        _activeBeacons = [NSMutableDictionary dictionaryWithCapacity:10];
        _lastUpdate = nil;
    }
    return self;
}

- (BOOL) needsRefresh
{
    BOOL test = ([[Player getInstance] isFacebookConnected]);
    return test &&
            ((!_lastUpdate) ||
            ([_lastUpdate timeIntervalSinceNow] < refreshTime));
}

- (void) createPostsArray:(id)responseObject
{
    for (NSDictionary* post in responseObject)
    {
        TradePost* current = [[TradePost alloc] initWithDictionary:post isForeign:TRUE];
        [self.activeBeacons setObject:current forKey:current.postId];
    }
}

- (void) retrieveBeaconsFromServer
{
    // make a get request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    NSString *userId = [NSString stringWithFormat:@"%d", [[Player getInstance] playerId]];
    [httpClient setDefaultHeader:@"user-id" value:userId];
    [httpClient getPath:@"posts/beacons"
             parameters:nil
                success:^(AFHTTPRequestOperation *operation, id responseObject){
                    NSLog(@"Retrieved: %@", responseObject);
                    [self createPostsArray:responseObject];
                    _lastUpdate = [NSDate date];
                    [self.delegate didCompleteHttpCallback:kBeaconMgr_ReceiveBeacons, TRUE];
                }
                failure:^(AFHTTPRequestOperation* operation, NSError* error){
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                      message:@"Unable to create retrieve beacons. Please try again later."
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    
                    [message show];
                    [self.delegate didCompleteHttpCallback:kBeaconMgr_ReceiveBeacons, FALSE];
                }
     ];
    [httpClient setDefaultHeader:@"user_id" value:nil];
}

// this method performs linkage on variables that need to be resolved when
// all data in all managers (FlyerMgr, TradePostMgr, etc.) has been loaded
// specifically, it adds all the beacon posts as annotations in the game map, and it
// initializes the hasFlyer variable in each post;
- (void) addBeaconAnnotationsToMap:(MapControl*)map
{
    NSArray* postIdsWithFlyers = [[FlyerMgr getInstance] tradePostIdsWithFlyers];
    for(TradePost* cur in [_activeBeacons allValues])
    {
        [map addAnnotation:cur];
        if([postIdsWithFlyers stringArrayContainsString:[cur postId]])
        {
            cur.hasFlyer = YES;
        }
    }
}

#pragma mark - WheelDataSource
- (unsigned int) numItemsInWheel:(WheelControl *)wheel
{
    unsigned int num = [_activeBeacons count];
    return num;
}


- (WheelBubble*) wheel:(WheelControl *)wheel bubbleAtIndex:(unsigned int)index
{
    WheelBubble* contentView = [wheel dequeueResuableBubble];
    UILabel* labelView = nil;
    if(nil == contentView)
    {
        CGRect contentRect = CGRectMake(5.0f, 5.0f, 30.0f, 30.0f);
        contentView = [[WheelBubble alloc] initWithFrame:contentRect];
    }
    labelView = [contentView labelView];
    labelView.backgroundColor = [UIColor clearColor];
    [labelView setText:[NSString stringWithFormat:@"%d", index]];
    contentView.backgroundColor = [UIColor redColor];
    
    [PogUIUtility setCircleForView:contentView];
    return contentView;
}

- (UIView*) wheel:(WheelControl*)wheel previewContentInitAtIndex:(unsigned int)index;
{
    MKMapView* result = nil;
    if([_activeBeacons count])
    {
        if(_previewMap)
        {
            result = [_previewMap view];
        }
        else
        {
            CGRect superFrame = wheel.previewView.bounds;
            result = [[MKMapView alloc] initWithFrame:superFrame];
            index = MIN(index, [_activeBeacons count]-1);
            TradePost* initBeacon = [_activeBeacons.allValues objectAtIndex:index];
            _previewMap = [[MapControl alloc] initWithMapView:result
                                                    andCenter:[initBeacon coord]
                                                  atZoomLevel:kBeaconPreviewZoomLevel];
            
            // add all pre-existing beacons
            [self addBeaconAnnotationsToMap:_previewMap];
        }
    }
    return result;
}

#pragma mark - WheelProtocol
- (void) wheelDidMoveTo:(unsigned int)index
{
    NSLog(@"wheel moved to %d",index);
}

- (void) wheelDidSettleAt:(unsigned int)index
{
    if([_activeBeacons count])
    {
        index = MIN(index, [_activeBeacons count]-1);
        TradePost* cur = [_activeBeacons.allValues objectAtIndex:index];
        [_previewMap centerOn:[cur coord] animated:YES];
    }
}

- (void) wheel:(WheelControl*)wheel didPressOkOnIndex:(unsigned int)index
{
    if([_activeBeacons count])
    {
        index = MIN(index, [_activeBeacons count]-1);
        TradePost* cur = [_activeBeacons.allValues objectAtIndex:index];
        [wheel.superMap defaultZoomCenterOn:[cur coord] animated:YES];
    }
}

- (void) wheel:(WheelControl *)wheel didPressCloseOnIndex:(unsigned int)index
{
    // do nothing
}

- (void) wheel:(WheelControl*)wheel willShowAtIndex:(unsigned int)index
{
    // do nothing
}

- (void) wheel:(WheelControl*)wheel willHideAtIndex:(unsigned int)index
{
    // do nothing
}

#pragma mark - Singleton
static BeaconMgr* singleton = nil;
+ (BeaconMgr*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
            if (!singleton)
            {
                singleton = [[BeaconMgr alloc] init];
            }
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
