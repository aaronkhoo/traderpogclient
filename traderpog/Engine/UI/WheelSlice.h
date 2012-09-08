//
//  WheelSlice.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 6/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WheelBubble;
@class WheelControl;
@interface WheelSlice : NSObject
{
    float _minAngle;
    float _midAngle;
    float _maxAngle;
    float _radius;
    unsigned int _index;
    int _value;
    UILabel* _labelView;
    UIView* _view;              // the container view that spans from perimeter to center
    WheelBubble* _contentBubble;
}
@property (nonatomic) float minAngle;
@property (nonatomic) float midAngle;
@property (nonatomic) float maxAngle;
@property (nonatomic) unsigned int index;
@property (nonatomic) int value;
@property (nonatomic,strong) UILabel* labelView;
@property (nonatomic,readonly) UIView* view;
- (id) initWithMin:(float)min mid:(float)mid max:(float)max 
            radius:(float)radius sliceLength:(float)sliceLength
             angle:(float)angle
             index:(unsigned int)index;

- (void) wheel:(WheelControl*)wheel setContentBubble:(WheelBubble*)bubble;
- (WheelBubble*) contentBubble;
@end
