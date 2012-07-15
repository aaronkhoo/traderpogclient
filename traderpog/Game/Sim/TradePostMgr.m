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
    NSMutableDictionary* _activePosts;
}
@property (nonatomic) NSMutableDictionary* activePosts;
- (void) loadTradePosts;
@end

@implementation TradePostMgr
@synthesize activePosts = _activePosts;

- (id) init
{
    self = [super init];
    if(self)
    {
        _homebase = nil;
        _activePosts = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    return self;
}

- (TradePost*) newTradePostAtCoord:(CLLocationCoordinate2D)coord 
                       sellingItem:(NSString *)itemId
                        isHomebase:(BOOL)isHomebase
{
    // HACK
    // need to ask server for post id
    NSString* postId = @"post1";
    // HACK
    TradePost* newPost = [[TradePost alloc] initWithPostId:postId coordinate:coord item:itemId];
    newPost.isHomebase = isHomebase;
    [self.activePosts setObject:newPost forKey:postId];
    return newPost;
}

- (TradePost*) getTradePostWithId:(NSString *)postId
{
    TradePost* result = [self.activePosts objectForKey:postId];
    return result;
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
