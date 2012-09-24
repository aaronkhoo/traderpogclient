//
//  MetricLogger.h
//  traderpog
//
//  Created by Aaron Khoo on 9/22/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MetricLogger : NSObject

+ (void)logError:(NSString*)eventName eventDict:(NSDictionary*)eventDict;

+ (void)logCreateObject:(NSString*)objectType slot:(unsigned int)slot member:(BOOL)member;
+ (void)logDepartEvent:(NSString*)flyerType postType:(NSString*)postType;
+ (void)logArriveEvent:(double)dist numItems:(unsigned int)numItems itemType:(NSString*)itemType;

@end
