//
//  GameEventMgr.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/28/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "GameEvent.h"

@interface GameEventMgr : NSObject
{
    NSMutableArray* _eventQueue;
}

- (GameEvent*) queueEventWithType:(unsigned int)gameEventType atCoord:(CLLocationCoordinate2D)coord;
- (GameEvent*) dequeueEvent;

// singleton
+(GameEventMgr*) getInstance;
+(void) destroyInstance;

@end
