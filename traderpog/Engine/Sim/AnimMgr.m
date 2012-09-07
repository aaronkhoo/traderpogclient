//
//  AnimMgr.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AnimMgr.h"

@implementation AnimMgr

- (id) init
{
    self = [super init];
    if(self)
    {
        _animObjects = [NSMutableArray arrayWithCapacity:10];
    }
    return self;
}

- (void) addAnimObject:(NSObject<AnimDelegate>*)animObject
{
    [_animObjects addObject:animObject];
}

- (void) removeAnimObject:(NSObject<AnimDelegate>*)animObject
{
    [_animObjects removeObject:animObject];
}

- (void) update:(NSTimeInterval)elapsed
{
    for(NSObject<AnimDelegate>* cur in _animObjects)
    {
        [cur animUpdate:elapsed];
    }
}


#pragma mark - Singleton
static AnimMgr* singleton = nil;
+ (AnimMgr*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
			singleton = [[AnimMgr alloc] init];
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
