//
//  Flyer.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/21/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "Flyer.h"
#import "TradePost.h"
#import "FlightPathOverlay.h"
#import "TradePostMgr.h"

@implementation Flyer
@synthesize curPostId = _curPostId;
@synthesize nextPostId = _nextPostId;
@synthesize flightPathRender = _flightPathRender;
@synthesize annotation = _annotation;
@synthesize coord = _coord;

- (id) initAtPost:(TradePost*)tradePost
{
    self = [super init];
    if(self)
    {
        _curPostId = [tradePost postId];
        _nextPostId = nil;
        _flightPathRender = nil;
        _annotation = nil;
        _coord = [tradePost coord];
    }
    return self;
}

- (void) departForPostId:(NSString *)postId
{
    if(![postId isEqualToString:[self curPostId]])
    {
        self.nextPostId = postId;
        
        // create renderer
        CLLocationCoordinate2D srcCoord = [[[TradePostMgr getInstance] getTradePostWithId:[self curPostId]] coord];
        CLLocationCoordinate2D destCoord = [[[TradePostMgr getInstance] getTradePostWithId:[self nextPostId]] coord];
        self.flightPathRender = [[FlightPathOverlay alloc] initWithSrcCoord:srcCoord destCoord:destCoord];
    }
}

@end
