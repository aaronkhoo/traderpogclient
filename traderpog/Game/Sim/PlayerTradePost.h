//
//  PlayerTradePost.h
//  traderpog
//
//  Created by Aaron Khoo on 8/31/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TradePost.h"

static NSString* const kKeyTradePostId = @"id";
static NSString* const kKeyTradeUserId = @"user_id";
static NSString* const kKeyTradeLong = @"longitude";
static NSString* const kKeyTradeLat = @"latitude";
static NSString* const kKeyTradeItemId = @"item_info_id";
static NSString* const kKeyTradeImgPath= @"img";
static NSString* const kKeyTradeSupply = @"supply";
static NSString* const kKeyTradeSupplyRateLevel = @"supplymaxlevel";
static NSString* const kKeyTradeSupplyMaxLevel = @"supplyratelevel";
static NSString* const kKeyTradeBeacontime = @"beacontime";
static NSString* const kKeyTradeFBId = @"fbid";

@interface PlayerTradePost : TradePost
{
    NSDate*     _beacontime;
}

- (id) initWithDictionary:(NSDictionary*)dict;

@end
