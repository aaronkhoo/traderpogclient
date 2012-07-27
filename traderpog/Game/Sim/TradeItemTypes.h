//
//  TradeItemTypes.h
//  traderpog
//
//  Created by Aaron Khoo on 7/16/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpCallbackDelegate.h"

extern NSString* const kTradeItemTypes_ReceiveItems;
extern const unsigned int kTradeItemTierMin;

@class TradeItemType;
@interface TradeItemTypes : NSObject
{
    NSMutableArray* _itemTypes;
    NSDate* _lastUpdate;
    
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<HttpCallbackDelegate>* _delegate;
}
@property (nonatomic,strong) NSMutableArray* itemTypes;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegate;

// Public methods
- (BOOL) needsRefresh;
- (void) retrieveItemsFromServer;

// Returns an array of TradeItemType
- (NSArray*) getItemTypesForTier:(unsigned int)tier;
- (TradeItemType*) getItemTypeForId:(NSString*)itemId;

// singleton
+(TradeItemTypes*) getInstance;
+(void) destroyInstance;

@end
