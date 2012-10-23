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
#import <MapKit/MapKit.h>

extern NSString* const kKeyGameObjDesc;
extern NSString* const kKeyGameObjType;
extern NSString* const kKeyGameObjImage;
extern NSString* const kKeyGameObjId;
extern NSString* const kKeyGameObjCompleted;
extern NSString* const kKeyGameObjPointX;
extern NSString* const kKeyGameObjPointY;

enum kGameObjectiveFlag {
    kGameObjectiveFlag_None = 0,
    kGameObjectiveFlag_ScreenPoint = (1 << 0),
    kGameObjectiveFlag_MapPoint = (1 << 1)
    };

enum kGameObjectiveTypes {
    kGameObjectiveType_Basic = 0,
    kGameObjectiveType_Scan,
    
    kGameObjectiveType_Num
};

@interface GameObjective : NSObject<NSCoding>
{
    NSString*   _objectiveId;
    NSUInteger   _type;
    unsigned int _flags;
    CGPoint     _screenPoint;
    MKMapPoint  _mapPoint;
    BOOL        _isCompleted;
}
@property (nonatomic,readonly) NSString* objectiveId;
@property (nonatomic) NSUInteger type;
@property (nonatomic) unsigned int flags;
@property (nonatomic) CGPoint screenPoint;
@property (nonatomic) MKMapPoint mapPoint;
@property (nonatomic,readonly) BOOL isCompleted;

- (id) initWithDictionary:(NSDictionary*)dict;

// do NOT call this directly!
// call [ObjectiveMgr setCompletedForObjective:] instead
- (void) setCompleted;
@end
