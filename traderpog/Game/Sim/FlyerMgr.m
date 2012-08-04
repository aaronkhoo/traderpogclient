//
//  FlyerMgr.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/22/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AFClientManager.h"
#import "FlyerMgr.h"
#import "Flyer.h"
#import "GameManager.h"
#import "Player.h"
#import "TradePost.h"
#import "WheelControl.h"
#import "WheelBubble.h"
#import "PogUIUtility.h"
#import "MapControl.h"


@interface FlyerMgr ()
{    
    // User flyer in the midst of being generated
    Flyer* _tempFlyer;
    
    // Flyer Wheel datasource
    MapControl* _previewMap;
}
@end

static double const refreshTime = -(60 * 15);

@implementation FlyerMgr
@synthesize playerFlyers = _playerFlyers;
@synthesize delegate = _delegate;

- (id) init
{
    self = [super init];
    if(self)
    {
        _playerFlyers = [NSMutableArray arrayWithCapacity:10];
        _lastUpdate = nil;
        _previewMap = nil;
    }
    return self;
}

- (BOOL) needsRefresh
{
    return (!_lastUpdate) || ([_lastUpdate timeIntervalSinceNow] < refreshTime);
}

- (BOOL) newPlayerFlyerAtTradePost:(TradePost*)tradePost firstFlyer:(FlyerType*)flyerType
{
    if (_tempFlyer == nil)
    {
        Flyer* newFlyer = [[Flyer alloc] initWithPostAndFlyerId:tradePost, [flyerType flyerId]];
        [newFlyer setDelegate:[FlyerMgr getInstance]];
        _tempFlyer = newFlyer;
        [_tempFlyer createNewUserFlyerOnServer];
        return TRUE;
    }    
    return FALSE;
}

- (void) setTempFlyerToActive
{
    if (_tempFlyer)
    {
        // The temp TradePost has been successfully uploaded to the server, so move it
        // to the active list.
        [_playerFlyers addObject:_tempFlyer];
        
        // Add this tradepost as an annotation to the mapcontrol instance if the map control has already
        // been created. If it hasn't, then log and skip this step. It's possible that the mapcontrol
        // doesn't exist yet during the startup flow. This will be taken care of properly, see GameManager
        // for more details.
        if ([[GameManager getInstance] gameViewController].mapControl)
        {
            //[[[GameManager getInstance] gameViewController].mapControl addAnnotation  ];
        }
        else
        {
            NSLog(@"Map control has not been initialized!");
        }
        _tempFlyer = nil;
    }
}

- (void) createFlyerssArray:(id)responseObject
{
    for (NSDictionary* flyer in responseObject)
    {
        Flyer* current = [[Flyer alloc] initWithDictionary:flyer];
        [self.playerFlyers addObject:current];
    }
}

- (void) retrieveUserFlyersFromServer
{
    // make a get request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    NSString *userFlyerPath = [NSString stringWithFormat:@"users/%d/user_flyers", [[Player getInstance] id]];
    [httpClient getPath:userFlyerPath
             parameters:nil
                success:^(AFHTTPRequestOperation *operation, id responseObject){
                    NSLog(@"Retrieved: %@", responseObject);
                    [self createFlyerssArray:responseObject];
                    _lastUpdate = [NSDate date];
                    [self.delegate didCompleteHttpCallback:kFlyerMgr_ReceiveFlyers, TRUE];
                }
                failure:^(AFHTTPRequestOperation* operation, NSError* error){
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                      message:@"Unable to create retrieve flyers. Please try again later."
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    
                    [message show];
                    [self.delegate didCompleteHttpCallback:kFlyerMgr_ReceiveFlyers, FALSE];
                }
     ];
}

- (void) updateFlyersAtDate:(NSDate *)currentTime
{
    for(Flyer* cur in _playerFlyers)
    {
        [cur updateAtDate:currentTime];
    }
}

#pragma mark - HttpCallbackDelegate
- (void) didCompleteHttpCallback:(NSString*)callName, BOOL success
{
    if (success)
    {
        [self setTempFlyerToActive];
    }
    [[GameManager getInstance] selectNextGameUI];
}

#pragma mark - WheelDataSource
- (unsigned int) numItemsInWheel:(WheelControl *)wheel
{
    unsigned int num = [_playerFlyers count];
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
    if([_playerFlyers count])
    {
        if(_previewMap)
        {
            result = [_previewMap view];
        }
        else
        {
            CGRect superFrame = wheel.previewView.bounds;
            result = [[MKMapView alloc] initWithFrame:superFrame];
            index = MIN(index, [_playerFlyers count]-1);
            Flyer* initFlyer = [_playerFlyers objectAtIndex:index];
            _previewMap = [[MapControl alloc] initWithMapView:result
                                                    andCenter:[initFlyer coord]];
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
    if([_playerFlyers count])
    {
        index = MIN(index, [_playerFlyers count]-1);
        Flyer* curFlyer = [_playerFlyers objectAtIndex:index];
        [_previewMap centerOn:[curFlyer coord] animated:YES];
    }
}

- (void) wheel:(WheelControl*)wheel didPressOkOnIndex:(unsigned int)index
{
    if([_playerFlyers count])
    {
        index = MIN(index, [_playerFlyers count]-1);
        Flyer* curFlyer = [_playerFlyers objectAtIndex:index];
        [wheel.superMap centerOn:[curFlyer coord] animated:YES];
    }    
}


#pragma mark - Singleton
static FlyerMgr* singleton = nil;
+ (FlyerMgr*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
            if (!singleton)
            {
                singleton = [[FlyerMgr alloc] init];
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
