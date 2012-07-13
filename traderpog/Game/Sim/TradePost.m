//
//  TradePost.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "TradePost.h"

static NSString* const kKeyLong = @"longitude";
static NSString* const kKeyLat = @"latitude";

@implementation TradePost
@synthesize coord = _coord;
- (id) initWithCoordinate:(CLLocationCoordinate2D)coordinate
{
    self = [super init];
    if(self)
    {
        _coord = coordinate;
    }
    return self;
}

#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeDouble:_coord.latitude forKey:kKeyLat];
    [aCoder encodeDouble:_coord.longitude forKey:kKeyLong];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self.coord = CLLocationCoordinate2DMake([aDecoder decodeDoubleForKey:kKeyLat], 
                                            [aDecoder decodeDoubleForKey:kKeyLong]);
    
    return self;
}

@end
