//
//  MKMapView+Game.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/3/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "MKMapView+Game.h"
#import "BeaconMgr.h"
#import "FlyerMgr.h"
#import "TradePostMgr.h"

@implementation MKMapView (Game)
- (BOOL) isPreviewMap
{
    BOOL result = NO;
    
    if(([BeaconMgr getInstance].previewMap.view == self) ||
       ([TradePostMgr getInstance].previewMap.view == self) ||
       ([FlyerMgr getInstance].previewMap.view == self))
    {
        result = YES;
    }
    
    return result;
}
@end
