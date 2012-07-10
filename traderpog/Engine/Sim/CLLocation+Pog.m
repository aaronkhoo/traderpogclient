//
//  CLLocation+Pog.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 4/16/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "CLLocation+Pog.h"

@implementation CLLocation (Pog)

+ (CLLocation*) geoloPigs
{ 
    CLLocation* result = [[CLLocation alloc] initWithLatitude:37.78959 longitude:-122.41235];
    return result;
}

+ (CLLocation*) seattle
{
    CLLocation* result = [[CLLocation alloc] initWithLatitude:47.609722 longitude:-122.333056];
    return result;
}

+ (CLLocation*) sanFrancisco
{
    CLLocation* result = [[CLLocation alloc] initWithLatitude:37.787359 longitude:-122.408227];
    return result;
}

+ (CLLocation*) penang
{
    CLLocation* result = [[CLLocation alloc] initWithLatitude:5.416667 longitude:100.31667];
    return result;    
}

+ (CLLocation*) kualaLumpur
{
    CLLocation* result = [[CLLocation alloc] initWithLatitude:3.116667 longitude:101.7];
    return result;    
}
@end
