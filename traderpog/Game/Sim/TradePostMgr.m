//
//  TradePostMgr.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "GameManager.h"
#import "TradePostMgr.h"
#import "TradePost.h"
#import "TradeItem.h"
#import "TradeItemType.h"

@interface TradePostMgr ()
{
    NSMutableDictionary* _activePosts;
    NSMutableDictionary* _npcPosts;
    
    // for NPC posts generation
    unsigned int _npcPostIndex;
    
    // User trade post in the midst of being generated
    TradePost* _tempTradePost;
}
@property (nonatomic,strong) NSMutableDictionary* activePosts;
@property (nonatomic,strong) NSMutableDictionary* npcPosts;

- (BOOL) post:(TradePost*)post isWithinDistance:(float)distance fromCoord:(CLLocationCoordinate2D)coord;
- (void) loadTradePosts;
@end

@implementation TradePostMgr
@synthesize activePosts = _activePosts;
@synthesize npcPosts = _npcPosts;

- (id) init
{
    self = [super init];
    if(self)
    {
        _activePosts = [NSMutableDictionary dictionaryWithCapacity:10];
        _npcPosts = [NSMutableDictionary dictionaryWithCapacity:10];
        _npcPostIndex = 0;
        _tempTradePost = nil;
    }
    return self;
}

- (TradePost*) newNPCTradePostAtCoord:(CLLocationCoordinate2D)coord
                          sellingItem:(TradeItemType*)itemType
{
    NSString* postId = [NSString stringWithFormat:@"NPCPost%d", _npcPostIndex];
    ++_npcPostIndex;
    TradePost* newPost = [[TradePost alloc] initWithPostId:postId coordinate:coord itemType:itemType];
    [self.npcPosts setObject:newPost forKey:postId];
    return newPost;
}

- (BOOL) newTradePostAtCoord:(CLLocationCoordinate2D)coord 
                              sellingItem:(TradeItemType *)itemType
                              isHomebase:(BOOL)isHomebase
{
    if (_tempTradePost == nil)
    {
        TradePost* newPost = [[TradePost alloc] initWithCoordinates:coord itemType:itemType];
        [newPost setDelegate:[TradePostMgr getInstance]];
        newPost.isHomebase = isHomebase;
        _tempTradePost = newPost;
        [_tempTradePost createNewPostOnServer];
        return TRUE;
    }
    
    return FALSE;
}

- (void) setTempPostToActive
{
    if (_tempTradePost)
    {
        [self.activePosts setObject:_tempTradePost forKey:_tempTradePost.postId];
        _tempTradePost = nil;
    }
}

- (TradePost*) getTradePostWithId:(NSString *)postId
{
    TradePost* result = [self.activePosts objectForKey:postId];
    if(!result)
    {
        result = [self.npcPosts objectForKey:postId];
    }
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

- (NSMutableArray*) getTradePostsAtCoord:(CLLocationCoordinate2D)coord 
                           radius:(float)radius 
                           maxNum:(unsigned int)maxNum
{
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:5];
    
    // HACK
    // TODO: implement query from server
    // HACK
    
    // query active posts
    unsigned int num = 0;
    for(TradePost* cur in self.activePosts.allValues)
    {
        if([self post:cur isWithinDistance:radius fromCoord:coord])
        {
            [result addObject:cur];
            ++num;
            if(num >= maxNum)
            {
                break;
            }
        }
    }
    
    // query npc posts
    for(TradePost* cur in self.npcPosts.allValues)
    {
        if([self post:cur isWithinDistance:radius fromCoord:coord])
        {
            [result addObject:cur];
            ++num;
            if(num >= maxNum)
            {
                break;
            }
        }        
    }
    
    return result;
}

#pragma mark - internal methods
- (BOOL) post:(TradePost*)post isWithinDistance:(float)distance fromCoord:(CLLocationCoordinate2D)coord
{
    BOOL result = NO;
    
    CLLocation* center = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
    CLLocation* postLoc = [[CLLocation alloc] initWithLatitude:post.coord.latitude longitude:post.coord.longitude];
    CLLocationDistance dist = [postLoc distanceFromLocation:center];
    if(dist <= distance)
    {
        result = YES;
    }
    
    return result;
}

- (void) loadTradePosts
{
    // HACK
    // TODO: implement load from server 
    // HACK
}

#pragma mark - HttpCallbackDelegate
- (void) didCompleteHttpCallback:(NSString*)callName, BOOL success
{
    if (success)
    {
        [self setTempPostToActive];
    }
    [[GameManager getInstance] selectNextGameUI];
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
