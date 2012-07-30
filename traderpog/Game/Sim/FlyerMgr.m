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

@interface FlyerMgr ()
{    
    // User flyer in the midst of being generated
    Flyer* _tempFlyer;
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
    }
    
    BOOL result = NO;
    if(_tempFlyer)
    {
        result = YES;
    }
    
    return result;
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
    // HACK
    // TODO: re-enable this if(success) check when integration with server is done
    //if (success)
    // HACK
    {
        [self setTempFlyerToActive];
    }
    [[GameManager getInstance] selectNextGameUI];
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
