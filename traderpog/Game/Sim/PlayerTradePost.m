//
//  PlayerTradePost.m
//  traderpog
//
//  Created by Aaron Khoo on 8/31/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "PlayerTradePost.h"
#import "PogUIUtility.h"

@implementation PlayerTradePost

- (id) initWithDictionary:(NSDictionary*)dict
{
    self = [super init];
    if(self)
    {
        _postId = [NSString stringWithFormat:@"%d", [[dict valueForKeyPath:kKeyTradePostId] integerValue]];
        _coord.latitude = [[dict valueForKeyPath:kKeyTradeLat] doubleValue];
        _coord.longitude = [[dict valueForKeyPath:kKeyTradeLong] doubleValue];
        _itemId = [NSString stringWithFormat:@"%d", [[dict valueForKeyPath:kKeyTradeItemId] integerValue]];
        _imgPath = [dict valueForKeyPath:kKeyTradeImgPath];
        _supplyMaxLevel =[[dict valueForKeyPath:kKeyTradeSupplyMaxLevel] integerValue];
        _supplyRateLevel =[[dict valueForKeyPath:kKeyTradeSupplyRateLevel] integerValue];
        _beacontime = nil;
        
        id obj = [dict valueForKeyPath:kKeyTradeBeacontime];
        if ((NSNull *)obj != [NSNull null])
        {
            NSString* utcdate = [NSString stringWithFormat:@"%@", obj];
            if (![utcdate isEqualToString:@"<null>"])
            {
                _beacontime = [PogUIUtility convertUtcToNSDate:utcdate];
            }
        }
        
        // transient variables
        _hasFlyer = NO;
    }
    return self;
}

@end
