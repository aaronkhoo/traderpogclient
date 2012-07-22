//
//  Flyer.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/21/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TradePost;
@class FlightPathOverlay;
@interface Flyer : NSObject
{
    NSString* _curPostId;
    NSString* _nextPostId;
    FlightPathOverlay* _flightPathRender;
}
@property (nonatomic,strong) NSString* curPostId;
@property (nonatomic,strong) NSString* nextPostId;
@property (nonatomic,strong) FlightPathOverlay* flightPathRender;

- (id) initAtPost:(TradePost*)tradePost;
- (void) departForPostId:(NSString*)postId;
@end
