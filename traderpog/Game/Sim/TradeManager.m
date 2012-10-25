//
//  TradeManager.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/11/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "TradeManager.h"
#import "TradePost.h"
#import "TradePostMgr.h"
#import "Flyer.h"
#import "FlyerMgr.h"
#import "TradeItemTypes.h"
#import "TradeItemType.h"
#import "Player.h"
#import "Player+Shop.h"

#define METERS_TO_KM(dist) ((dist) * 0.001f)

static const int kTradeMaxItemTypes = 3;
static const float kTradeDistanceFactor = 0.001f;

@interface TradeManager ()
- (void) flyer:(Flyer*)flyer sellAtPost:(TradePost*)post;
- (float) premiumForItemTier:(int)tier;
@end

@implementation TradeManager

- (void) flyer:(Flyer *)flyer buyFromPost:(TradePost *)post numItems:(unsigned int)numItems
{
    // compute num items flyer can afford
    TradeItemType* itemType = [[TradeItemTypes getInstance] getItemTypeForId:[post itemId]];
    unsigned int bucks = [[Player getInstance] bucks];
    unsigned int numAfford = bucks / [itemType price];
    unsigned int numSupply = [post supplyLevel];
    unsigned int cost = 0;
    unsigned int num = 0;
    unsigned int remCap = [flyer remainingCapacity];
    if(!numAfford || !numSupply || !remCap ||
       (![post.itemId isEqualToString:[flyer.inventory itemId]]))
    {
        // if player can't afford, OR
        // no supply at post, OR
        // flyer capacity is full, OR
        // flyer is already carrying a different item than post item
        // don't buy anything, just charge player the Go Fee
        cost = [[Player getInstance] goFee];
        num = 0;
    }
    else
    {
        num = MIN(numSupply, numAfford);
        num = MIN(num, remCap);
        cost = num * [itemType price];

        // deduct num items from post
        [post deductNumItems:num];

        // place order in escrow
        [[flyer inventory] orderItemId:[post itemId] num:num price:[itemType price]];
        //NSLog(@"Trade: placed order for %d items of %@ at price %d", numToBuy, [post itemId], [itemType price]);
    }
    
    // deduct player bucks
    [[Player getInstance] deductBucks:cost];

}

- (void) flyer:(Flyer *)flyer didArriveAtPost:(TradePost *)post
{
    if([post isMemberOfClass:[MyTradePost class]])
    {
        // sell everything at post
        [self flyer:flyer sellAtPost:post];
    }
    else
    {
        // release escrow
        [[flyer inventory] commitOutstandingOrder];
    }
}

#pragma mark - queries on post
- (unsigned int) numItemsPlayerCanBuyAtPost:(TradePost*)post
{
    TradeItemType* itemType = [[TradeItemTypes getInstance] getItemTypeForId:[post itemId]];
    unsigned int bucks = [[Player getInstance] bucks];
    unsigned int numAfford = bucks / [itemType price];
    unsigned int num = MIN([post supplyLevel], numAfford);

    return num;
}

- (unsigned int) totalCostForNumItems:(unsigned int)num atPost:(TradePost*)post
{
    TradeItemType* itemType = [[TradeItemTypes getInstance] getItemTypeForId:[post itemId]];
    unsigned int bucks = [[Player getInstance] bucks];
    unsigned int cost = MIN(num * [itemType price], bucks);

    return cost = 0;
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

- (BOOL) playerHasIdleFlyers
{
    BOOL result = NO;
    for(Flyer* cur in [[FlyerMgr getInstance] playerFlyers])
    {
        if((kFlyerStateIdle == [cur state]) ||
           (kFlyerStateLoaded == [cur state]))
        {
            result = YES;
        }
    }
    return result;
}

#pragma mark - internal
- (void) flyer:(Flyer *)flyer sellAtPost:(TradePost *)post
{
    NSAssert([post isMemberOfClass:[MyTradePost class]], @"flyer can only sell at own posts");
    
    // store item id at post for ui purposes
    MyTradePost* myPost = (MyTradePost*)post;
    myPost.lastUnloadedItemId = [[flyer inventory] itemId];
    
    TradeItemType* itemType = [[TradeItemTypes getInstance] getItemTypeForId:[[flyer inventory] itemId]];
    float tierPremiumTerm = [self premiumForItemTier:[itemType tier]] + 1.0f;
    float distanceTerm = MAX(METERS_TO_KM([[flyer inventory] metersTraveled]) * kTradeDistanceFactor, 1.0f);
    float earnings = ceilf([[flyer inventory] costBasis] * [[flyer inventory] numItems] * tierPremiumTerm * distanceTerm);
    NSLog(@"Flyer earnings: tierPremium %f, distance %f km, distanceTerm %f, earnings %f",
          tierPremiumTerm, METERS_TO_KM([[flyer inventory] metersTraveled]), distanceTerm, earnings);
    
    [[Player getInstance] addBucks:(NSUInteger)earnings];
    
    // unload all items
    [[flyer inventory] unloadAllItems];
    
    // reset distance
    NSLog(@"Distance Traveled: %lf", [[flyer inventory] metersTraveled]);
    [[flyer inventory] resetDistanceTraveled];
}

- (float) premiumForItemTier:(int)tier
{
    // tier starts at 1 instead of 0
    float result = 0.0f;
    float kPremiums[kTradeMaxItemTypes+1] =
    {
        0.0f,
        0.2f,
        0.5f,
        0.8f
    };
    if(tier <= kTradeMaxItemTypes)
    {
        result = kPremiums[tier];
    }
    return result;
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
