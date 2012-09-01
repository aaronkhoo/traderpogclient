//
//  GameColors.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/31/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "GameColors.h"

@implementation GameColors

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
    UIColor* result = [UIColor colorWithRed:229.0f/255.0f green:54.0f/255.0f blue:9.0f/255.0f alpha:alpha];
    return result;
}

+ (UIColor*) bubbleColorScanWithAlpha:(CGFloat)alpha
{
    UIColor* result = [UIColor colorWithRed:8.0f/255.0f green:67.0f/255.0f blue:67.0f/255.0f alpha:alpha];
    return result;
}

+ (UIColor*) borderColorFlyersWithAlpha:(CGFloat)alpha
{
    UIColor* result = [UIColor colorWithRed:93.0f/255.0f green:155.0f/255.0f blue:207.0f/255.0f alpha:1.0f];
    return result;
}

+ (UIColor*) borderColorBeaconsWithAlpha:(CGFloat)alpha
{
    UIColor* result = [UIColor colorWithRed:27.0f/255.0f green:89.0f/255.0f blue:141.0f/255.0f alpha:1.0f];
    return result;
}

+ (UIColor*) borderColorPostsWithAlpha:(CGFloat)alpha
{
    UIColor* result = [UIColor colorWithRed:177.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:1.0f];
    return result;
}

+ (UIColor*) borderColorScanWithAlpha:(CGFloat)alpha
{
    UIColor* result = [UIColor colorWithRed:48.0f/255.0f green:80.0f/255.0f blue:107.0f/255.0f alpha:1.0f];
    return result;
}


@end
