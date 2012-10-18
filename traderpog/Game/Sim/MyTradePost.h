//
//  MyTradePost.h
//  traderpog
//
//  Created by Aaron Khoo on 8/31/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlayerTradePost.h"

@interface MyTradePost : PlayerTradePost
{
    BOOL _preFlyerLab;
    
    // transient
    NSString* _lastUnloadedItemId;
}
@property (nonatomic) BOOL preFlyerLab;
@property (nonatomic,strong) NSString* lastUnloadedItemId;

- (id) initWithCoordinates:(CLLocationCoordinate2D)coordinate
                  itemType:(TradeItemType *)itemType;
- (void) createNewPostOnServer;
- (void) setBeacon;
- (bool) beaconActive;
- (void) raiseEmptySupplyAtPostIfNecessary;
- (void)restockPostSupply;

@end
