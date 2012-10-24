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
@class MapControl;
@interface FlyerMgr : NSObject<NSCoding,HttpCallbackDelegate,WheelDataSource,WheelProtocol>
{
    NSMutableArray* _playerFlyers;
    NSDate* _lastUpdate;
    MapControl* _previewMap;
    
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<HttpCallbackDelegate>* _delegate;
}
@property (nonatomic,strong) NSMutableArray* playerFlyers;
@property (nonatomic,readonly) NSDate* lastUpdate;
@property (nonatomic,strong) MapControl* previewMap;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegate;

- (void) clearAllFlyers;
- (void) resetRefresh;
- (BOOL) needsRefresh;
- (BOOL) newPlayerFlyerAtTradePost:(TradePost*)tradePost
                        firstFlyer:(NSInteger)flyerTypeIndex;
- (BOOL) newPlayerFlyerAtTradePost:(TradePost *)tradePost
           purchasedFlyerTypeIndex:(NSInteger)flyerTypeIndex;
- (void) retrieveUserFlyersFromServer;
- (void) updateFlyersAtDate:(NSDate*)currentTime;
- (void) initFlyersOnMap;
- (void) saveFlyerMgrData;
- (void) removeFlyerMgrData;
- (void) clearForQuitGame;

// queries
- (Flyer*) flyerAtPostId:(NSString*)postId;
- (NSArray*) tradePostIdsWithFlyers;
- (NSMutableArray*) unknownTradePostsFromFlyers;
- (NSArray*) tradePostIdsInFlightpaths;
- (Flyer*) homeOrHomeboundFlyer;
- (NSArray*) getPurchaseableFlyerTypeIndices;

// singleton
+(FlyerMgr*) getInstance;
+(void) destroyInstance;


@end
