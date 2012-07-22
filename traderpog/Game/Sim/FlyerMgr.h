//
//  FlyerMgr.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/22/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Flyer;
@class TradePost;
@interface FlyerMgr : NSObject
{
    NSMutableArray* _playerFlyers;
}
@property (nonatomic,strong) NSMutableArray* playerFlyers;

- (Flyer*) newPlayerFlyerAtTradePost:(TradePost*)tradePost;
- (void) loadFlyersFromServer;
- (void) updateFlyersAtDate:(NSDate*)currentTime;

// singleton
+(FlyerMgr*) getInstance;
+(void) destroyInstance;


@end
