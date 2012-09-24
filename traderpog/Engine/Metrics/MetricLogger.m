//
//  MetricLogger.m
//  traderpog
//
//  Created by Aaron Khoo on 9/22/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "LocalyticsSession.h"
#import "MetricLogger.h"
#import "Player.h"

@implementation MetricLogger

+ (void)internalLog:(NSString*)eventName eventDict:(NSDictionary*)eventDict
{
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:eventName attributes:eventDict];
}

+ (void)logError:(NSString*)eventName eventDict:(NSDictionary*)eventDict
{
    //NSString* fullEventName = [NSString stringWithFormat:@"error_%@", eventName];
    //NSInteger playerId = [[Player getInstance] playerId];
}

+ (void)logCreateObject:(NSString*)objectType slot:(unsigned int)slot member:(BOOL)member
{
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                objectType,
                                @"Game Object",
                                [NSNumber numberWithBool:member],
                                @"Membership",
                                [NSNumber numberWithUnsignedInt:slot],
                                @"Slot number",
                                nil];
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Create Game Object" attributes:dictionary];
}

+ (void)logDepartEvent:(NSString*)flyerType postType:(NSString*)postType
{
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                        flyerType,
                                        @"Flyer Type",
                                        postType,
                                        @"Post Type",
                                        nil];
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Depart For Post" attributes:dictionary];
}

+ (void)logArriveEvent:(double)dist numItems:(unsigned int)numItems itemType:(NSString*)itemType
{
    NSString* distance_text;
    double dist_in_km = dist / 1000.0;
    if (dist_in_km < 10.0)
    {
        distance_text = @"< 10.0 km";
    }
    else if (dist_in_km >= 10.0 && dist_in_km < 100.0)
    {
        distance_text = @">= 10.0 km && < 100.0 km";
    }
    else if (dist_in_km >= 100.0 && dist_in_km < 1000.0)
    {
        distance_text = @">= 100.0 km && < 1000.0 km";
    }
    else if (dist_in_km >= 1000.0 && dist_in_km < 10000.0)
    {
        distance_text = @">= 1000.0 km && < 10000.0 km";
    }
    else // if (dist_in_km >= 10000.0)
    {
        distance_text = @">= 10000.0 km";
    }
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                distance_text,
                                @"Distance traveled",
                                itemType,
                                @"Item Type",
                                [NSNumber numberWithUnsignedInt:numItems],
                                @"Numer of items",
                                nil];
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Arrive At Post" attributes:dictionary];
}

@end
