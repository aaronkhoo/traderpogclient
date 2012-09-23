//
//  GameAnim.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/22/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "GameAnim.h"

@implementation GameAnim
- (id) init
{
    self = [super init];
    if(self)
    {
        
    }
    return self;
}



#pragma mark - Singleton
static GameAnim* singleton = nil;
+ (GameAnim*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
            if (!singleton)
            {
                singleton = [[GameAnim alloc] init];
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
