//
//  FlyerLabFactory.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerLabFactory.h"

@implementation FlyerLabFactory

#pragma mark - Singleton
static FlyerLabFactory* singleton = nil;
+ (FlyerLabFactory*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
            if (!singleton)
            {
                singleton = [[FlyerLabFactory alloc] init];
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
