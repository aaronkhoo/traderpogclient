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
NSString* const kKeyGameObjCompleted = @"completed";

NSString* const kNameGameObjTypeBasic = @"basic";
NSString* const kNameGameObjTypeScan = @"scan";

@interface GameObjective ()
- (void) setInitVars;
- (unsigned int) typeFromName:(NSString*)name;
@end

@implementation GameObjective
@synthesize desc = _desc;
@synthesize type = _type;
@synthesize flags = _flags;
@synthesize screenPoint = _screenPoint;
@synthesize mapPoint = _mapPoint;
@synthesize isCompleted = _isCompleted;

- (void) setInitVars
{
    _desc = @"";
    _type = kGameObjectiveType_Basic;
    _flags = kGameObjectiveFlag_None;
    _screenPoint = CGPointMake(0.5f, 0.8f);
    _mapPoint = MKMapPointForCoordinate([[CLLocation penang] coordinate]);
    _isCompleted = NO;
}

- (unsigned int) typeFromName:(NSString*)name
{
    NSString* lut[kGameObjectiveType_Num] =
    {
        kNameGameObjTypeBasic,
        kNameGameObjTypeScan
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
        _desc = [dict objectForKey:kKeyGameObjDesc];
        NSString* typeName = [dict objectForKey:kKeyGameObjType];
        _type = [self typeFromName:typeName];
    }
    return self;
}

- (void) setCompleted
{
    _isCompleted = YES;
}

#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_desc forKey:kKeyGameObjDesc];
    [aCoder encodeInteger:_type forKey:kKeyGameObjType];
    [aCoder encodeBool:_isCompleted forKey:kKeyGameObjCompleted];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _desc = [aDecoder decodeObjectForKey:kKeyGameObjDesc];
    _type = [aDecoder decodeIntegerForKey:kKeyGameObjType];
    _isCompleted = [aDecoder decodeBoolForKey:kKeyGameObjCompleted];
    return self;
}


@end
