//
//  FlyerMgr.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/22/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerMgr.h"
#import "Flyer.h"
#import "GameManager.h"
#import "TradePost.h"

@interface FlyerMgr ()
{    
    // User flyer in the midst of being generated
    Flyer* _tempFlyer;
}
@end

@implementation FlyerMgr
@synthesize playerFlyers = _playerFlyers;

- (id) init
{
    self = [super init];
    if(self)
    {
        _playerFlyers = [NSMutableArray arrayWithCapacity:10];
    }
    return self;
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

- (void) loadFlyersFromServer
{
    // HACK
    
    // TODO: load from server
    
    // HACK
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
