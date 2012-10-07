//
//  NSDictionary+Pog.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/18/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Pog)
- (float) getFloatForKey:(NSString*)varKey withDefault:(float)defaultValue;
- (int) getIntForKey:(NSString*)varKey withDefault:(int)defaultValue;
- (unsigned int) getUnsignedIntForKey:(NSString*)varKey withDefault:(unsigned int)defaultValue;
- (BOOL) getBoolForKey:(NSString*)varKey;
@end
