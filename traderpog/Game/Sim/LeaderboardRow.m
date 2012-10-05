//
//  LeaderboardRow.m
//  traderpog
//
//  Created by Aaron Khoo on 9/19/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "LeaderboardRow.h"

static NSString* const kKeyVersion = @"version";
static NSString* const kKeyFbname = @"fb_name";
static NSString* const kKeyMember = @"member";
static NSString* const kKeyValue = @"value";

@interface LeaderboardRow ()
{
    // internal
    NSString* _createdVersion;
}
@end

@implementation LeaderboardRow
@synthesize fbname = _fbname;
@synthesize fbid = _fbid;
@synthesize member = _member;
@synthesize lbValue = _lbValue;

- (id) initWithData:(NSString*)current_fbname
       current_fbid:(NSString*)current_fbid
      current_value:(NSInteger)current_value
     current_member:(BOOL)current_member
{
    self = [super init];
    if(self)
    {
        _fbname = current_fbname;
        _fbid = current_fbid;
        _lbValue = current_value;
        _member = current_member;
    }
    return self;
}

#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_createdVersion forKey:kKeyVersion];
    [aCoder encodeObject:_fbname forKey:kKeyFbname];
    [aCoder encodeInteger:_lbValue forKey:kKeyValue];
    [aCoder encodeBool:_member forKey:kKeyMember];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _createdVersion = [aDecoder decodeObjectForKey:kKeyVersion];
    _fbname = [aDecoder decodeObjectForKey:kKeyFbname];
    _lbValue = [aDecoder decodeIntegerForKey:kKeyValue];
    _member = [aDecoder decodeBoolForKey:kKeyMember];
    return self;
}

@end
