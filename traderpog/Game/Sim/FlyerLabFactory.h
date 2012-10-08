//
//  FlyerLabFactory.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FlyerUpgradePack;
@interface FlyerLabFactory : NSObject
{
    NSMutableDictionary* _colorPacks;
    NSMutableArray* _upgradePacks;
}

- (unsigned int) maxUpgradeTier;
- (FlyerUpgradePack*) upgradeForTier:(unsigned int)tier;

// singleton
+(FlyerLabFactory*) getInstance;
+(void) destroyInstance;

@end
