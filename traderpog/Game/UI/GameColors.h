//
//  GameColors.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/31/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GameColors : NSObject
+ (UIColor*) bubbleColorFlyersWithAlpha:(CGFloat)alpha;
+ (UIColor*) bubbleColorBeaconsWithAlpha:(CGFloat)alpha;
+ (UIColor*) bubbleColorPostsWithAlpha:(CGFloat)alpha;
+ (UIColor*) bubbleColorScanWithAlpha:(CGFloat)alpha;

+ (UIColor*) borderColorFlyersWithAlpha:(CGFloat)alpha;
+ (UIColor*) borderColorBeaconsWithAlpha:(CGFloat)alpha;
+ (UIColor*) borderColorPostsWithAlpha:(CGFloat)alpha;
+ (UIColor*) borderColorScanWithAlpha:(CGFloat)alpha;
@end
