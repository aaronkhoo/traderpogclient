//
//  WorldState.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WorldState : NSObject<NSCoding>
{
    NSMutableDictionary* _activeTradePosts; // value TradePost; key tradePost identifier
}
@property (nonatomic,strong) NSMutableDictionary* activeTradePosts;
@end
