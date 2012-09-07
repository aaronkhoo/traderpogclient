//
//  DownloadMgr.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "DownloadMgr.h"

@implementation DownloadMgr

- (id) init
{
    self = [super init];
    if(self)
    {
        
    }
    return self;
}


#pragma mark - Singleton
static DownloadMgr* singleton = nil;
+ (DownloadMgr*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
			singleton = [[DownloadMgr alloc] init];
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
