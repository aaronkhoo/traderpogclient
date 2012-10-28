//
//  GameObjective.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/21/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "GameObjective.h"
#import "CLLocation+Pog.h"

NSString* const kKeyGameObjDesc = @"desc";
NSString* const kKeyGameObjType = @"type";
NSString* const kKeyGameObjImage = @"image";
NSString* const kKeyGameObjId = @"id";
NSString* const kKeyGameObjCompleted = @"completed";
NSString* const kKeyGameObjPointX = @"pointX";
NSString* const kKeyGameObjPointY = @"pointY";
NSString* const kKeyGameObjDelay = @"delay";
NSString* const kKeyGameObjIsNewUser = @"is_newuser";
NSString* const kKeyGameObjIsRecurring = @"is_recurring";

NSString* const kNameGameObjTypeBasic = @"basic";
NSString* const kNameGameObjTypeScan = @"scan";
NSString* const kNameGameObjTypeKnobLeft = @"knob_left";
NSString* const kNameGameObjTypeKnobRight = @"knob_right";
NSString* const kNameGameObjTypeFbTip = @"tip_fb";

@interface GameObjective ()
- (void) setInitVars;
- (unsigned int) typeFromName:(NSString*)name;
@end

@implementation GameObjective
@synthesize objectiveId = _objectiveId;
@synthesize type = _type;
@synthesize isCompleted = _isCompleted;

- (void) setInitVars
{
    _objectiveId = @"uninit";
    _type = kGameObjectiveType_Basic;
    _isCompleted = NO;
}

- (unsigned int) typeFromName:(NSString*)name
{
    NSString* lut[kGameObjectiveType_Num] =
    {
        kNameGameObjTypeBasic,
        kNameGameObjTypeScan,
        kNameGameObjTypeKnobLeft,
        kNameGameObjTypeKnobRight,
        kNameGameObjTypeFbTip
    };
    unsigned int type = kGameObjectiveType_Basic;
    for(unsigned int i = 0; i < kGameObjectiveType_Num; ++i)
    {
        if([name isEqualToString:lut[i]])
        {
            type = i;
            break;
        }
    }
    return type;
}


- (id) init
{
    self = [super init];
    if(self)
    {
        [self setInitVars];
    }
    return self;
}

- (id) initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if(self)
    {
        [self setInitVars];
        _objectiveId = [dict objectForKey:kKeyGameObjId];
        NSString* typeName = [dict objectForKey:kKeyGameObjType];
        _type = [self typeFromName:typeName];
    }
    return self;
}

- (void) setCompleted
{
    _isCompleted = YES;
}

- (void) unsetCompleted
{
    _isCompleted = NO;
}

#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_objectiveId forKey:kKeyGameObjId];
    [aCoder encodeInteger:_type forKey:kKeyGameObjType];
    [aCoder encodeBool:_isCompleted forKey:kKeyGameObjCompleted];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _objectiveId = [aDecoder decodeObjectForKey:kKeyGameObjId];
    _type = [aDecoder decodeIntegerForKey:kKeyGameObjType];
    _isCompleted = [aDecoder decodeBoolForKey:kKeyGameObjCompleted];
    return self;
}


@end
