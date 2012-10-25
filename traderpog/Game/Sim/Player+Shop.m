//
//  Player+Shop.m
//  traderpog
//
//  Shop related queries on Player
//  This includes flyer upgrades, flyer customization, and instant-load/unload
//
//  Created by Shu Chiun Cheah on 10/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "Player+Shop.h"
#import "FlyerUpgradePack.h"
#import "FlyerColorPack.h"
#import "FlyerLabFactory.h"
#import "Flyer.h"
#import "FlyerType.h"
#import "FlyerTypes.h"
#import "FlyerMgr.h"
#import "TradePostMgr.h"
#import "GameManager.h"

@implementation Player (Shop)

#pragma mark - flyer lab
- (BOOL) canAffordFlyerUpgradeTier:(unsigned int)tier
{
    BOOL result = NO;
    FlyerUpgradePack* pack = [[FlyerLabFactory getInstance] upgradeForTier:tier];
    if([self bucks] >= [pack price])
    {
        result = YES;
    }
    return result;
}

- (void) buyUpgradeTier:(unsigned int)tier forFlyer:(Flyer *)flyer
{
    FlyerUpgradePack* pack = [[FlyerLabFactory getInstance] upgradeForTier:tier];
    [self deductBucks:[pack price]];
    [flyer applyUpgradeTier:tier];
}

- (BOOL) canAffordFlyerColor
{
    BOOL result = NO;
    unsigned int price = [[FlyerLabFactory getInstance] priceForColorCustomization];
    if([self bucks] >= price)
    {
        result = YES;
    }
    return result;
}

- (void) buyColorCustomization:(unsigned int)colorIndex forFlyer:(Flyer *)flyer
{
    unsigned int price = [[FlyerLabFactory getInstance] priceForColorCustomization];
    [self deductBucks:price];
    [flyer applyColor:colorIndex];
}

- (BOOL) canAffordFlyerType:(FlyerType *)flyerType
{
    BOOL result = NO;
    unsigned int price = [flyerType price];
    if([self bucks] >= price)
    {
        result = YES;
    }
    return result;
}

- (void) buyFlyerType:(FlyerType *)flyerType
{
    // pay money
    unsigned int price = [flyerType price];
    [self deductBucks:price];
    
    // get flyer
    GameViewController* game = [[GameManager getInstance] gameViewController];
    TradePost* newFlyerPost = [[TradePostMgr getInstance] getFirstMyTradePost];
    if([newFlyerPost flyerAtPost])
    {
        // there's already a flyer at home, generate an npc post nearby
        CLLocationCoordinate2D newCoord = [newFlyerPost coord];
        CLLocation* newLoc = [game.mapControl availableLocationNearCoord:newCoord visibleOnly:YES];
        if(newLoc)
        {
            newCoord = [newLoc coordinate];
        }
        
        newFlyerPost = [[TradePostMgr getInstance] newNPCTradePostAtCoord:newCoord bucks:0];
        [game.mapControl addAnnotationForTradePost:newFlyerPost isScan:YES];
    }
    
    NSInteger flyerTypeIndex = [[FlyerTypes getInstance] getFlyerIndexById:[flyerType flyerId]];
    [[FlyerMgr getInstance] newPlayerFlyerAtTradePost:newFlyerPost purchasedFlyerTypeIndex:flyerTypeIndex];
}

#pragma mark - labor
- (unsigned int) priceForExtraHelp
{
    // TODO: charge a percentage of the buying cost
    return 50;
}

- (BOOL) canAffordExtraHelp
{
    BOOL result = NO;
    unsigned int price = [self priceForExtraHelp];
    if([self bucks] >= price)
    {
        result = YES;
    }
    
    return result;
}

- (void) buyExtraHelp
{
    unsigned int price = [self priceForExtraHelp];
    [self deductBucks:price];
}

#pragma mark - miscellaneous fees
static const float kGoFeeFrac = 0.2f;
static const float kGoFeeMax = 50;
- (unsigned int) goFee
{
    float fee = kGoFeeFrac * ((float)[self bucks]);
    unsigned int result = MIN(kGoFeeMax, ((unsigned int)fee));
    return (result);
}


@end
