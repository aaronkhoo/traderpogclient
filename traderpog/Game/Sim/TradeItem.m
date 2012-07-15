//
//  TradeItem.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/15/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "TradeItem.h"

static NSString* const kKeyItemType = @"itemType";
static NSString* const kKeyItemPrice = @"itemPrice";
static NSString* const kKeyItemRate = @"itemRate";

@implementation TradeItem
@synthesize itemType = _itemType;
@synthesize price = _price;
@synthesize restockRate = _restockRate;

- (id) initWithItemType:(TradeItemType *)itemType price:(unsigned int)price restockRate:(float)restockRate
{
    self = [super init];
    if(self)
    {
        _itemType = itemType;
        _price = price;
        _restockRate = restockRate;
    }
    return self;
}

#pragma mark - NSCoding

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:[self itemType] forKey:kKeyItemType];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInt:[self price]] forKey:kKeyItemPrice];
    [aCoder encodeFloat:[self restockRate] forKey:kKeyItemRate];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self.itemType = [aDecoder decodeObjectForKey:kKeyItemType];
    NSNumber* priceObj = [aDecoder decodeObjectForKey:kKeyItemPrice];
    if(priceObj)
    {
        self.price = [priceObj unsignedIntValue];
    }
    else 
    {
        self.price = 0;
    }
    self.restockRate = [aDecoder decodeFloatForKey:kKeyItemRate];
    return self;
}

@end
