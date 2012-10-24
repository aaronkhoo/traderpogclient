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
static NSString* const kKeyTopimg = @"topimg";
static NSString* const kKeySideimg = @"sideimg";
static NSString* const kKeyLoadTime = @"load_time";

// default values
static const float kFlyerDefaultLoadTime = 90.0f;   // seconds

@implementation FlyerType
@synthesize flyerId = _flyerId;
@synthesize name = _name;
@synthesize desc = _desc;
@synthesize price = _price;
@synthesize capacity = _capacity;
@synthesize tier = _tier;
@synthesize speed = _speed;
@synthesize topimg = _topimg;
@synthesize sideimg = _sideimg;
@synthesize loadtime = _loadtime;

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
        _topimg = [dict valueForKeyPath:kKeyTopimg];
        _sideimg = [dict valueForKeyPath:kKeySideimg];
        _loadtime = [[dict valueForKeyPath:kKeyLoadTime] integerValue];
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
    [aCoder encodeObject:[NSNumber numberWithInteger:_loadtime] forKey:kKeyLoadTime];
    [aCoder encodeObject:[NSNumber numberWithInteger:_speed] forKey:kKeySpeed];
    [aCoder encodeObject:[NSNumber numberWithInteger:_multiplier] forKey:kKeyMultiplier];
    [aCoder encodeObject:[NSNumber numberWithInteger:_stormresist] forKey:kKeyStormResist];
    [aCoder encodeObject:[NSNumber numberWithInteger:_tier] forKey:kKeyTier];
    [aCoder encodeObject:_topimg forKey:kKeyTopimg];
    [aCoder encodeObject:_sideimg forKey:kKeySideimg];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _createdVersion = [aDecoder decodeObjectForKey:kKeyVersion];
    _flyerId = [aDecoder decodeObjectForKey:kKeyFlyerId];
    _name = [aDecoder decodeObjectForKey:kKeyName];
    _desc = [aDecoder decodeObjectForKey:kKeyDesc];
    _price = [[aDecoder decodeObjectForKey:kKeyPrice] integerValue];
    _capacity = [[aDecoder decodeObjectForKey:kKeyCapacity] integerValue];
    NSNumber* loadTimeNum = [aDecoder decodeObjectForKey:kKeyLoadTime];
    if(loadTimeNum)
    {
        _loadtime = [loadTimeNum integerValue];
    }
    else
    {
        _loadtime = kFlyerDefaultLoadTime;
    }
    _speed = [[aDecoder decodeObjectForKey:kKeySpeed] integerValue];
    _multiplier = [[aDecoder decodeObjectForKey:kKeyMultiplier] integerValue];
    _stormresist = [[aDecoder decodeObjectForKey:kKeyStormResist] integerValue];
    _tier = [[aDecoder decodeObjectForKey:kKeyTier] integerValue];
    _topimg = [aDecoder decodeObjectForKey:kKeyTopimg];
    _sideimg = [aDecoder decodeObjectForKey:kKeySideimg];

    return self;
}

// flyerlab uses more readable names than the numeric flyerId
// for easier maintenance of the flyerlab.plist file
enum kFlyerIdNumeric
{
    kFlyerId_Numeric_basic = 1,
    kFlyerId_Numeric_wing,
    kFlyerId_Numeric_rang,
    kFlyerId_Numeric_frog,
    kFlyerId_Numeric_hornet,
    kFlyerId_Numeric_blimp,
    
    kFlyerId_Numeric_Num
};
- (NSString*) getNameForFlyerLab
{
    NSString* result = @"flyer_glider";
    NSString* names[kFlyerId_Numeric_Num] =
    {
        @"flyer_glider",
        @"flyer_glider",
        @"flyer_wing",
        @"flyer_rang",
        @"flyer_frog",
        @"flyer_hornet",
        @"flyer_blimp"
    };
    
    int flyerIdNum = [_flyerId intValue];
    if((0 > flyerIdNum) || (kFlyerId_Numeric_Num <= flyerIdNum))
    {
        flyerIdNum = 0;
    }
    result = names[flyerIdNum];
    return result;
}

@end
