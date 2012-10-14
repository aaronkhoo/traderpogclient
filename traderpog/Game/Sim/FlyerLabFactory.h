//
//  FlyerLabFactory.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FlyerUpgradePack;
@class FlyerColorPack;
@interface FlyerLabFactory : NSObject
{
    NSMutableDictionary* _colorPacks;
    NSMutableArray* _upgradePacks;
    unsigned int _priceColorCustomization;
    NSMutableDictionary* _topImages;
    NSMutableDictionary* _sideImages;
}

// upgrades
- (unsigned int) maxUpgradeTier;
- (unsigned int) nextUpgradeTierForTier:(unsigned int)tier;
- (FlyerUpgradePack*) upgradeForTier:(unsigned int)tier;

// colors
- (unsigned int) priceForColorCustomization;
- (FlyerColorPack*) colorPackAtIndex:(unsigned int)index forFlyerTypeNamed:(NSString*)name;
- (unsigned int) numColorsForFlyerTypeNamed:(NSString*)name;
- (unsigned int) maxColorIndex;

// images
- (NSString*) sideImageForFlyerTypeNamed:(NSString*)name
                                    tier:(unsigned int)tier
                              colorIndex:(unsigned int)colorIndex;
- (NSString*) topImageForFlyerTypeNamed:(NSString*)name
                                    tier:(unsigned int)tier
                              colorIndex:(unsigned int)colorIndex;

// singleton
+(FlyerLabFactory*) getInstance;
+(void) destroyInstance;

@end
