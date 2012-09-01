//
//  NPCTradePost.h
//  traderpog
//
//  Created by Aaron Khoo on 8/31/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TradePost.h"

@interface NPCTradePost : TradePost

- (id) initWithPostId:(NSString*)postId
           coordinate:(CLLocationCoordinate2D)coordinate
                bucks:(unsigned int)bucks;

@end
