//
//  TradeItemType.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/15/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "TradeItemType.h"

@implementation TradeItemType
@synthesize itemId = _itemId;
@synthesize name = _name;
@synthesize desc = _desc;

- (id) initWithItemId:(NSString *)itemId name:(NSString *)name desc:(NSString *)desc
{
    self = [super init];
    if(self)
    {
        _itemId = itemId;
        _name = name;
        _desc = desc;
    }
    return self;
}

- (id) initWithDictionary:(NSDictionary*)dict
{
    self = [super init];
    if(self)
    {
        _itemId = [dict valueForKeyPath:@"id"];
        _name = [dict valueForKeyPath:@"localized_name"];
        _desc = [dict valueForKeyPath:@"localized_desc"];
        _price =[[dict valueForKeyPath:@"price"] integerValue];
        _supplymax =[[dict valueForKeyPath:@"supplymax"] integerValue];
        _supplyrate =[[dict valueForKeyPath:@"supplyrate"] integerValue];
        _multiplier =[[dict valueForKeyPath:@"multiplier"] integerValue];
    }
    return self;
}

#pragma mark - convenience methods
+ (TradeItemType*) itemWithId:(NSString *)itemId name:(NSString *)name desc:(NSString *)desc
{
    TradeItemType* newItemType = [[TradeItemType alloc] initWithItemId:itemId name:name desc:desc];
    NSLog(@"newItemType %@, %@, %@", itemId, name, desc);
    return newItemType;
}

@end
