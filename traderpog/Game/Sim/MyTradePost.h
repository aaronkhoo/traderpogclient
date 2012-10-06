//
//  MyTradePost.h
//  traderpog
//
//  Created by Aaron Khoo on 8/31/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlayerTradePost.h"

/*
enum kMyTradePostStates
{
    kMyTradePostState_Idle = 0,
    kMyTradePostState_FlyerWaitingToUnload,
    kMyTradePostState_FlyerUnloading,
    kMyTradePostState_FlyerIdle,
    kMyTradePostState_PreFlyerLab,
    
    kMyTradePostState_Num
};
*/
@interface MyTradePost : PlayerTradePost
{
    BOOL _preFlyerLab;
}
@property (nonatomic) BOOL preFlyerLab;

- (id) initWithCoordinates:(CLLocationCoordinate2D)coordinate
                  itemType:(TradeItemType *)itemType;
- (void) createNewPostOnServer;
- (void) setBeacon;
- (bool) beaconActive;

@end
