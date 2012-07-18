//
//  TradeItemTypes.h
//  traderpog
//
//  Created by Aaron Khoo on 7/16/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpCallbackDelegate.h"

static NSString* const kTradeItemTypes_ReceiveItems = @"TradeItemType_ReceiveItems";

@interface TradeItemTypes : NSObject
{
    NSMutableArray* _itemTypes;
    NSDate* _lastUpdate;
    
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<HttpCallbackDelegate>* _delegate;
}
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegate;

// Public methods
- (BOOL) needsRefresh;
- (void) retrieveItemsFromServer;

// Returns an array of TradeItemType
- (NSArray*) getItemTypesForTier:(unsigned int)tier;

// singleton
+(TradeItemTypes*) getInstance;
+(void) destroyInstance;

@end
