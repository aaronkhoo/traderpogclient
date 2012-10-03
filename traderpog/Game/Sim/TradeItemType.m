//
//  TradeItemType.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/15/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "TradeItemType.h"

// encoding keys
static NSString* const kKeyVersion = @"version";
static NSString* const kKeyItemId = @"id";
static NSString* const kKeyName = @"localized_name";
static NSString* const kKeyDesc = @"localized_desc";
static NSString* const kKeyPrice = @"price";
static NSString* const kKeySupplyMax = @"supplymax";
static NSString* const kKeySupplyRate = @"supplyrate";
static NSString* const kKeyMultiplier = @"multiplier";
static NSString* const kKeyTier = @"tier";

// HACK
// image names need to come from server DB
static const unsigned int kHackNumImageNames = 9;
static NSString* const kItemImageNames[kHackNumImageNames] =
{
    // tier 1
    @"item_grain.png",
    @"item_rice.png",
    @"item_eggs.png",
    
    // tier 2
    @"item_flour.png",
    @"item_milk.png",
    @"item_apple.png",
    
    // tier 3
    @"item_cake.png",
    @"item_corn.png",
    @"item_pie.png"
};

// HACK

@implementation TradeItemType
@synthesize itemId = _itemId;
@synthesize name = _name;
@synthesize desc = _desc;
@synthesize price = _price;
@synthesize supplymax = _supplymax;
@synthesize supplyrate = _supplyrate;
@synthesize multiplier = _multiplier;
@synthesize tier = _tier;

// HACK
- (NSString* const) hackGetImgPathForItemId:(NSString*)itemId
{
    NSInteger itemIndex = [itemId integerValue] - 1;
    if(0 > itemIndex)
    {
        itemIndex = 0;
    }
    else if(kHackNumImageNames <= itemIndex)
    {
        itemIndex = kHackNumImageNames - 1;
    }
    
    return kItemImageNames[itemIndex];
}
// HACK

- (id) initWithDictionary:(NSDictionary*)dict
{
    self = [super init];
    if(self)
    {
        _itemId = [NSString stringWithFormat:@"%d", [[dict valueForKeyPath:kKeyItemId] integerValue]];
        _name = [dict valueForKeyPath:kKeyName];
        _desc = [dict valueForKeyPath:kKeyDesc];
        _price =[[dict valueForKeyPath:kKeyPrice] integerValue];
        _supplymax =[[dict valueForKeyPath:kKeySupplyMax] integerValue];
        _supplyrate =[[dict valueForKeyPath:kKeySupplyRate] integerValue];
        _multiplier =[[dict valueForKeyPath:kKeyMultiplier] integerValue];
        _tier = [[dict valueForKeyPath:kKeyTier] integerValue];
        
        // HACK (should come from dictionary)
        _imgPath = [self hackGetImgPathForItemId:_itemId];
        // HACK
    }
    return self;
}

#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{    
    [aCoder encodeObject:_createdVersion forKey:kKeyVersion];
    [aCoder encodeObject:_itemId forKey:kKeyItemId];
    [aCoder encodeObject:_name forKey:kKeyName];
    [aCoder encodeObject:_desc forKey:kKeyDesc];
    [aCoder encodeObject:[NSNumber numberWithInteger:_price] forKey:kKeyPrice];
    [aCoder encodeObject:[NSNumber numberWithInteger:_supplymax] forKey:kKeySupplyMax];
    [aCoder encodeObject:[NSNumber numberWithInteger:_supplyrate] forKey:kKeySupplyRate];
    [aCoder encodeObject:[NSNumber numberWithInteger:_multiplier] forKey:kKeyMultiplier];
    [aCoder encodeObject:[NSNumber numberWithInteger:_tier] forKey:kKeyTier];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _createdVersion = [aDecoder decodeObjectForKey:kKeyVersion];
    _itemId = [aDecoder decodeObjectForKey:kKeyItemId];
    _name = [aDecoder decodeObjectForKey:kKeyName];
    _desc = [aDecoder decodeObjectForKey:kKeyDesc];
    _price = [[aDecoder decodeObjectForKey:kKeyPrice] integerValue];
    _supplymax = [[aDecoder decodeObjectForKey:kKeySupplyMax] integerValue];
    _supplyrate = [[aDecoder decodeObjectForKey:kKeySupplyRate] integerValue];
    _multiplier = [[aDecoder decodeObjectForKey:kKeyMultiplier] integerValue];
    _tier = [[aDecoder decodeObjectForKey:kKeyTier] integerValue];
    
    // HACK (should come from dictionary)
    _imgPath = [self hackGetImgPathForItemId:_itemId];
    // HACK
    
    return self;
}

@end
