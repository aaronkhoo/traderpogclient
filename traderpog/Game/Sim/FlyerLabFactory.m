//
//  FlyerLabFactory.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerLabFactory.h"
#import "FlyerColorPack.h"
#import "FlyerUpgradePack.h"
#import "NSDictionary+Pog.h"

static NSString* const kKeyColorPacks = @"color_packs";
static NSString* const kKeyUpgradePacks = @"upgrade_packs";
static NSString* const kKeyColorPrice = @"color_price";
static NSString* const kKeyFlyerImages = @"flyer_images";
static NSString* const kKeyTop = @"top";
static NSString* const kKeySide = @"side";

@interface FlyerLabFactory ()
- (void) initColorPacksWithDictionary:(NSDictionary*)dict;
@end

@implementation FlyerLabFactory

- (id) init
{
    self = [super init];
    if(self)
    {
        NSString* filepath = [[NSBundle mainBundle] pathForResource:@"flyerlab" ofType:@"plist"];
        NSDictionary* packs = [NSDictionary dictionaryWithContentsOfFile:filepath];
        
        // colors
        NSDictionary* colorPacks = [packs objectForKey:kKeyColorPacks];
        [self initColorPacksWithDictionary:colorPacks];
        _priceColorCustomization = [packs getUnsignedIntForKey:kKeyColorPrice withDefault:200];
        
        // upgrades
        NSArray* upgradePacks = [packs objectForKey:kKeyUpgradePacks];
        _upgradePacks = [NSMutableArray arrayWithCapacity:10];
        for(NSDictionary* cur in upgradePacks)
        {
            FlyerUpgradePack* newPack = [[FlyerUpgradePack alloc] initWithDictionary:cur];
            [_upgradePacks addObject:newPack];
        }
        
        NSDictionary* imageDict = [packs objectForKey:kKeyFlyerImages];
        _topImages = [NSMutableDictionary dictionaryWithCapacity:10];
        _sideImages = [NSMutableDictionary dictionaryWithCapacity:10];
        for(NSString* curKey in imageDict)
        {
            NSDictionary* cur = [imageDict objectForKey:curKey];
            NSArray* top = [cur objectForKey:kKeyTop];
            NSArray* side = [cur objectForKey:kKeySide];
            [_topImages setObject:top forKey:curKey];
            [_sideImages setObject:side forKey:curKey];
        }
    }
    return self;
}

#pragma mark - upgrades

- (unsigned int) maxUpgradeTier
{
    unsigned int result = [_upgradePacks count];
    return result;
}

- (unsigned int) nextUpgradeTierForTier:(unsigned int)tier
{
    unsigned int result = MIN(tier+1, [self maxUpgradeTier]);
    return result;
}

- (FlyerUpgradePack*) upgradeForTier:(unsigned int)tier
{
    FlyerUpgradePack* result = nil;
    if((0 < tier) && (tier <= [_upgradePacks count]))
    {
        result = [_upgradePacks objectAtIndex:tier-1];
    }
    else
    {
        // if query tier is out of range, just return the default pack, which is Identity
        result = [[FlyerUpgradePack alloc] init];
    }
    return result;
}

#pragma mark - colors

- (unsigned int) priceForColorCustomization
{
    return _priceColorCustomization;
}

- (FlyerColorPack*) colorPackAtIndex:(unsigned int)index forFlyerTypeNamed:(NSString *)name
{
    FlyerColorPack* result = nil;
    NSArray* packsArray = [_colorPacks objectForKey:name];
    if(packsArray && (index < [packsArray count]))
    {
        result = [packsArray objectAtIndex:index];
    }
    return result;
}

- (unsigned int) numColorsForFlyerTypeNamed:(NSString*)name
{
    unsigned int result = 0;
    NSArray* packsArray = [_colorPacks objectForKey:name];
    if(packsArray)
    {
        result = [packsArray count];
    }
    return result;
}

- (unsigned int) maxColorIndex
{
    return 3;
}

#pragma mark - images
- (NSString*) sideImageForFlyerTypeNamed:(NSString *)name
                                    tier:(unsigned int)tier
                              colorIndex:(unsigned int)colorIndex
{
    NSString* result = nil;
    NSArray* curArray = [_sideImages objectForKey:name];
    if(curArray)
    {
       if(tier < [curArray count])
       {
           NSDictionary* reg = [curArray objectAtIndex:tier];
           if(reg)
           {
               FlyerColorPack* colorPack = [self colorPackAtIndex:colorIndex forFlyerTypeNamed:name];
               if(colorPack)
               {
                   result = [reg objectForKey:[colorPack name]];
               }
           }
       }
    }
    return result;
}

- (NSString*) topImageForFlyerTypeNamed:(NSString *)name
                                    tier:(unsigned int)tier
                              colorIndex:(unsigned int)colorIndex
{
    NSString* result = nil;
    NSArray* curArray = [_topImages objectForKey:name];
    if(curArray)
    {
        if(tier < [curArray count])
        {
            NSDictionary* reg = [curArray objectAtIndex:tier];
            if(reg)
            {
                FlyerColorPack* colorPack = [self colorPackAtIndex:colorIndex forFlyerTypeNamed:name];
                if(colorPack)
                {
                    result = [reg objectForKey:[colorPack name]];
                }
            }
        }
    }
    return result;
}

#pragma mark - internal methods
- (void) initColorPacksWithDictionary:(NSDictionary *)dict
{
    _colorPacks = [NSMutableDictionary dictionaryWithCapacity:10];
    for(NSString* curKey in dict)
    {
        NSArray* cur = [dict objectForKey:curKey];
        NSMutableArray* flyerPacks = [NSMutableArray arrayWithCapacity:[cur count]];
        for(NSDictionary* curPack in cur)
        {
            FlyerColorPack* newPack = [[FlyerColorPack alloc] initWithDictionary:curPack];
            [flyerPacks addObject:newPack];
        }
        [_colorPacks setObject:flyerPacks forKey:curKey];
    }

}

#pragma mark - Singleton
static FlyerLabFactory* singleton = nil;
+ (FlyerLabFactory*) getInstance
{
	@synchronized(self)
	{
        if (!singleton)
        {
            singleton = [[FlyerLabFactory alloc] init];
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
