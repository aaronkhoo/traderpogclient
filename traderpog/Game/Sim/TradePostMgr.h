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

- (void) setHomebase:(TradePost*)newPost;
- (TradePost*) getHomebase;

// singleton
+(TradePostMgr*) getInstance;
+(void) destroyInstance;


@end
