//
//  FlyerUpgradePack.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerUpgradePack.h"
#import "NSDictionary+Pog.h"

NSString* const kKeyUpgradeTier = @"tier";
NSString* const kKeyUpgradeCapacity = @"capacity";
NSString* const kKeyUpgradeSpeed = @"speed";
NSString* const kKeyUpgradeStorm = @"storm";
NSString* const kKeyUpgradePrice = @"price";

@implementation FlyerUpgradePack
@synthesize tier = _tier;
@synthesize capacityFactor = _capacityFactor;
@synthesize speedFactor = _speedFactor;
@synthesize stormFactor = _stormFactor;
@synthesize price = _price;

- (id) init
{
    NSAssert(false, @"must use initDictionary to create FlyerUpgradePack");
    return nil;
}

- (id) initWithDictionary:(NSDictionary*)dict
{
    self = [super init];
    if(self)
    {
        _tier = [dict getUnsignedIntForKey:kKeyUpgradeTier withDefault:1];
        _capacityFactor = [dict getFloatForKey:kKeyUpgradeCapacity withDefault:1.0f];
        _speedFactor = [dict getFloatForKey:kKeyUpgradeSpeed withDefault:1.0f];
        _stormFactor = [dict getFloatForKey:kKeyUpgradeStorm withDefault:1.0f];
        _price = [dict getUnsignedIntForKey:kKeyUpgradePrice withDefault:200];
    }
    return self;
}
@end
