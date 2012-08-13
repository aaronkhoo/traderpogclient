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
    
    // deduct player bucks
    [[Player getInstance] deductBucks:bucks];

    // place order in escrow
    [flyer orderItemId:[post itemId] num:numToBuy price:[itemType price]];
}

- (void) flyer:(Flyer *)flyer didArriveAtPost:(TradePost *)post
{
    if([post isOwnPost])
    {
        // TODO: handle home post
    }
    else
    {
        // other's post
        
        // TODO: proceed to timesink
        
        // release escrow
        [flyer commitOutstandingOrder];
    }
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
