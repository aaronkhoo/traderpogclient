//
//  FlyerInventory.m
//  traderpog
//
//  Created by Aaron Khoo on 9/2/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AsyncHttpCallMgr.h"
#import "FlyerInventory.h"
#import "Player.h"

static NSString* const kKeyVersion = @"version";
static NSString* const kKeyItemId = @"item_info_id";
static NSString* const kKeyNumItems = @"num_items";
static NSString* const kKeyCostBasis = @"cost_basis";
static NSString* const kKeyOrderMoney = @"price";
static NSString* const kKeyMetersTraveled = @"meterstraveled";
static NSString* const kKeyFlyerPath = @"flyer_path";

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
        if ((NSNull *)obj == [NSNull null])
        {
            // no item for this flyer
            _itemId = nil;
        }
        else
        {
            _itemId = [NSString stringWithFormat:@"%d", [obj integerValue]];
        }
        obj = [dict valueForKeyPath:kKeyNumItems];
        if ((NSNull *)obj == [NSNull null])
        {
            _numItems = 0;
        }
        else
        {
            _numItems = [obj integerValue];
        }
        obj = [dict valueForKeyPath:kKeyCostBasis];
        if ((NSNull *)obj == [NSNull null])
        {
            _costBasis = 0.0f;
        }
        else
        {
            _costBasis = [obj floatValue];
        }
        obj = [dict valueForKeyPath:kKeyMetersTraveled];
        if ((NSNull *)obj == [NSNull null])
        {
            _metersTraveled = 0.0;
        }
        else
        {
            _metersTraveled = [obj doubleValue];
        }
        
        // escrow
        NSArray* paths_array = [dict valueForKeyPath:@"flyer_paths"];
        NSDictionary* path_dict = [paths_array objectAtIndex:0];
        obj = [path_dict valueForKeyPath:kKeyItemId];
        if ((NSNull *)obj == [NSNull null])
        {
            // no item for this flyer
            _orderItemId = nil;
        }
        else
        {
            _orderItemId = [NSString stringWithFormat:@"%d", [obj integerValue]];
        }
        obj = [path_dict valueForKeyPath:kKeyNumItems];
        if ((NSNull *)obj == [NSNull null])
        {
            _orderNumItems = 0;
        }
        else
        {
            _orderNumItems = [obj unsignedIntValue];
        }
        obj = [path_dict valueForKeyPath:kKeyOrderMoney];
        if ((NSNull *)obj == [NSNull null])
        {
            _orderPrice = 0;
        }
        else
        {
            _orderPrice = [obj unsignedIntValue];
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
    [aCoder encodeObject:_orderItemId forKey:kKeyItemId];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInt:_orderNumItems] forKey:kKeyNumItems];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInt:_orderPrice] forKey:kKeyOrderMoney];
    [aCoder encodeDouble:_metersTraveled forKey:kKeyMetersTraveled];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _createdVersion = [aDecoder decodeObjectForKey:kKeyVersion];
    _itemId = [aDecoder decodeObjectForKey:kKeyItemId];
    _numItems = [[aDecoder decodeObjectForKey:kKeyNumItems] unsignedIntValue];
    _costBasis = [aDecoder decodeFloatForKey:kKeyCostBasis];
    _orderItemId = [aDecoder decodeObjectForKey:kKeyItemId];
    _orderNumItems = [[aDecoder decodeObjectForKey:kKeyNumItems] unsignedIntValue];
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

#pragma mark - server calls
- (void) updateFlyerInventoryOnServer:(NSString*)userFlyerId
{
    NSString *flyerInventoryUrl = [NSString stringWithFormat:@"users/%d/user_flyers/%@", [[Player getInstance] playerId], userFlyerId];
    NSDictionary* parameters = [self createParametersForFlyerInventory];
    NSString* msg = [self createFlyerInventoryErrorMsg];
    [[AsyncHttpCallMgr getInstance] newAsyncHttpCall:flyerInventoryUrl
                                      current_params:parameters
                                     current_headers:nil
                                         current_msg:msg
                                        current_type:putType];
}

- (NSDictionary*) createParametersForFlyerInventory
{
    NSMutableDictionary* parameters = [[NSMutableDictionary alloc] init];
    NSMutableDictionary* flyerPathParameters = [[NSMutableDictionary alloc] init];
    
    if (_orderItemId)
    {
        [flyerPathParameters setObject:_orderItemId forKey:kKeyItemId];   
    }
    else
    {
        [flyerPathParameters setObject:[NSNull null] forKey:kKeyItemId];
    }
    [flyerPathParameters setValue:[NSNumber numberWithUnsignedInt:_orderNumItems] forKey:kKeyNumItems];
    [flyerPathParameters setValue:[NSNumber numberWithUnsignedInt:_orderPrice] forKey:kKeyOrderMoney];
    
    if (_itemId)
    {
        [parameters setObject:_itemId forKey:kKeyItemId];   
    }
    else
    {
        [parameters setObject:[NSNull null] forKey:kKeyItemId];
    }
    [parameters setValue:[NSNumber numberWithUnsignedInt:_numItems] forKey:kKeyNumItems];
    [parameters setValue:[NSNumber numberWithFloat:_costBasis] forKey:kKeyCostBasis];
    [parameters setValue:[NSNumber numberWithDouble:_metersTraveled] forKey:kKeyMetersTraveled];
    
    [parameters setObject:flyerPathParameters forKey:kKeyFlyerPath];
    
    return parameters;
}

- (NSString*) createFlyerInventoryErrorMsg
{
    NSString* msg = [NSString stringWithFormat:@"FlyerInventory update failed with params: orderItemID:%@ orderNumItems:%d orderItemPrice:%d currentItem:%@ numItems:%d costBasis:%f metersTraveled:%f",
                     _orderItemId, _orderNumItems, _orderPrice,
                     _itemId, _numItems, _costBasis, _metersTraveled];
    return msg;
}

@end
