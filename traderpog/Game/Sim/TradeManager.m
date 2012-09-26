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
    [[flyer inventory] orderItemId:[post itemId] num:numToBuy price:[itemType price]];
    NSLog(@"Trade: placed order for %d items of %@ at price %d", numToBuy, [post itemId], [itemType price]);
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
