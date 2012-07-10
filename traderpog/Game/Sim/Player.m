//
//  Player.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "Player.h"

// encoding keys
static NSString* const kKeyVersion = @"version";
static NSString* const kKeyUserId = @"userid";

@implementation Player
- (id) initWithUserId:(NSString *)userId
{
    self = [super init];
    if(self)
    {
        _createdVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
        _userId = userId;
    }
    return self;
}

#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_createdVersion forKey:kKeyVersion];
    [aCoder encodeObject:_userId forKey:kKeyUserId];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _createdVersion = [aDecoder decodeObjectForKey:kKeyVersion];
    _userId = [aDecoder decodeObjectForKey:kKeyUserId];
    return self;
}

@end
