//
//  TradeItemTypes.m
//  traderpog
//
//  Created by Aaron Khoo on 7/16/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "GameManager.h"
#import "TradeItemTypes.h"
#import "TradeItemType.h"
#import "AFClientManager.h"

const unsigned int kTradeItemTierMin = 1;
NSString* const kTradeItemTypes_ReceiveItems = @"TradeItemType_ReceiveItems";
static NSString* const kKeyVersion = @"version";
static NSString* const kKeyLastUpdate = @"lastUpdate";
static NSString* const kKeyItemTypes = @"itemTypes";
static NSString* const kTradeItemTypesFilename = @"tradeitemtypes.sav";

@interface TradeItemTypes ()
{
    // internal
    NSString* _createdVersion;
    
    NSDate* _lastUpdate;
    NSMutableDictionary* _itemTypeReg;
}
@property (nonatomic,strong) NSMutableDictionary* itemTypeReg;
@end

@implementation TradeItemTypes
@synthesize delegate = _delegate;
@synthesize itemTypeReg = _itemTypeReg;

- (id) init
{
    self = [super init];
    if(self)
    {
        _lastUpdate = nil;
        _itemTypeReg = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    return self;
}

#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_createdVersion forKey:kKeyVersion];
    [aCoder encodeObject:_lastUpdate forKey:kKeyLastUpdate];
    [aCoder encodeObject:_itemTypeReg forKey:kKeyItemTypes];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _createdVersion = [aDecoder decodeObjectForKey:kKeyVersion];
    _lastUpdate = [aDecoder decodeObjectForKey:kKeyLastUpdate];
    _itemTypeReg = [aDecoder decodeObjectForKey:kKeyItemTypes];
    return self;
}

#pragma mark - private functions

+ (NSString*) tradeitemtypesFilePath
{
    NSString* docsDir = [GameManager documentsDirectory];
    NSString* filepath = [docsDir stringByAppendingPathComponent:kTradeItemTypesFilename];
    return filepath;
}

#pragma mark - saved game data loading and unloading
+ (TradeItemTypes*) loadTradeItemTypesData
{
    TradeItemTypes* current = nil;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* filepath = [TradeItemTypes tradeitemtypesFilePath];
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

- (void) saveTradeItemTypesData
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    NSError* error = nil;
    BOOL writeSuccess = [data writeToFile:[TradeItemTypes tradeitemtypesFilePath]
                                  options:NSDataWritingAtomic
                                    error:&error];
    if(writeSuccess)
    {
        NSLog(@"trade item types file saved successfully");
    }
    else
    {
        NSLog(@"trade item types file save failed: %@", error);
    }
}

- (void) removeTradeItemTypesData
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* filepath = [TradeItemTypes tradeitemtypesFilePath];
    NSError *error = nil;
    if ([fileManager fileExistsAtPath:filepath])
    {
        [fileManager removeItemAtPath:filepath error:&error];
    }
}

#pragma mark - public functions
- (BOOL) needsRefresh:(NSDate*) lastModifiedDate
{
    return (!_lastUpdate) || ([_lastUpdate timeIntervalSinceDate:lastModifiedDate] < 0);
}

- (void) createItemsReg:(id)responseObject
{
    for (NSDictionary* item in responseObject)
    {
        TradeItemType* current = [[TradeItemType alloc] initWithDictionary:item];
        [_itemTypeReg setObject:current forKey:[current itemId]];
    }
}

- (void) retrieveItemsFromServer
{    
    // make a post request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    [httpClient getPath:@"item_infos.json" 
              parameters:nil
                 success:^(AFHTTPRequestOperation *operation, id responseObject){                     
                     NSLog(@"Retrieved: %@", responseObject);
                     [self createItemsReg:responseObject];
                     _lastUpdate = [NSDate date];
                     [self saveTradeItemTypesData];
                     [self.delegate didCompleteHttpCallback:kTradeItemTypes_ReceiveItems, TRUE];
                 }
                 failure:^(AFHTTPRequestOperation* operation, NSError* error){
                     if (_lastUpdate)
                     {
                         // GameInfo has previously been retrieved. Use the previous version for now.
                         NSLog(@"Downloading new Trade Item Types info from server has failed. Using old version of data");
                         [self.delegate didCompleteHttpCallback:kTradeItemTypes_ReceiveItems, TRUE];
                     }
                     else
                     {
                         // GameInfo has never been updated. Have to pop an error.
                         UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                           message:@"Unable to create retrieve items. Please try again later."
                                                                          delegate:nil
                                                                 cancelButtonTitle:@"OK"
                                                                 otherButtonTitles:nil];
                         
                         [message show];
                         [self.delegate didCompleteHttpCallback:kTradeItemTypes_ReceiveItems, FALSE];
                     }
                 }
     ];
}

- (NSArray*) getItemTypesForTier:(unsigned int)tier
{
    tier = MAX(kTradeItemTierMin, tier);
    NSMutableArray* itemArray = [[NSMutableArray alloc] init];
    for (id key in _itemTypeReg) {
        TradeItemType* item = [_itemTypeReg objectForKey:key];
        if ([item tier] == tier)
        {
            [itemArray addObject:item];
        }
    }
    return (NSArray*)itemArray;
}

- (TradeItemType*) getItemTypeForId:(NSString *)itemId
{
    TradeItemType* itemType = [self.itemTypeReg objectForKey:itemId];
    return itemType;
}

#pragma mark - Singleton
static TradeItemTypes* singleton = nil;
+ (TradeItemTypes*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
            // First, try to load the trade item types data from disk
            singleton = [TradeItemTypes loadTradeItemTypesData];
            if (!singleton)
            {
                // OK, no saved data available. Go ahead and create a new TradeItemTypes instance.
                singleton = [[TradeItemTypes alloc] init];
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
