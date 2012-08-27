//
//  FlyerTypes.m
//  traderpog
//
//  Created by Aaron Khoo on 7/25/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AFClientManager.h"
#import "FlyerTypes.h"
#import "GameManager.h"

static double const refreshTime = -(60 * 15);
static NSString* const kKeyVersion = @"version";
static NSString* const kKeyLastUpdate = @"lastUpdate";
static NSString* const kKeyFlyerTypes = @"flyerTypes";
static NSString* const kTradeItemTypesFilename = @"flyertypes.sav";

@interface FlyerTypes ()
{
    // internal
    NSString* _createdVersion;
    
    NSMutableArray* _flyerTypes;
    NSDate* _lastUpdate;
}
@end

@implementation FlyerTypes
@synthesize delegate = _delegate;
@synthesize flyerTypes = _flyerTypes;

- (id) init
{
    self = [super init];
    if(self)
    {
        _lastUpdate = nil;
        _flyerTypes = [[NSMutableArray alloc] init];
    }
    return self;
}


#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_createdVersion forKey:kKeyVersion];
    [aCoder encodeObject:_lastUpdate forKey:kKeyLastUpdate];
    [aCoder encodeObject:_flyerTypes forKey:kKeyFlyerTypes];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _createdVersion = [aDecoder decodeObjectForKey:kKeyVersion];
    _lastUpdate = [aDecoder decodeObjectForKey:kKeyLastUpdate];
    _flyerTypes = [aDecoder decodeObjectForKey:kKeyFlyerTypes];
    return self;
}

#pragma mark - private functions

+ (NSString*) flyertypesFilePath
{
    NSString* docsDir = [GameManager documentsDirectory];
    NSString* filepath = [docsDir stringByAppendingPathComponent:kTradeItemTypesFilename];
    return filepath;
}

#pragma mark - saved game data loading and unloading
+ (FlyerTypes*) loadFlyerTypesData
{
    FlyerTypes* current = nil;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* filepath = [FlyerTypes flyertypesFilePath];
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

- (void) saveFlyerTypesData
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    NSError* error = nil;
    BOOL writeSuccess = [data writeToFile:[FlyerTypes flyertypesFilePath]
                                  options:NSDataWritingAtomic
                                    error:&error];
    if(writeSuccess)
    {
        NSLog(@"flyer types file saved successfully");
    }
    else
    {
        NSLog(@"flyer types file save failed: %@", error);
    }
}

- (void) removeTradeItemTypesData
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* filepath = [FlyerTypes flyertypesFilePath];
    NSError *error = nil;
    if ([fileManager fileExistsAtPath:filepath])
    {
        [fileManager removeItemAtPath:filepath error:&error];
    }
}

#pragma mark - public functions
- (BOOL) needsRefresh
{
    return (!_lastUpdate) || ([_lastUpdate timeIntervalSinceNow] < refreshTime);
}

- (void) createFlyerArray:(id)responseObject
{
    for (NSDictionary* flyer in responseObject)
    {
        FlyerType* current = [[FlyerType alloc] initWithDictionary:flyer];
        [_flyerTypes addObject:current];
    }
}

- (void) retrieveFlyersFromServer
{    
    // make a post request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    [httpClient getPath:@"flyer_infos.json" 
             parameters:nil
                success:^(AFHTTPRequestOperation *operation, id responseObject){                     
                    NSLog(@"Retrieved: %@", responseObject);
                    [self createFlyerArray:responseObject];
                    _lastUpdate = [NSDate date];
                    [self saveFlyerTypesData];
                    [self.delegate didCompleteHttpCallback:kFlyerTypes_ReceiveFlyers, TRUE];
                }
                failure:^(AFHTTPRequestOperation* operation, NSError* error){
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                      message:@"Unable to create retrieve flyers. Please try again later."
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    
                    [message show];
                    [self.delegate didCompleteHttpCallback:kFlyerTypes_ReceiveFlyers, FALSE];
                }
     ];
}

- (FlyerType*) getFlyerTypeById:(NSString*)flyerId
{
    FlyerType* current = nil;
    for (FlyerType* flyer in _flyerTypes)
    {
        if ([[flyer flyerId] compare:flyerId] == NSOrderedSame)
        {
            current = flyer;
        }
    }
    return current;
}

- (NSInteger) getFlyerIndexById:(NSString*)flyerId
{
    BOOL found = false;
    NSInteger current = 0;
    for (FlyerType* flyer in _flyerTypes)
    {
        if ([[flyer flyerId] compare:flyerId] == NSOrderedSame)
        {
            found = true;
            break;
        }
        current++;
    }
    if (!found)
    {
        current = -1;
        NSLog(@"Could not match flyerId to list of flyer types!");
    }
    return current;
}

- (NSArray*) getFlyersForTier:(unsigned int)tier
{
    NSMutableArray* flyerArray = [[NSMutableArray alloc] init];
    for (FlyerType* flyer in _flyerTypes)
    {
        if ([flyer tier] == tier)
        {
            [flyerArray addObject:flyer];
        }
    }
    return (NSArray*)flyerArray;
}

#pragma mark - Singleton
static FlyerTypes* singleton = nil;
+ (FlyerTypes*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
            // First, try to load the flyer type data from disk
            singleton = [FlyerTypes loadFlyerTypesData];
            if (!singleton)
            {
                // OK, no saved data available. Go ahead and create a new FlyerTypes instance.
                singleton = [[FlyerTypes alloc] init];
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
