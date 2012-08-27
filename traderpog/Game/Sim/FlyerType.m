//
//  FlyerType.m
//  traderpog
//
//  Created by Aaron Khoo on 7/25/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerType.h"

// encoding keys
static NSString* const kKeyVersion = @"version";
static NSString* const kKeyFlyerId = @"id";
static NSString* const kKeyName = @"localized_name";
static NSString* const kKeyDesc = @"localized_desc";
static NSString* const kKeyPrice = @"price";
static NSString* const kKeyCapacity = @"capacity";
static NSString* const kKeySpeed = @"speed";
static NSString* const kKeyMultiplier = @"multiplier";
static NSString* const kKeyStormResist = @"stormresist";
static NSString* const kKeyTier = @"tier";

@implementation FlyerType
@synthesize flyerId = _flyerId;
@synthesize name = _name;
@synthesize desc = _desc;
@synthesize tier = _tier;
@synthesize speed = _speed;

- (id) initWithDictionary:(NSDictionary*)dict
{
    self = [super init];
    if(self)
    {
        _flyerId = [NSString stringWithFormat:@"%d", [[dict valueForKeyPath:@"id"] integerValue]];
        _name = [dict valueForKeyPath:@"localized_name"];
        _desc = [dict valueForKeyPath:@"localized_desc"];
        _price =[[dict valueForKeyPath:@"price"] integerValue];
        _capacity =[[dict valueForKeyPath:@"capacity"] integerValue];
        _speed =[[dict valueForKeyPath:@"speed"] integerValue];
        _multiplier =[[dict valueForKeyPath:@"multiplier"] integerValue];
        _stormresist =[[dict valueForKeyPath:@"stormresist"] integerValue];
        _tier = [[dict valueForKeyPath:@"tier"] integerValue];
    }
    return self;
}

#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_createdVersion forKey:kKeyVersion];
    [aCoder encodeObject:_flyerId forKey:kKeyFlyerId];
    [aCoder encodeObject:_name forKey:kKeyName];
    [aCoder encodeObject:_desc forKey:kKeyDesc];
    [aCoder encodeObject:[NSNumber numberWithInteger:_price] forKey:kKeyPrice];
    [aCoder encodeObject:[NSNumber numberWithInteger:_capacity] forKey:kKeyCapacity];
    [aCoder encodeObject:[NSNumber numberWithInteger:_speed] forKey:kKeySpeed];
    [aCoder encodeObject:[NSNumber numberWithInteger:_multiplier] forKey:kKeyMultiplier];
    [aCoder encodeObject:[NSNumber numberWithInteger:_stormresist] forKey:kKeyStormResist];
    [aCoder encodeObject:[NSNumber numberWithInteger:_tier] forKey:kKeyTier];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _createdVersion = [aDecoder decodeObjectForKey:kKeyVersion];
    _flyerId = [aDecoder decodeObjectForKey:kKeyFlyerId];
    _name = [aDecoder decodeObjectForKey:kKeyName];
    _desc = [aDecoder decodeObjectForKey:kKeyDesc];
    _price = [[aDecoder decodeObjectForKey:kKeyPrice] integerValue];
    _capacity = [[aDecoder decodeObjectForKey:kKeyCapacity] integerValue];
    _speed = [[aDecoder decodeObjectForKey:kKeySpeed] integerValue];
    _multiplier = [[aDecoder decodeObjectForKey:kKeyMultiplier] integerValue];
    _stormresist = [[aDecoder decodeObjectForKey:kKeyStormResist] integerValue];
    _tier = [[aDecoder decodeObjectForKey:kKeyTier] integerValue];
    return self;
}

@end
