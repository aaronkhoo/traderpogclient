//
//  TradePostMgr.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "TradePostMgr.h"
#import "TradePost.h"
#import "TradeItem.h"
#import "TradeItemType.h"

@interface TradePostMgr ()
{
    NSMutableDictionary* _activePosts;
    
    // for NPC posts generation
    unsigned int _npcPostIndex;
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
        _activePosts = [NSMutableDictionary dictionaryWithCapacity:10];
        _npcPostIndex = 0;
    }
    return self;
}

- (TradePost*) newNPCTradePostAtCoord:(CLLocationCoordinate2D)coord
                          sellingItem:(TradeItemType*)itemType
{
    NSString* postId = [NSString stringWithFormat:@"NPCPost%d", _npcPostIndex];
    ++_npcPostIndex;
    TradePost* newPost = [[TradePost alloc] initWithPostId:postId coordinate:coord itemType:itemType];
    [self.activePosts setObject:newPost forKey:postId];
    return newPost;
}

- (TradePost*) newTradePostAtCoord:(CLLocationCoordinate2D)coord 
                       sellingItem:(TradeItemType *)itemType
                        isHomebase:(BOOL)isHomebase
{
    // HACK
    // need to ask server for post id
    NSString* postId = @"post1";
    // HACK
    TradePost* newPost = [[TradePost alloc] initWithPostId:postId coordinate:coord itemType:itemType];
    newPost.isHomebase = isHomebase;
    [self.activePosts setObject:newPost forKey:postId];
    return newPost;
}

- (TradePost*) getTradePostWithId:(NSString *)postId
{
    TradePost* result = [self.activePosts objectForKey:postId];
    return result;
}

- (TradePost*) getHomebase
{
    TradePost* result = nil;
    for(TradePost* cur in self.activePosts.allValues)
    {
        if([cur isHomebase])
        {
            result = cur;
            break;
        }
    }
    return result;
}

- (NSArray*) getTradePostsAtCoord:(CLLocationCoordinate2D)coord radius:(float)radius
{
    NSArray* result = nil;
    
    // HACK
    // TODO: implement query from server
    // HACK
    
    return result;
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
