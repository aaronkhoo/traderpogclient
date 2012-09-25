//
//  Leaderboard.m
//  traderpog
//
//  Created by Aaron Khoo on 9/18/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "Leaderboard.h"

static NSString* const kKeyVersion = @"version";
static NSString* const kKeyRows = @"rows";
static NSString* const kKeyName = @"name";
static NSString* const kKeyWeekOf = @"weekof";

@interface Leaderboard ()
{
    // internal
    NSString* _createdVersion;
}
@end

@implementation Leaderboard
@synthesize lbRows = _lbRows;
@synthesize lbName = _lbName;
@synthesize week_of = _week_of;

#pragma mark - Public functions
- (id) initBoard:(NSString*)name
{
    self = [super init];
    if(self)
    {
        _lbRows = [[NSMutableArray alloc] initWithCapacity:20];
        _lbName = name;
        _week_of = nil;
    }
    return self;
}

- (void) insertNewRow:(LeaderboardRow*)current_row
{
    [_lbRows addObject:current_row];
}

- (void) clearLeaderboard
{
    [_lbRows removeAllObjects];
    _week_of = nil;
}

- (void) sortLeaderboard
{
    [_lbRows sortUsingComparator:^(id firstObject, id secondObject) {
        LeaderboardRow* firstRow = (LeaderboardRow*)firstObject;
        LeaderboardRow* secondRow = (LeaderboardRow*)secondObject;
        if (firstRow.lbValue < secondRow.lbValue)
            return NSOrderedAscending;
        else if (firstRow.lbValue == secondRow.lbValue)
            return NSOrderedSame;
        else
            return NSOrderedDescending;
    }];
}

- (BOOL) weekofValid
{
    return (_week_of != nil);
}

- (void) createWeekOfUsingString:(NSString*) datefromserver
{
    // Set up conversion of RFC 3339 time format
    NSDateFormatter *rfc3339DateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    
    [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
    [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'"];
    [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    // Convert the RFC 3339 date time string to an NSDate.
    _week_of = [rfc3339DateFormatter dateFromString:datefromserver];
}

#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_createdVersion forKey:kKeyVersion];
    [aCoder encodeObject:_lbRows forKey:kKeyRows];
    [aCoder encodeObject:_lbName forKey:kKeyName];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _createdVersion = [aDecoder decodeObjectForKey:kKeyVersion];
    _lbRows = [aDecoder decodeObjectForKey:kKeyRows];
    _lbName = [aDecoder decodeObjectForKey:kKeyName];
    return self;
}

@end
