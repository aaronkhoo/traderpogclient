//
//  FlyerMgr.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/22/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerMgr.h"
#import "Flyer.h"
#import "TradePost.h"

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

- (Flyer*) newPlayerFlyerAtTradePost:(TradePost*)tradePost
{
    Flyer* newFlyer = [[Flyer alloc] initAtPost:tradePost];
    [_playerFlyers addObject:newFlyer];
    return newFlyer;
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
