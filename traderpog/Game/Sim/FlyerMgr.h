//
//  FlyerMgr.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/22/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerTYpe.h"
#import "HttpCallbackDelegate.h"
#import <Foundation/Foundation.h>

@class Flyer;
@class TradePost;
@interface FlyerMgr : NSObject<HttpCallbackDelegate>
{
    NSMutableArray* _playerFlyers;
    
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<HttpCallbackDelegate>* _delegate;
}
@property (nonatomic,strong) NSMutableArray* playerFlyers;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegate;

- (BOOL) newPlayerFlyerAtTradePost:(TradePost*)tradePost
                        firstFlyer:(FlyerType*)flyerType;
- (void) loadFlyersFromServer;
- (void) updateFlyersAtDate:(NSDate*)currentTime;

// singleton
+(FlyerMgr*) getInstance;
+(void) destroyInstance;


@end
