//
//  BeaconMgr.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "BeaconMgr.h"
#import "Beacon.h"


@implementation BeaconMgr
@synthesize activeBeacons = _activeBeacons;

- (id) init
{
    self = [super init];
    if(self)
    {
        _activeBeacons = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    return self;
}

// HACK
// remove when retrieveFromServer is implemented
- (void) createPlaceholderBeacons
{
    Beacon* beacon1 = [[Beacon alloc] initWithBeaconId:@"PlaceholderBeacon1"
                                                postId:@"PlaceholderFriendPost1"];
    Beacon* beacon2 = [[Beacon alloc] initWithBeaconId:@"PlaceholderBeacon2"
                                                postId:@"PlaceholderFriendPost2"];
    [_activeBeacons setObject:beacon1 forKey:@"PlaceholderBeacon1"];
    [_activeBeacons setObject:beacon2 forKey:@"PlaceholderBeacon2"];
}

// HACK


#pragma mark - Singleton
static BeaconMgr* singleton = nil;
+ (BeaconMgr*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
            if (!singleton)
            {
                singleton = [[BeaconMgr alloc] init];
            }
		}
	}
	return singleton;
}

+ (void) destroyInstance
{
	@synchronized(self)
	{
		singleton = nil;
	}
}

@end
