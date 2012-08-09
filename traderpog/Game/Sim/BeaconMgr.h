//
//  BeaconMgr.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BeaconMgr : NSObject
{
    NSMutableDictionary* _activeBeacons;
}
@property (nonatomic,readonly) NSMutableDictionary* activeBeacons;

- (void) createPlaceholderBeacons;


// singleton
+(BeaconMgr*) getInstance;
+(void) destroyInstance;

@end
