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

@implementation Player (Shop)
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
@end
