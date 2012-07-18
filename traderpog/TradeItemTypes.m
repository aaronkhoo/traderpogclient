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

@implementation TradeItemTypes
@synthesize delegate = _delegate;

- (id) init
{
    self = [super init];
    if(self)
    {
        _lastUpdate = nil;
        _itemTypes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (BOOL) needsRefresh
{
    return (!_lastUpdate) || ([_lastUpdate timeIntervalSinceNow] < refreshTime);
}

- (void) createItemsArray:(id)responseObject
{
    for (NSDictionary* item in responseObject)
    {
        TradeItemType* current = [[TradeItemType alloc] initWithDictionary:item];
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
                     [self createItemsArray:responseObject];
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
    return nil;
}

#pragma mark - Singleton
static TradeItemTypes* singleton = nil;
+ (TradeItemTypes*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
            // First, try to load the player data from disk
            //singleton = [TradeItemTypes loadPlayerData];
            if (!singleton)
            {
                // OK, no saved data available. Go ahead and create a new Player. 
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
