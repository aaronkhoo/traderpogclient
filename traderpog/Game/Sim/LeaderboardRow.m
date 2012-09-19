//
//  LeaderboardRow.m
//  traderpog
//
//  Created by Aaron Khoo on 9/19/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "LeaderboardRow.h"

static NSString* const kKeyVersion = @"version";
static NSString* const kKeyFbid = @"fbid";
static NSString* const kKeyValue = @"value";

@interface LeaderboardRow ()
{
    // internal
    NSString* _createdVersion;
}
@end

@implementation LeaderboardRow
@synthesize fbid = _fbid;
@synthesize lbValue = _lbValue;

- (id) initWithFbidAndValue:(NSString*)current_fbid current_value:(NSInteger)current_value
{
    self = [super init];
    if(self)
    {
        _fbid = current_fbid;
        _lbValue = current_value;
    }
    return self;
}

#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_createdVersion forKey:kKeyVersion];
    [aCoder encodeObject:_fbid forKey:kKeyFbid];
    [aCoder encodeInteger:_lbValue forKey:kKeyValue];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _createdVersion = [aDecoder decodeObjectForKey:kKeyVersion];
    _fbid = [aDecoder decodeObjectForKey:kKeyFbid];
    _lbValue = [aDecoder decodeIntegerForKey:kKeyValue];
    return self;
}

@end
