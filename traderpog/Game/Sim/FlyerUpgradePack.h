//
//  FlyerUpgradePack.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const kKeyUpgradeTier;
extern NSString* const kKeyUpgradeCapacity;
extern NSString* const kKeyUpgradeSpeed;
extern NSString* const kKeyUpgradeStorm;

@interface FlyerUpgradePack : NSObject
{
    unsigned int    _tier; // starts from 1
    float           _capacityFactor;
    float           _speedFactor;
    float           _stormFactor;
    unsigned int    _price;
    NSString*       _img;
    NSString*       _secondTitle;
}
@property (nonatomic,readonly) unsigned int tier;
@property (nonatomic,readonly) float capacityFactor;
@property (nonatomic,readonly) float speedFactor;
@property (nonatomic,readonly) float stormFactor;
@property (nonatomic,readonly) unsigned int price;
@property (nonatomic,readonly) NSString* img;
@property (nonatomic,readonly) NSString* secondTitle;

- (id) initWithDictionary:(NSDictionary*)dict;

@end
