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
}
@property (nonatomic) NSMutableDictionary* activePosts;
// HACK
@property (nonatomic,strong) NSArray* tier0ItemTypes;
// HACK
- (void) loadTradePosts;
@end

@implementation TradePostMgr
@synthesize activePosts = _activePosts;
@synthesize tier0ItemTypes;

- (id) init
{
    self = [super init];
    if(self)
    {
        _activePosts = [NSMutableDictionary dictionaryWithCapacity:10];

        // HACK
        self.tier0ItemTypes = [NSArray arrayWithObjects:
                               [TradeItemType itemWithId:@"1" name:@"Rice" desc:@"Great with Kung Pao dishes"],
                               [TradeItemType itemWithId:@"2" name:@"Eggs" desc:@"Omelette essential"],
                               [TradeItemType itemWithId:@"3" name:@"Grain" desc:@"Great with PBJ"], nil];
        // HACK
    }
    return self;
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

- (NSArray*) getItemTypesForTier:(unsigned int)tier
{
    // TODO: implement item list retrieval from server
    
    // HACK
    return [self tier0ItemTypes];
    // HACK
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
