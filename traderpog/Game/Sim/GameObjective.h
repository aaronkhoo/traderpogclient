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

enum kGameObjectiveFlag {
    kGameObjectiveFlag_None = 0,
    kGameObjectiveFlag_ScreenPoint = (1 << 0),
    kGameObjectiveFlag_MapPoint = (1 << 1)
    };

enum kGameObjectiveTypes {
    kGameObjectiveType_Close = 0,
    kGameObjectiveType_Scan,
    
    kGameObjectiveType_Num
};

@interface GameObjective : NSObject<NSCoding>
{
    NSString*   _desc;
    NSUInteger   _type;
    unsigned int _flags;
    CGPoint     _screenPoint;
    MKMapPoint  _mapPoint;
    BOOL        _isCompleted;
}
@property (nonatomic,strong) NSString* desc;
@property (nonatomic) NSUInteger type;
@property (nonatomic) unsigned int flags;
@property (nonatomic) CGPoint screenPoint;
@property (nonatomic) MKMapPoint mapPoint;
@property (nonatomic,readonly) BOOL isCompleted;

- (id) initWithDictionary:(NSDictionary*)dict;
- (void) setCompleted;
@end
