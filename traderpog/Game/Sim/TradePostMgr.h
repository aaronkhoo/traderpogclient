//
//  TradePostMgr.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "HttpCallbackDelegate.h"
#import "MapControl.h"
#import "MyTradePost.h"
#import "NPCTradePost.h"
#import "WheelProtocol.h"
#import "HiAccuracyLocatorDelegate.h"

static NSString* const kTradePostMgr_ReceiveSinglePost = @"TradePostMgr_ReceiveSinglePost";
static NSString* const kTradePostMgr_ReceivePosts = @"TradePostMgr_ReceivePosts";
static NSString* const kTradePostMgr_ScanForPosts = @"TradePostMgr_ScanForPosts";

@class TradePost;
@class TradeItemType;
@interface TradePostMgr : NSObject<HttpCallbackDelegate,WheelDataSource,WheelProtocol,HiAccuracyLocatorDelegate>
{
    NSDate* _lastUpdate;
    MapControl* _previewMap;
    
    // Delegate for callbacks to inform interested parties of Post retrieval completion
    __weak NSObject<HttpCallbackDelegate>* _delegate;
    
    // Delegate for callbacks to inform interested parties of Scan retrieval completion
    __weak NSObject<HttpCallbackDelegate>* _delegateScan;
    
    // Delegate for callbacks to inform interested parties of dangling posts retrieval completion
    __weak NSObject<HttpCallbackDelegate>* _delegateDanglingPosts;
}
@property (nonatomic,strong) MapControl* previewMap;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegate;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegateScan;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegateDanglingPosts;

// Public methods
- (BOOL) needsRefresh;
- (void) retrievePostsFromServer;
- (NSInteger) postsCount;
- (BOOL) isBeaconActive;
- (void) annotatePostsOnMap:(MapControl*)map;
- (NPCTradePost*) newNPCTradePostAtCoord:(CLLocationCoordinate2D)coord
                                   bucks:(unsigned int)bucks;
- (BOOL) newTradePostAtCoord:(CLLocationCoordinate2D)coord 
                              sellingItem:(TradeItemType*)itemType;
- (TradePost*) getTradePostWithId:(NSString*)postId;
- (MyTradePost*) getFirstMyTradePost;
- (void) setTempPostToActive;
- (NSMutableArray*) getTradePostsAtCoord:(CLLocationCoordinate2D)coord 
                                  radius:(float)radius 
                                  maxNum:(unsigned int)maxNum;
- (void) scanForTradePosts:(CLLocationCoordinate2D)coord;
- (BOOL) isNPCPostId:(NSString*)postid;
- (BOOL) resolveDanglingPosts;
- (void) flushForeignPosts;
- (NSArray*) retireTradePostsWithExcludeSet:(NSSet *)excludeSet;

// singleton
+(TradePostMgr*) getInstance;
+(void) destroyInstance;


@end
