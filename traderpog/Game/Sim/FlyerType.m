//
//  FlyerType.m
//  traderpog
//
//  Created by Aaron Khoo on 7/25/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerType.h"

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

@end
