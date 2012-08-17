//
//  BeaconMgr.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapControl.h"
#import "WheelProtocol.h"

@interface BeaconMgr : NSObject<WheelDataSource,WheelProtocol>
{
    NSMutableDictionary* _activeBeacons;
}
@property (nonatomic,readonly) NSMutableDictionary* activeBeacons;

// init
- (void) createPlaceholderBeacons;
- (void) addBeaconAnnotationsToMap:(MapControl*)map;

// singleton
+(BeaconMgr*) getInstance;
+(void) destroyInstance;

@end
