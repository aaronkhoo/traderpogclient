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
#import <CoreLocation/CoreLocation.h>
#import "GameObjective.h"

@interface ObjectivesMgr : NSObject<NSCoding>
{
    NSMutableArray* _objectives;
    NSString*  _fileversion;
    
    // current outstanding objective
    GameObjective* _outObjective;
}
@property (nonatomic,readonly) NSString* fileversion;

// objectives processing
@property (nonatomic,strong) GameObjective* outObjective;
@property (nonatomic,strong) NSDate* lastCompletionDate;
@property (nonatomic,readonly) NSUInteger scanCount;
@property (nonatomic,readonly) NSUInteger knobLeftCount;
@property (nonatomic,readonly) NSUInteger knobRightCount;
@property (nonatomic,readonly) NSUInteger homeNotVisibleCount;

- (void) saveObjectivesData;
- (void) removeObjectivesData;
- (void) clearForQuitGame;
- (void) setAllCompleted;

// objective operations
- (GameObjective*) getNextObjective;
- (void) setCompletedForObjective:(GameObjective*)objective hasView:(BOOL)hasView;
- (NSString* const) descForObjective:(GameObjective*)objective;
- (NSString* const) imageNameForObjective:(GameObjective*)objective;
- (CGPoint) pointForObjective:(GameObjective*)objective;
- (NSTimeInterval) delayForObjective:(GameObjective*)objective;
- (void) resetKnobCounts;

// the game calls these to inform the manager of events user has performed
- (void) playerDidPerformScan;
- (void) playerDidPerformKnobLeft;
- (void) playerDidPerformKnobRight;
- (void) playerDidChangeMapCenterTo:(CLLocationCoordinate2D)coord;

// singleton
+(ObjectivesMgr*) getInstance;
+(void) destroyInstance;

@end
