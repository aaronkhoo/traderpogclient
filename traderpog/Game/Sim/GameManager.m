//
//  GameManager.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "GameManager.h"

@implementation GameManager
@synthesize isUserRegistered = _isUserRegistered;

- (id) init
{
    self = [super init];
    if(self)
    {
        _isUserRegistered = NO;
    }
    return self;
}

#pragma mark - Singleton
static GameManager* singleton = nil;
+ (GameManager*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
			singleton = [[GameManager alloc] init];
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
