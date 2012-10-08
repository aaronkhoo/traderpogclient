//
//  PlayerSales.m
//  traderpog
//
//  Created by Aaron Khoo on 10/2/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AFClientManager.h"
#import "GameManager.h"
#import "Player.h"
#import "PlayerSales.h"

static double const refreshTime = -(60 * 15);
static NSString* const kKeyVersion = @"version";
static NSString* const kKeyBucks = @"bucks";
static NSString* const kKeyHasSales = @"hassales";
static NSString* const kKeyFbidArray = @"fbidarray";
static NSString* const kKeyNonNamedCount = @"nonnamedcount";
static NSString* const kKeyLastUpdated= @"lastUpdated";
static NSString* const kPlayerSalesFilename = @"playersales.sav";

@interface PlayerSales ()
{
    // internal
    NSString* _createdVersion;
    
}
@end

@implementation PlayerSales
@synthesize hasSales = _hasSales;
@synthesize bucks = _bucks;
@synthesize nonNamedCount = _nonNamedCount;
@synthesize fbidArray = _fbidArray;
@synthesize delegate = _delegate;

- (id) init
{
    self = [super init];
    if(self)
    {
        _hasSales = FALSE;
        _lastUpdate = nil;
    }
    return self;
}

- (BOOL) needsRefresh
{
    return (!_hasSales && (!_lastUpdate || ([_lastUpdate timeIntervalSinceNow] < refreshTime)));
}

- (void) retrieveSalesFromServer
{
    // Reset values
    // Try resolveSales first in case there were outstanding sales to be resolved before
    // call was made to retrieve more sales from the server
    [self resolveSales];
    _bucks = 0;
    _hasSales = FALSE;
    _fbidArray = [NSMutableArray arrayWithCapacity:5];
    _nonNamedCount = 0;
    
    // make a get request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    NSString* salesPath = [NSString stringWithFormat:@"users/%d/sales.json", [[Player getInstance] playerId]];
    [httpClient getPath:salesPath
             parameters:nil
                success:^(AFHTTPRequestOperation *operation, id responseObject){
                    NSLog(@"Retrieved: %@", responseObject);
                    [self computeSales:responseObject];
                    _lastUpdate = [NSDate date];
                    [self savePlayerSalesData];
                    [self.delegate didCompleteHttpCallback:kPlayerSales_ReceiveSales, TRUE];
                }
                failure:^(AFHTTPRequestOperation* operation, NSError* error){
                    // Don't indicate failure, just log it
                    NSLog(@"Retrieve sales from server failed.");
                    [self.delegate didCompleteHttpCallback:kPlayerSales_ReceiveSales, FALSE];
                }
     ];
}

- (void) computeSales:(id)responseObject
{
    NSInteger friendCount = 0;
    
    for (NSDictionary* sale in responseObject)
    {
        _bucks = _bucks + [[sale valueForKeyPath:@"amount"] integerValue];
        
        id obj = [sale valueForKeyPath:@"fbid"];
        if ((NSNull *)obj == [NSNull null])
        {
            // Count the non-facebook account that traded with some post
            _nonNamedCount++;
        }
        else
        {
            NSString* fbid = [NSString stringWithFormat:@"%@", obj];
            NSString* name = [[Player getInstance] getFacebookNameByFbid:fbid];
            if (name)
            {
                if (friendCount < 5)
                {
                    [_fbidArray addObject:fbid];
                    friendCount++;
                }
                else
                {
                    // Count the friend that traded with some post
                    _nonNamedCount++;
                }
            }
            else
            {
                // Count the non-friend that traded with some post
                _nonNamedCount++;
            }
        }
    }
    
    // Construct the message
    if (_bucks > 0)
    {
        _hasSales = TRUE;
    }
}

- (void) resolveSales
{
    if (_hasSales)
    {
        [[Player getInstance] addBucks:_bucks];
        _hasSales = FALSE;
        [self savePlayerSalesData];
    }
}

#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_createdVersion forKey:kKeyVersion];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:_bucks] forKey:kKeyBucks];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:_nonNamedCount] forKey:kKeyNonNamedCount];
    [aCoder encodeObject:_fbidArray forKey:kKeyFbidArray];
    [aCoder encodeBool:_hasSales forKey:kKeyHasSales];
    [aCoder encodeObject:_lastUpdate forKey:kKeyLastUpdated];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _createdVersion = [aDecoder decodeObjectForKey:kKeyVersion];
    _bucks = [[aDecoder decodeObjectForKey:kKeyBucks] unsignedIntegerValue];
    _nonNamedCount = [[aDecoder decodeObjectForKey:kKeyNonNamedCount] unsignedIntegerValue];
    _hasSales = [aDecoder decodeBoolForKey:kKeyHasSales];
    _fbidArray = [aDecoder decodeObjectForKey:kKeyFbidArray];
    _lastUpdate = [aDecoder decodeObjectForKey:kKeyLastUpdated];
    return self;
}

#pragma mark - private functions

+ (NSString*) playerSalesFilePath
{
    NSString* docsDir = [GameManager documentsDirectory];
    NSString* filepath = [docsDir stringByAppendingPathComponent:kPlayerSalesFilename];
    return filepath;
}

#pragma mark - saved game data loading and unloading
+ (PlayerSales*) loadPlayerSalesData
{
    PlayerSales* current = nil;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* filepath = [PlayerSales playerSalesFilePath];
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

- (void) savePlayerSalesData
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    NSError* error = nil;
    BOOL writeSuccess = [data writeToFile:[PlayerSales playerSalesFilePath]
                                  options:NSDataWritingAtomic
                                    error:&error];
    if(writeSuccess)
    {
        NSLog(@"playersales file saved successfully");
    }
    else
    {
        NSLog(@"playersales file save failed: %@", error);
    }
}

- (void) removePlayerSalesData
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* filepath = [PlayerSales playerSalesFilePath];
    NSError *error = nil;
    if ([fileManager fileExistsAtPath:filepath])
    {
        [fileManager removeItemAtPath:filepath error:&error];
    }
}

#pragma mark - Singleton
static PlayerSales* singleton = nil;
+ (PlayerSales*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
            // First, try to load the playersales data from disk
            singleton = [PlayerSales loadPlayerSalesData];
            if (!singleton)
            {
                singleton = [[PlayerSales alloc] init];
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
