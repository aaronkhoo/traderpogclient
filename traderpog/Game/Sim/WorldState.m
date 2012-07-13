//
//  WorldState.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "WorldState.h"

static NSString* const kKeyActivePosts = @"activePosts";

@implementation WorldState
@synthesize activeTradePosts = _activeTradePosts;

- (id) init
{
    self = [super init];
    if(self)
    {
        _activeTradePosts = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    return self;
}

#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_activeTradePosts forKey:kKeyActivePosts];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self.activeTradePosts = [aDecoder decodeObjectForKey:kKeyActivePosts];
    return self;
}

@end
