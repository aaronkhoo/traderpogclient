//
//  PogUIUtility.h
//  PeterPog
//
//  Utility functions for UI
//
//  Created by Shu Chiun Cheah on 2/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

// tag numbering convention for PogUI elements
#define BACKSCRIM_VIEW_TAG (10)

typedef void (^CompletionBlock)(BOOL finished);

@interface PogUIUtility : NSObject

+ (NSString*) stringFromTimeInterval:(NSTimeInterval)timeInterval;
+ (NSDate*) convertUtcToNSDate:(NSString*)utcdate;
+ (NSString*) convertNSDateToUtc:(NSDate*)utcdate;
+ (NSString*) commaSeparatedStringFromUnsignedInt:(unsigned int)number;
+ (NSString*) currencyStringForAmount:(unsigned int)amount;
+ (NSString*) stringTrimAllWhitespaces:(NSString*)src;
+ (NSDate*) getMondayOfTheWeek;

+ (void) followUsOnTwitter;

+ (UIView*) createBorderForView:(UIView*)targetView;
+ (UIView*) createScrimForView:(UIView*)targetView color:(UIColor*)color;
+ (void) createScrimAndBorderForView:(UIView*)contentView;
+ (void) createInsertScrimForView:(UIView*)contentView;
+ (void) setRoundCornersForView:(UIView*)targetView;
+ (void) setRoundCornersForView:(UIView *)targetView withCornerRadius:(float)radius;
+ (void) setCircleForView:(UIView*)targetView;
+ (void) setCircleForView:(UIView *)targetView
          withBorderWidth:(float)borderWidth
              borderColor:(UIColor*)borderColor;
+ (void) setCircleForView:(UIView *)targetView
          withBorderWidth:(float)borderWidth
              borderColor:(UIColor*)borderColor
           rasterizeScale:(float)rasterScale;
+ (void) setCircleShadowOnView:(UIView*)view
                   shadowColor:(UIColor*)shadowColor;
+ (void) setBorderOnView:(UIView*)view width:(float)borderWidth color:(UIColor*)borderColor;

+ (UIView*) createFadeAlert:(NSString*)message;
+ (void) fadeView:(UIView*)parentView toColor:(UIColor*)color completion:(CompletionBlock)completionBlock;
+ (void) fadeView:(UIView*)parentView fromColor:(UIColor*)color completion:(CompletionBlock)completionBlock;

+ (unsigned int) smallerDiffFromMarker:(unsigned int)markA toMarker:(unsigned int)markB numMarkers:(unsigned int)num;
+ (float) gaussianFor:(float)x withA:(float)a b:(float)b c:(float)c;

+ (NSString*) versionStringForCurConfig;

// ui frame calculation utilities
+ (CGRect) createCenterFrameWithSize:(CGSize)size inFrame:(CGRect)targetFrame;
+ (CGRect) createCenterFrameWithSize:(CGSize)size inFrame:(CGRect)targetFrame withFrameSize:(CGSize)frameSize;
@end
