//
//  TradePostMgr.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class TradePost;
@interface TradePostMgr : NSObject

- (TradePost*) newTradePostAtCoord:(CLLocationCoordinate2D)coord 
                       sellingItem:(NSString*)itemId
                        isHomebase:(BOOL)isHomebase;
- (TradePost*) getTradePostWithId:(NSString*)postId;
- (TradePost*) getHomebase;

// singleton
+(TradePostMgr*) getInstance;
+(void) destroyInstance;


@end
