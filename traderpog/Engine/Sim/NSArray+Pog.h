//
//  NSArray+Pog.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/25/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Pog)

// returns TRUE if array contains an NSString object whose string
// value matches the query string
- (BOOL) stringArrayContainsString:(NSString*)queryString;
@end
