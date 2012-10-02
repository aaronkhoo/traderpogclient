//
//  BeaconMgr.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpCallbackDelegate.h"
#import "MapControl.h"
#import "WheelProtocol.h"

static NSString* const kBeaconMgr_ReceiveBeacons = @"kBeaconMgr_ReceiveBeacons";

@interface BeaconMgr : NSObject<WheelDataSource,WheelProtocol>
{
    NSMutableDictionary* _activeBeacons;
    MapControl* _previewMap;

    NSDate* _lastUpdate;
    
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<HttpCallbackDelegate>* _delegate;
}
@property (nonatomic,readonly) NSMutableDictionary* activeBeacons;
@property (nonatomic,strong) MapControl* previewMap;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegate;

// init
- (void) retrieveBeaconsFromServer;
- (void) addBeaconAnnotationsToMap:(MapControl*)map;
- (void) resetRefresh;
- (BOOL) needsRefresh;
- (BOOL) isPostABeacon:(NSString*)postId;

// singleton
+(BeaconMgr*) getInstance;
+(void) destroyInstance;

@end
