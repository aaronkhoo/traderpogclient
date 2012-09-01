//
//  GameColors.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/31/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "GameColors.h"

@implementation GameColors

case kKnobSliceFlyer:
break;

case kKnobSliceBeacon:
break;

case kKnobSlicePost:
break;

default:
case kKnobSliceScan:
result = [UIColor colorWithRed:8.0f/255.0f green:67.0f/255.0f blue:67.0f/255.0f alpha:alpha];
break;

+ (UIColor*) bubbleColorFlyersWithAlpha:(CGFloat)alpha
{
    UIColor* result = [UIColor colorWithRed:0.0f/255.0f green:112.0f/255.0f blue:185.0f/255.0f alpha:alpha];
    return result;
}

+ (UIColor*) bubbleColorBeaconsWithAlpha:(CGFloat)alpha
{
    UIColor* result = [UIColor colorWithRed:2.0f/255.0f green:64.0f/255.0f blue:116.0f/255.0f alpha:alpha];
    return result;
}

+ (UIColor*) bubbleColorPostsWithAlpha:(CGFloat)alpha
{
    result = [UIColor colorWithRed:229.0f/255.0f green:54.0f/255.0f blue:9.0f/255.0f alpha:alpha];
}

+ (UIColor*) bubbleColorScan
{
    
}

+ (UIColor*) borderColorFlyers
{
    
}

+ (UIColor*) borderColorBeacons
{
    
}

+ (UIColor*) borderColorPosts
{
    
}

+ (UIColor*) borderColorScan
{
    
}


@end
