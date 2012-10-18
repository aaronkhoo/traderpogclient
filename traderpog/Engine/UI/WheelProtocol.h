//
//  WheelProtocol.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 6/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WheelBubble;
@class WheelControl;
@protocol WheelProtocol <NSObject>
- (void) wheel:(WheelControl*)wheel didMoveTo:(unsigned int)index;
- (void) wheel:(WheelControl*)wheel didSettleAt:(unsigned int)index;
- (void) wheel:(WheelControl*)wheel didPressOkOnIndex:(unsigned int)index;
- (void) wheel:(WheelControl*)wheel didPressCloseOnIndex:(unsigned int)index;
- (void) wheel:(WheelControl*)wheel willShowAtIndex:(unsigned int)index;
- (void) wheel:(WheelControl*)wheel willHideAtIndex:(unsigned int)index;
@end

@protocol WheelDataSource <NSObject>
- (unsigned int) numItemsInWheel:(WheelControl*)wheel;
- (WheelBubble*) wheel:(WheelControl*)wheel bubbleAtIndex:(unsigned int)index;
- (UIView*) wheel:(WheelControl*)wheel previewContentInitAtIndex:(unsigned int)index;
@optional
- (UIColor*) previewColorForWheel:(WheelControl*)wheel;
- (UIColor*) previewBorderColorForWheel:(WheelControl*)wheel;
- (UIColor*) previewButtonColorForWheel:(WheelControl*)wheel;
- (UIColor*) previewButtonBorderColorForWheel:(WheelControl*)wheel;
- (CGRect) previewImageFrameForWheel:(WheelControl*)wheel inParentFrame:(CGRect)parentCircleFrame;
@end
