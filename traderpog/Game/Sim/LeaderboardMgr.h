//
//  LeaderboardMgr.h
//  traderpog
//
//  Created by Aaron Khoo on 9/19/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpCallbackDelegate.h"

typedef enum
{
    kLBBucks = 0,
    kLBTotalDistance,
    kLBFurthestDistance,
    kLBPostsVisited,
    
    kLBNum
} leaderboardType;

static NSString* const kKeyLastUpdated = @"lastUpdated";
static NSString* const kLeaderboardMgr_ReceiveLeaderboards = @"LeaderboardMgr_ReceiveLeaderboards";

@interface LeaderboardMgr : NSObject<NSCoding>
{
    NSMutableArray* _leaderboards;
    NSDate* _lastUpdate;
    
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<HttpCallbackDelegate>* _delegate;
}
@property (nonatomic,strong) NSMutableArray* leaderboards;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegate;

- (void) saveLeaderboardMgrData;
- (void) removeLeaderboardMgrData;

- (BOOL) needsRefresh;
- (void) retrieveLeaderboardFromServer;

// singleton
+(LeaderboardMgr*) getInstance;
+(void) destroyInstance;

@end
