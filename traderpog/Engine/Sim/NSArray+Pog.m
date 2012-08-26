//
//  NSArray+Pog.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/25/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "NSArray+Pog.h"

@implementation NSArray (Pog)

- (BOOL) stringArrayContainsString:(NSString *)queryString
{
    BOOL result = NO;
    for(id cur in self)
    {
        NSLog(@"cur is %@", cur);
        if([cur isKindOfClass:[NSString class]])
        {
            NSString* curString = (NSString*)cur;
            if([queryString isEqualToString:curString])
            {
                result = YES;
                break;
            }
        }
    }
    return result;
}

@end
