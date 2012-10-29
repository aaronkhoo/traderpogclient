//
//  GameObjective.h
//  traderpog
//
//  This is currently primarily used in new user guidethrough
//
//  Created by Shu Chiun Cheah on 10/21/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const kKeyGameObjDesc;
extern NSString* const kKeyGameObjType;
extern NSString* const kKeyGameObjImage;
extern NSString* const kKeyGameObjId;
extern NSString* const kKeyGameObjCompleted;
extern NSString* const kKeyGameObjPointX;
extern NSString* const kKeyGameObjPointY;
extern NSString* const kKeyGameObjDelay;
extern NSString* const kKeyGameObjIsNewUser;
extern NSString* const kKeyGameObjIsRecurring;

enum kGameObjectiveTypes {
    kGameObjectiveType_Basic = 0,
    kGameObjectiveType_Scan,
    kGameObjectiveType_KnobLeft,
    kGameObjectiveType_KnobRight,
    kGameObjectiveType_FbTipBeacon,
    
    kGameObjectiveType_Num
};

@interface GameObjective : NSObject<NSCoding>
{
    NSString*   _objectiveId;
    NSUInteger   _type;
    BOOL        _isCompleted;
}
@property (nonatomic,readonly) NSString* objectiveId;
@property (nonatomic) NSUInteger type;
@property (nonatomic,readonly) BOOL isCompleted;

- (id) initWithDictionary:(NSDictionary*)dict;

// do NOT call this directly!
// call [ObjectiveMgr setCompletedForObjective:] instead
- (void) setCompleted;
- (void) unsetCompleted;
@end
