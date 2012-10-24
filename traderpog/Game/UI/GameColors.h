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

+ (UIColor*) bubbleBgColorWithAlpha:(CGFloat)alpha;
+ (UIColor*) bgColorFlyersWithAlpha:(CGFloat)alpha;
+ (UIColor*) gliderWhiteWithAlpha:(CGFloat)alpha;
+ (UIColor*) membershipCliponColorWithAlpha:(CGFloat)alpha;

+ (UIColor*) flyerBuyTier1ColorWithAlpha:(CGFloat)alpha;
+ (UIColor*) flyerBuyTier2ColorWithAlpha:(CGFloat)alpha;
@end
