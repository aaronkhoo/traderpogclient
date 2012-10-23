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
    NSString*  _fileversion;
    
    // current outstanding objective
    GameObjective* _outObjective;
}
@property (nonatomic,strong) GameObjective* outObjective;
@property (nonatomic,readonly) NSString* fileversion;

- (void) saveObjectivesData;
- (void) removeObjectivesData;

// objective operations
- (GameObjective*) getNextObjective;
- (void) setCompletedForObjective:(GameObjective*)objective;
- (NSString* const) descForObjective:(GameObjective*)objective;
- (NSString* const) imageNameForObjective:(GameObjective*)objective;
- (CGPoint) pointForObjective:(GameObjective*)objective;

// the game calls these to inform the manager of events user has performed
- (void) playerDidPerformScan;

// singleton
+(ObjectivesMgr*) getInstance;
+(void) destroyInstance;

@end
