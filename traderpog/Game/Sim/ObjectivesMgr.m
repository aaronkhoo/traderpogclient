//
//  ObjectivesMgr.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/21/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "ObjectivesMgr.h"

@implementation ObjectivesMgr

- (id) init
{
    self = [super init];
    if(self)
    {
        
    }
    return self;
}



#pragma mark - Singleton
static ObjectivesMgr* singleton = nil;
+ (ObjectivesMgr*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
			singleton = [[ObjectivesMgr alloc] init];
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
