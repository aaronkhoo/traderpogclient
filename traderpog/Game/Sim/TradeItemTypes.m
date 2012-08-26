//
//  TradeItemTypes.m
//  traderpog
//
//  Created by Aaron Khoo on 7/16/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "TradeItemTypes.h"
#import "TradeItemType.h"
#import "AFClientManager.h"

static double const refreshTime = -(60 * 15);
const unsigned int kTradeItemTierMin = 1;
NSString* const kTradeItemTypes_ReceiveItems = @"TradeItemType_ReceiveItems";

@interface TradeItemTypes ()
{
    NSMutableDictionary* _itemTypeReg;
}
@property (nonatomic,strong) NSMutableDictionary* itemTypeReg;
@end

@implementation TradeItemTypes
@synthesize delegate = _delegate;
@synthesize itemTypes = _itemTypes;
@synthesize itemTypeReg = _itemTypeReg;

- (id) init
{
    self = [super init];
    if(self)
    {
        _lastUpdate = nil;
        _itemTypes = [[NSMutableArray alloc] init];
        _itemTypeReg = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    return self;
}

- (BOOL) needsRefresh
{
    return (!_lastUpdate) || ([_lastUpdate timeIntervalSinceNow] < refreshTime);
}

- (void) createItemsReg:(id)responseObject
{
    for (NSDictionary* item in responseObject)
    {
        TradeItemType* current = [[TradeItemType alloc] initWithDictionary:item];
        [_itemTypeReg setObject:current forKey:[current itemId]];
        [_itemTypes addObject:current];
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
                     [self.delegate didCompleteHttpCallback:kTradeItemTypes_ReceiveItems, TRUE];
                 }
                 failure:^(AFHTTPRequestOperation* operation, NSError* error){
                     UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                       message:@"Unable to create retrieve items. Please try again later."
                                                                      delegate:nil
                                                             cancelButtonTitle:@"OK"
                                                             otherButtonTitles:nil];
                     
                     [message show];
                     [self.delegate didCompleteHttpCallback:kTradeItemTypes_ReceiveItems, FALSE];
                 }
     ];
}

- (NSArray*) getItemTypesForTier:(unsigned int)tier
{
    tier = MAX(kTradeItemTierMin, tier);
    NSMutableArray* itemArray = [[NSMutableArray alloc] init];
    for (TradeItemType* item in _itemTypes)
    {
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
            singleton = [[TradeItemTypes alloc] init];
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
