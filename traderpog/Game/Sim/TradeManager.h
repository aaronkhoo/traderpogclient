//
//  TradeManager.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/11/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Flyer;
@class TradePost;
@interface TradeManager : NSObject

// actions
- (void) flyer:(Flyer*)flyer buyFromPost:(TradePost*)post numItems:(unsigned int)numItems;
- (void) flyer:(Flyer*)flyer didArriveAtPost:(TradePost*)post;

// queries on post
- (unsigned int) numItemsPlayerCanBuyAtPost:(TradePost*)post;
- (unsigned int) totalCostForNumItems:(unsigned int)num atPost:(TradePost*)post;
- (BOOL) playerCanAffordItemsAtPost:(TradePost*)post;
- (BOOL) playerHasIdleFlyers;

// singleton
+(TradeManager*) getInstance;
+(void) destroyInstance;

@end
