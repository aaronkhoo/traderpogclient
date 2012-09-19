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
@synthesize weekOf = _weekOf;

#pragma mark - Public functions
- (id) initBoard:(NSString*)name, NSDate* current_date
{
    self = [super init];
    if(self)
    {
        _lbRows = [[NSMutableArray alloc] initWithCapacity:20];
        _lbName = name;
        _weekOf = current_date;
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

#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_createdVersion forKey:kKeyVersion];
    [aCoder encodeObject:_lbRows forKey:kKeyRows];
    [aCoder encodeObject:_lbName forKey:kKeyName];
    [aCoder encodeObject:_weekOf forKey:kKeyWeekOf];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _createdVersion = [aDecoder decodeObjectForKey:kKeyVersion];
    _lbRows = [aDecoder decodeObjectForKey:kKeyRows];
    _lbName = [aDecoder decodeObjectForKey:kKeyName];
    _weekOf = [aDecoder decodeObjectForKey:kKeyWeekOf];
    return self;
}

@end
