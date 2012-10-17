//
//  GameEventMgr.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/28/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "GameEventMgr.h"
#import "GameEvent.h"
#import "SoundManager.h"

@implementation GameEventMgr

- (id) init
{
    self = [super init];
    if(self)
    {
        _eventQueue = [NSMutableArray arrayWithCapacity:10];
    }
    return self;
}

- (GameEvent*) queueEventWithType:(unsigned int)gameEventType atCoord:(CLLocationCoordinate2D)coord
{
    GameEvent* newEvent = [[GameEvent alloc] initWithEventType:gameEventType desc:nil coord:coord];
    [_eventQueue addObject:newEvent];
    return newEvent;
}

- (GameEvent*) dequeueEvent
{
    GameEvent* result = nil;
    
    if([_eventQueue count])
    {
        result = [_eventQueue objectAtIndex:0];
        [_eventQueue removeObjectAtIndex:0];
        
        // An event to notify the user. Play the appropriate sound
        [[SoundManager getInstance] playClip:@"Pog_SFX_LoadingReady"];
    }
    
    return result;
}

#pragma mark - Singleton
static GameEventMgr* singleton = nil;
+ (GameEventMgr*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
            if (!singleton)
            {
                singleton = [[GameEventMgr alloc] init];
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
