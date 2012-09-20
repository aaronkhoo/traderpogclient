//
//  LeaderboardMgr.m
//  traderpog
//
//  Created by Aaron Khoo on 9/19/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AFClientManager.h"
#import "GameManager.h"
#import "Leaderboard.h"
#import "LeaderboardMgr.h"
#import "LeaderboardRow.h"
#import "Player.h"

static const NSString *strings[kLBNum] = {
    @"BUCKS",
    @"TOTAL DISTANCE TRAVELLED",
    @"FURTHEST DISTANCE BETWEEN 2 POSTS",
    @"PLAYER POSTS VISITED"
};

// 4 hour refresh schedule
static double const refreshTime = -(60 * 60 * 4);

static NSString* const kLeaderboardMgrFilename = @"leaderboardmgr.sav";
static NSString* const kKeyVersion = @"version";
static NSString* const kKeyLeaderboards = @"leaderboards";
static NSString* const kKeyFbid = @"fbid";
static NSString* const kKeyType = @"lbtype";
static NSString* const kKeyValue = @"lbvalue";

@interface LeaderboardMgr ()
{
    // internal
    NSString* _createdVersion;
}
@end

@implementation LeaderboardMgr
@synthesize leaderboards = _leaderboards;
@synthesize delegate = _delegate;

#pragma mark - public functions

- (id) init
{
    self = [super init];
    if(self)
    {
        _lastUpdate = nil;
        _leaderboards = [[NSMutableArray alloc] initWithCapacity:kLBNum];
    }
    return self;
}

- (BOOL) needsRefresh
{
    return (!_lastUpdate) || ([_lastUpdate timeIntervalSinceNow] < refreshTime);
}

- (void) processSinglePlayerLeaderboardValues:(NSArray*)playerValues
{
    for (NSDictionary* lbRow in playerValues)
    {
        NSString* current_fbid = [NSString stringWithFormat:@"%@", [lbRow valueForKeyPath:kKeyFbid]];
        NSInteger current_value = [[lbRow valueForKey:kKeyValue] integerValue];
        NSUInteger current_type = [[lbRow valueForKey:kKeyType] integerValue];
        
        LeaderboardRow* new_row = [[LeaderboardRow alloc] initWithFbidAndValue:current_fbid current_value:current_value];
        Leaderboard* current_leaderboard = [_leaderboards objectAtIndex:current_type];
        [current_leaderboard insertNewRow:new_row];
    }
}

- (void) createLeaderboards:(id)responseObject
{
    // Clear existing leaderboards
    for (Leaderboard* current_lb in _leaderboards)
    {
        [current_lb clearLeaderboard];
    }
    
    // Insert new rows into leaderboards
    for (NSArray* playerValuesArray in responseObject)
    {
        [self processSinglePlayerLeaderboardValues:playerValuesArray];
    }
    
    // Sort leaderboards
    for (Leaderboard* current_lb in _leaderboards)
    {
        [current_lb sortLeaderboard];
    }
}

- (void) retrieveLeaderboardFromServer
{
    // make a get request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    NSString *leaderboardsPath = [NSString stringWithFormat:@"users/%d/user_leaderboards.json", [[Player getInstance] playerId]];
    [httpClient getPath:leaderboardsPath
             parameters:nil
                success:^(AFHTTPRequestOperation *operation, id responseObject){
                    NSLog(@"Retrieved: %@", responseObject);
                    [self createLeaderboards:responseObject];
                    _lastUpdate = [NSDate date];
                    [self saveLeaderboardMgrData];
                    [self.delegate didCompleteHttpCallback:kLeaderboardMgr_ReceiveLeaderboards, TRUE];
                }
                failure:^(AFHTTPRequestOperation* operation, NSError* error){
                    // No failures if the player can't retrieve leaderboards; just log it and move on
                    NSLog(@"Leaderboards retrieval failed: %@", error.localizedFailureReason);
                    [self.delegate didCompleteHttpCallback:kLeaderboardMgr_ReceiveLeaderboards, TRUE];
                }
     ];
}

#pragma mark - private functions

+ (NSString*) leaderboardmgrFilePath
{
    NSString* docsDir = [GameManager documentsDirectory];
    NSString* filepath = [docsDir stringByAppendingPathComponent:kLeaderboardMgrFilename];
    return filepath;
}

#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_createdVersion forKey:kKeyVersion];
    [aCoder encodeObject:_leaderboards forKey:kKeyLeaderboards];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _createdVersion = [aDecoder decodeObjectForKey:kKeyVersion];
    _leaderboards = [aDecoder decodeObjectForKey:kKeyLeaderboards];
    return self;
}

#pragma mark - saved game data loading and unloading
+ (LeaderboardMgr*) loadLeaderboardMgrData
{
    LeaderboardMgr* current = nil;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* filepath = [LeaderboardMgr leaderboardmgrFilePath];
    if ([fileManager fileExistsAtPath:filepath])
    {
        NSData* readData = [NSData dataWithContentsOfFile:filepath];
        if(readData)
        {
            current = [NSKeyedUnarchiver unarchiveObjectWithData:readData];
        }
    }
    return current;
}

- (void) saveLeaderboardMgrData
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    NSError* error = nil;
    BOOL writeSuccess = [data writeToFile:[LeaderboardMgr leaderboardmgrFilePath]
                                  options:NSDataWritingAtomic
                                    error:&error];
    if(writeSuccess)
    {
        NSLog(@"leaderboardmgr file saved successfully");
    }
    else
    {
        NSLog(@"leaderboardmgr file save failed: %@", error);
    }
}

- (void) removeLeaderboardMgrData
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* filepath = [LeaderboardMgr leaderboardmgrFilePath];
    NSError *error = nil;
    if ([fileManager fileExistsAtPath:filepath])
    {
        [fileManager removeItemAtPath:filepath error:&error];
    }
}

#pragma mark - Singleton
static LeaderboardMgr* singleton = nil;
+ (LeaderboardMgr*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
            // First, try to load the flyermgr data from disk
            singleton = [LeaderboardMgr loadLeaderboardMgrData];
            if (!singleton)
            {
                singleton = [[LeaderboardMgr alloc] init];
            }
		}
	}
	return singleton;
}

+ (void) destroyInstance
{
	@synchronized(self)
	{
		singleton = nil;
	}
}

@end