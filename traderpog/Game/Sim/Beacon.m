//
//  Beacon.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "Beacon.h"
#import "TradePostMgr.h"
#import "TradePost.h"
#import <CoreLocation/CoreLocation.h>

@interface Beacon()
{
    // transient variables
    CLLocationCoordinate2D _coord;
}
@property (nonatomic) CLLocationCoordinate2D coord;
@end

@implementation Beacon
@synthesize beaconId = _beaconId;
@synthesize postId = _postId;
@synthesize coord = _coord;

- (id) initWithBeaconId:(NSString*)beaconId postId:(NSString *)postId
{
    self = [super init];
    if(self)
    {
        _beaconId = beaconId;
        TradePost* post = [[TradePostMgr getInstance] getTradePostWithId:postId];
        if(post)
        {
            _coord = [post coord];
        }
    }
    return self;
}
@end
