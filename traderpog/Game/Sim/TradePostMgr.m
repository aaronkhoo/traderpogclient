//
//  TradePostMgr.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "TradePostMgr.h"
#import "TradePost.h"

@interface TradePostMgr ()
{
    TradePost* _homebase;
}
- (void) loadTradePosts;
@end

@implementation TradePostMgr

- (id) init
{
    self = [super init];
    if(self)
    {
        _homebase = nil;
    }
    return self;
}

- (void) setHomebase:(TradePost *)newPost
{
    _homebase = newPost;
}

- (TradePost*) getHomebase
{
    return _homebase;
}


#pragma mark - internal methods
- (void) loadTradePosts
{
    // HACK
    // TODO: implement load from server 
    // HACK
}


#pragma mark - Singleton
static TradePostMgr* singleton = nil;
+ (TradePostMgr*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
            if (!singleton)
            {
                singleton = [[TradePostMgr alloc] init];
                [singleton loadTradePosts];
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
