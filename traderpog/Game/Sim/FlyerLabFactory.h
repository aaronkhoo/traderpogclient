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
@class FlyerType;
@interface FlyerLabFactory : NSObject
{
    NSMutableDictionary* _colorPacks;
    NSMutableArray* _upgradePacks;
    unsigned int _priceColorCustomization;
    NSMutableDictionary* _topImages;
    NSMutableDictionary* _sideImages;
    NSMutableArray* _fallbackFlyerTypesArray;
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

// FlyerType fallbacks (dev use only in case we reset server and forget to populate the flyer_infos table)
- (FlyerType*) fallbackFlyerTypeForFlyerTypeId:(NSInteger)typeId;
- (FlyerType*) fallbackFlyerTypeAtIndex:(NSInteger)index;   // this is an index from 0 to numFallbackFlyerTypes
- (NSInteger) numFallbackFlyerTypes;

// singleton
+(FlyerLabFactory*) getInstance;
+(void) destroyInstance;

@end
