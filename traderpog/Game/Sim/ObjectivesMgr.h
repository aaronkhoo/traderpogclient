//
//  ObjectivesMgr.h
//  traderpog
//
//  player objectives manager
//  this is primarily used to guide new players through the experience
//
//  Created by Shu Chiun Cheah on 10/21/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameObjective.h"

@interface ObjectivesMgr : NSObject<NSCoding>
{
    NSMutableArray* _objectives;
}

- (void) saveObjectivesData;
- (void) removeObjectivesData;

- (GameObjective*) getNextObjective;
- (void) setCompletedForObjective:(GameObjective*)objective;

// singleton
+(ObjectivesMgr*) getInstance;
+(void) destroyInstance;

@end
