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

static NSString* const kKeyColorPacks = @"color_packs";
static NSString* const kKeyUpgradePacks = @"upgrade_packs";

@implementation FlyerLabFactory

- (id) init
{
    self = [super init];
    if(self)
    {
        NSString* filepath = [[NSBundle mainBundle] pathForResource:@"flyerlab" ofType:@"plist"];
        NSDictionary* packs = [NSDictionary dictionaryWithContentsOfFile:filepath];
        NSDictionary* colorPacks = [packs objectForKey:kKeyColorPacks];
        
        _colorPacks = [NSMutableDictionary dictionaryWithCapacity:10];
        for(NSString* curKey in colorPacks)
        {
            NSDictionary* cur = [colorPacks objectForKey:curKey];
            FlyerColorPack* newPack = [[FlyerColorPack alloc] initWithDictionary:cur];
            [_colorPacks setObject:newPack forKey:curKey];
        }
        
        NSDictionary* upgradePacks = [packs objectForKey:kKeyUpgradePacks];
        _upgradePacks = [NSMutableDictionary dictionaryWithCapacity:10];
        for(NSString* curKey in upgradePacks)
        {
            NSDictionary* cur = [upgradePacks objectForKey:curKey];
            FlyerUpgradePack* newPack = [[FlyerUpgradePack alloc] initWithDictionary:cur];
            [_upgradePacks setObject:newPack forKey:curKey];
        }
    }
    return self;
}

#pragma mark - Singleton
static FlyerLabFactory* singleton = nil;
+ (FlyerLabFactory*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
            if (!singleton)
            {
                singleton = [[FlyerLabFactory alloc] init];
            }
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