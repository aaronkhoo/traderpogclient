//
//  Player+Shop.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "Player.h"

@class Flyer;
@interface Player (Shop)
- (BOOL) canAffordFlyerUpgradeTier:(unsigned int)tier;
- (void) buyUpgradeTier:(unsigned int)tier forFlyer:(Flyer*)flyer;
- (BOOL) canAffordFlyerColor;
- (void) buyColorCustomization:(unsigned int)colorIndex forFlyer:(Flyer*)flyer;
@end
