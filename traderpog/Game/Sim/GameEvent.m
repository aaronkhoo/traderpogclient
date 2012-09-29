//
//  GameEvent.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/28/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "GameEvent.h"

@implementation GameEvent
@synthesize eventType = _eventType;
@synthesize desc = _desc;
@synthesize coord = _coord;
- (id) init
{
    NSAssert(false, @"must use initWithIconName:iconName:desc:coord to create GameEvent");
    return nil;
}

- (id) initWithEventType:(unsigned int)type desc:(NSString *)desc coord:(CLLocationCoordinate2D)coord
{
    self = [super init];
    if(self)
    {
        _eventType = type;
        _desc = desc;
        _coord = coord;
    }
    return self;
}



@end
