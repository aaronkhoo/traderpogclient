//
//  WorldState.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "WorldState.h"
#import "Player.h"
#import "FlyerMgr.h"
#import "Flyer.h"
#import "GameManager.h"

static NSString* const kWorldFilename = @"world.sav";

static NSString* const kKeyPlayerBucks = @"bucks";
static NSString* const kKeyFlyersInventory = @"flyersInventory";

// flyer inventory
NSString* const kKeyFlyerItemId = @"flyerItemId";
NSString* const kKeyFlyerNumItems = @"flyerNumItems";
NSString* const kKeyFlyerCostBasis = @"flyerCostBasis";

@implementation WorldState
@synthesize flyersInventory = _flyersInventory;

- (id) init
{
    self = [super init];
    if(self)
    {
        _flyersInventory = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    return self;
}

- (void) refreshDataFromGame
{
    [_flyersInventory removeAllObjects];
    for(Flyer* cur in [[FlyerMgr getInstance] playerFlyers])
    {
        NSDictionary* curData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [cur itemId], kKeyFlyerItemId,
                                 [NSNumber numberWithUnsignedInt:[cur numItems]], kKeyFlyerNumItems,
                                 [NSNumber numberWithFloat:[cur costBasis]], kKeyFlyerCostBasis, nil];
        [_flyersInventory setObject:curData forKey:[cur userFlyerId]];
    }
}

- (void) setDataIntoFlyer:(Flyer *)flyer
{
    NSDictionary* curData = [[self flyersInventory] objectForKey:[flyer userFlyerId]];
    if(curData)
    {
        flyer.itemId = [curData objectForKey:kKeyFlyerItemId];
        flyer.numItems = [[curData objectForKey:kKeyFlyerNumItems] unsignedIntValue];
        flyer.costBasis = [[curData objectForKey:kKeyFlyerCostBasis] floatValue];
    }
}

+ (NSString*) filepath
{
    NSString* docsDir = [GameManager documentsDirectory];
    NSString* filepath = [docsDir stringByAppendingPathComponent:kWorldFilename];
    return filepath;
}


#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [self refreshDataFromGame];
    [aCoder encodeObject:_flyersInventory forKey:kKeyFlyersInventory];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self.flyersInventory = [aDecoder decodeObjectForKey:kKeyFlyersInventory];
    return self;
}

@end
