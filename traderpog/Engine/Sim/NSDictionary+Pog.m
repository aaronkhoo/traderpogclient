//
//  NSDictionary+Pog.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/18/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "NSDictionary+Pog.h"

@implementation NSDictionary (Pog)

- (float) getFloatForKey:(NSString *)varKey withDefault:(float)defaultValue
{
    float result = defaultValue;
    NSNumber* varNumber = [self objectForKey:varKey];
    if(varNumber)
    {
        result = [varNumber floatValue];
    }
    return result;
}

- (int) getIntForKey:(NSString *)varKey withDefault:(int)defaultValue
{
    int result = defaultValue;
    NSNumber* varNumber = [self objectForKey:varKey];
    if(varNumber)
    {
        result = [varNumber intValue];
    }
    return result;
}

- (unsigned int) getUnsignedIntForKey:(NSString *)varKey withDefault:(unsigned int)defaultValue
{
    unsigned int result = defaultValue;
    NSNumber* varNumber = [self objectForKey:varKey];
    if(varNumber)
    {
        result = [varNumber unsignedIntValue];
    }
    return result;
}

- (BOOL) getBoolForKey:(NSString *)varKey
{
    // NO if key doesn't exist
    BOOL result = NO;
    NSNumber* varNumber = [self objectForKey:varKey];
    if(varNumber)
    {
        result = [varNumber boolValue];
    }
    return result;
}

@end
