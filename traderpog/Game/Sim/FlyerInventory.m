//
//  FlyerInventory.m
//  traderpog
//
//  Created by Aaron Khoo on 9/2/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerInventory.h"
#import "Player.h"

static NSString* const kKeyVersion = @"version";
static NSString* const kKeyItemId = @"itemId";
static NSString* const kKeyNumItems = @"numItems";
static NSString* const kKeyCostBasis = @"costBasis";
static NSString* const kKeyOrderItemId = @"orderItemId";
static NSString* const kKeyOrderNumItems = @"orderNumItems";
static NSString* const kKeyOrderMoney = @"orderPrice";
static NSString* const kKeyMetersTraveled = @"metersTraveled";

@interface FlyerInventory ()
{
    // internal
    NSString* _createdVersion;
}
@end

@implementation FlyerInventory

@synthesize itemId = _itemId;
@synthesize numItems = _numItems;
@synthesize costBasis = _costBasis;
@synthesize orderItemId = _orderItemId;
@synthesize orderNumItems = _orderNumItems;
@synthesize orderPrice = _orderPrice;
@synthesize metersTraveled = _metersTraveled;

- (id) init
{
    self = [super init];
    if(self)
    {
        _itemId = nil;
        _numItems = 0;
        _costBasis = 0.0f;
        _orderItemId = nil;
        _orderNumItems = 0;
        _orderPrice = 0;
        _metersTraveled = 0.0;
    }
    return self;
}

- (id) initWithDictionary:(NSDictionary*)dict
{
    self = [super init];
    if(self)
    {
        // inventory
        id obj = [dict valueForKeyPath:kKeyItemId];
        if (obj)
        {
            _itemId = [NSString stringWithFormat:@"%d", [obj integerValue]];
        }
        else
        {
            // no item for this flyer
            _itemId = nil;
        }
        obj = [dict valueForKeyPath:kKeyNumItems];
        if (obj)
        {
            _numItems = [obj unsignedIntegerValue];
        }
        else
        {
            _numItems = 0;
        }
        obj = [dict valueForKeyPath:kKeyCostBasis];
        if (obj)
        {
            _costBasis = [obj floatValue];
        }
        else
        {
            _costBasis = 0.0f;
        }
        
        // escrow
        obj = [dict valueForKeyPath:kKeyOrderItemId];
        if (obj)
        {
            _orderItemId = [NSString stringWithFormat:@"%d", [obj integerValue]];
        }
        else
        {
            // no item for this flyer
            _orderItemId = nil;
        }
        obj = [dict valueForKeyPath:kKeyOrderNumItems];
        if (obj)
        {
            _orderNumItems = [obj unsignedIntValue];
        }
        else
        {
            _orderNumItems = 0;
        }
        obj = [dict valueForKeyPath:kKeyOrderMoney];
        if (obj)
        {
            _orderPrice = [obj unsignedIntValue];
        }
        else
        {
            _orderPrice = 0;
        }
        
        // meters traveled
        obj = [dict valueForKeyPath:kKeyMetersTraveled];
        if ((NSNull *)obj == [NSNull null])
        {
            _metersTraveled = 0.0;
        }
        else
        {
            _metersTraveled = [obj doubleValue];
        }
    }
    return self;
}

#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{    
    [aCoder encodeObject:_createdVersion forKey:kKeyVersion];
    [aCoder encodeObject:_itemId forKey:kKeyItemId];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInt:_numItems] forKey:kKeyNumItems];
    [aCoder encodeFloat:_costBasis forKey:kKeyCostBasis];
    [aCoder encodeObject:_orderItemId forKey:kKeyOrderItemId];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInt:_orderNumItems] forKey:kKeyOrderNumItems];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInt:_orderPrice] forKey:kKeyOrderMoney];
    [aCoder encodeDouble:_metersTraveled forKey:kKeyMetersTraveled];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _createdVersion = [aDecoder decodeObjectForKey:kKeyVersion];
    _itemId = [aDecoder decodeObjectForKey:kKeyItemId];
    _numItems = [[aDecoder decodeObjectForKey:kKeyNumItems] unsignedIntValue];
    _costBasis = [aDecoder decodeFloatForKey:kKeyCostBasis];
    _orderItemId = [aDecoder decodeObjectForKey:kKeyOrderItemId];
    _orderNumItems = [[aDecoder decodeObjectForKey:kKeyOrderNumItems] unsignedIntValue];
    _orderPrice = [[aDecoder decodeObjectForKey:kKeyOrderMoney] unsignedIntValue];
    _metersTraveled = [aDecoder decodeDoubleForKey:kKeyMetersTraveled];
    return self;
}

#pragma mark - trade
- (void) addItemId:(NSString *)newItemId num:(unsigned int)num price:(unsigned int)price
{
    if([self itemId] &&
       (NSOrderedSame != [self.itemId compare:newItemId]))
    {
        // if different item, dump existing inventory
        [self unloadAllItems];
        NSLog(@"Flyer: dumped current items");
    }
    
    unsigned int newNumItems = [self numItems] + num;
    float newCostBasis = (((float) [self numItems] * [self costBasis]) + ((float)price * (float)num)) / ((float)newNumItems);
    
    self.costBasis = newCostBasis;
    self.itemId = newItemId;
    self.numItems = newNumItems;
    
    NSLog(@"Flyer: inventory updated %d items of %@ at cost %f", newNumItems, newItemId, newCostBasis);
    NSLog(@"Flyer: current (%d, %d, %@, %f)", [[Player getInstance] bucks], [self numItems], [self itemId], [self costBasis]);
}

// place an order in ecrow (will commit when flyer arrives at post and finishes loading)
- (void) orderItemId:(NSString *)itemId num:(unsigned int)num price:(unsigned int)price
{
    self.orderItemId = itemId;
    self.orderNumItems = num;
    self.orderPrice = price;
}

- (void) commitOutstandingOrder
{
    if([self orderItemId])
    {
        [self addItemId:[self orderItemId] num:[self orderNumItems] price:[self orderPrice]];
        
        // clear escrow
        self.orderItemId = nil;
        self.orderNumItems = 0;
        self.orderPrice = 0;
    }
}

- (void) revertOutstandingOrder
{
    if([self orderItemId])
    {
        [self addItemId:[self orderItemId] num:[self orderNumItems] price:[self orderPrice]];
        
        // credit the player
        [[Player getInstance] addBucks:[self orderPrice] * [self orderNumItems]];
        
        
        
        // clear escrow
        self.orderItemId = nil;
        self.orderNumItems = 0;
        self.orderPrice = 0;
    }
}

- (void) unloadAllItems
{
    self.costBasis = 0.0f;
    self.itemId = nil;
    self.numItems = 0;
}

- (void) resetDistanceTraveled
{
    _metersTraveled = 0.0;
}

- (void) incrementTravelDistance:(CLLocationDistance) routeDist
{
    _metersTraveled += routeDist;
    NSLog(@"Distance added: %lf (total %lf)", routeDist, _metersTraveled);
}

@end
