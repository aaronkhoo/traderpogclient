//
//  ViewReuseQueue.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/4/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "ViewReuseQueue.h"

@implementation ViewReuseQueue
- (id) init
{
    self = [super init];
    if(self)
    {
        _registry = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void) clearQueue
{
    [_registry removeAllObjects];
}

- (void) queueView:(UIView<ViewReuseDelegate>*)view
{
    NSString* key = [view reuseIdentifier];
    NSMutableArray* array = [_registry objectForKey:key];
    if(!array)
    {
        array = [NSMutableArray array];
        [_registry setObject:array forKey:key];
    }
    if(array)
    {
        [array addObject:view];
    }
}

- (UIView*) dequeueReusableViewWithIdentifier:(NSString*)identifier
{
    UIView* result = nil;
    NSMutableArray* array = [_registry objectForKey:identifier];
    if(array && [array count])
    {
        result = [array objectAtIndex:0];
        [array removeObjectAtIndex:0];
    }
    
    return result;
}


@end
