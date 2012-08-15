//
//  TradeManager.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/11/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "TradeManager.h"
#import "TradePost.h"
#import "Flyer.h"
#import "TradeItemTypes.h"
#import "TradeItemType.h"
#import "Player.h"

@interface TradeManager ()
- (void) flyer:(Flyer*)flyer sellAtPost:(TradePost*)post;
@end

@implementation TradeManager

- (void) flyer:(Flyer *)flyer buyFromPost:(TradePost *)post numItems:(unsigned int)numItems
{
    // if Flyer has another item type, ask user if they want to dump it
    // TODO
    
    // compute num items flyer can afford
    TradeItemType* itemType = [[TradeItemTypes getInstance] getItemTypeForId:[post itemId]];
    unsigned int bucks = [[Player getInstance] bucks];
    unsigned int numAfford = bucks / [itemType price];
    unsigned int numToBuy = MIN([post supplyLevel], numAfford);
    
    // deduct num items from post
    [post deductNumItems:numToBuy];
    NSLog(@"Trade: deduct %d items from post %@; post now has %d items", numToBuy, [post postId], [post supplyLevel]);
    
    // deduct player bucks
    unsigned int cost = MIN(numToBuy * [itemType price], bucks);
    [[Player getInstance] deductBucks:cost];
    NSLog(@"Trade: deduct %d coins from player", cost);

    // place order in escrow
    [flyer orderItemId:[post itemId] num:numToBuy price:[itemType price]];
    NSLog(@"Trade: placed order for %d items of %@ at price %d", numToBuy, [post itemId], [itemType price]);
}

- (void) flyer:(Flyer *)flyer didArriveAtPost:(TradePost *)post
{
    if([post isOwnPost])
    {
        [self flyer:flyer sellAtPost:post];
    }
    else
    {
        // other's post
        
        // TODO: proceed to timesink
        
        // release escrow
        [flyer commitOutstandingOrder];
    }
}

- (BOOL) playerCanAffordItemsAtPost:(TradePost *)post
{
    TradeItemType* itemType = [[TradeItemTypes getInstance] getItemTypeForId:[post itemId]];
    unsigned int bucks = [[Player getInstance] bucks];
    unsigned int numAfford = bucks / [itemType price];
    BOOL result = NO;
    if(numAfford)
    {
        result = YES;
    }
    return result;
}

#pragma mark - internal
- (void) flyer:(Flyer *)flyer sellAtPost:(TradePost *)post
{
    NSAssert([post isOwnPost], @"flyer can only sell at own posts");
    
    // HACK
    // TODO: compute with formulae in PogPanBible (need flight time first)
    float earnings = ceilf([flyer costBasis] * [flyer numItems] * 1.2f);
    [[Player getInstance] addBucks:(NSUInteger)earnings];
    // HACK
    
    // unload all items
    [flyer unloadAllItems];
}

#pragma mark - Singleton
static TradeManager* singleton = nil;
+ (TradeManager*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
			singleton = [[TradeManager alloc] init];
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
