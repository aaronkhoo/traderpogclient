//
//  GameEvent.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/28/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

enum _GameEventTypes
{
    kGameEvent_FlyerArrival = 0,
    kGameEvent_LoadingCompleted,
    
    kGameEventTypesNum
};

@interface GameEvent : NSObject
{
    unsigned int _eventType;
    NSString* _desc;
    CLLocationCoordinate2D _coord;
}
@property (nonatomic) unsigned int eventType;
@property (nonatomic,strong) NSString* desc;
@property (nonatomic) CLLocationCoordinate2D coord;
- (id) initWithEventType:(unsigned int)type desc:(NSString*)desc coord:(CLLocationCoordinate2D)coord;
@end
