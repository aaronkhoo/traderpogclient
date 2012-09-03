//
//  FlyerMgr.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/22/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerTYpe.h"
#import "HttpCallbackDelegate.h"
#import "WheelProtocol.h"
#import <Foundation/Foundation.h>

static NSString* const kFlyerMgr_ReceiveFlyers = @"FlyerMgr_ReceiveFlyers";

@class Flyer;
@class TradePost;
@class WorldState;
@class MapControl;

@interface FlyerMgr : NSObject<HttpCallbackDelegate,WheelDataSource,WheelProtocol>
{
    NSMutableArray* _playerFlyers;
    NSDate* _lastUpdate;
    MapControl* _previewMap;
    
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<HttpCallbackDelegate>* _delegate;
}
@property (nonatomic,strong) NSMutableArray* playerFlyers;
@property (nonatomic,strong) MapControl* previewMap;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegate;

- (BOOL) needsRefresh;
- (BOOL) newPlayerFlyerAtTradePost:(TradePost*)tradePost
                        firstFlyer:(NSInteger)flyerTypeIndex;
- (void) retrieveUserFlyersFromServer;
- (void) updateFlyersAtDate:(NSDate*)currentTime;
- (void) initFlyersOnMap;

- (void) refreshFromWorldState:(WorldState*)worldState;

// queries
- (NSArray*) tradePostIdsWithFlyers;

// singleton
+(FlyerMgr*) getInstance;
+(void) destroyInstance;


@end
