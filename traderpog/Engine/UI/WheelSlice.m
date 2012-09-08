//
//  WheelSlice.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 6/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "WheelSlice.h"
#import "WheelBubble.h"
#import "WheelControl.h"
#import <QuartzCore/QuartzCore.h>

@implementation WheelSlice
@synthesize minAngle = _minAngle;
@synthesize midAngle = _midAngle;
@synthesize maxAngle = _maxAngle;
@synthesize index = _index;
@synthesize value = _value;
@synthesize labelView = _labelView;
@synthesize view = _view;

- (id) initWithMin:(float)min mid:(float)mid max:(float)max 
            radius:(float)radius sliceLength:(float)sliceLength
             angle:(float)angle
             index:(unsigned int)index
{
    self = [super init];
    if(self)
    {
        _minAngle = min;
        _midAngle = mid;
        _maxAngle = max;
        _radius = radius;
        _index = index;
        _value = -1;
        _labelView = nil;
        
        // create container view
        CGRect viewRect = CGRectMake(0.0f, 0.0f, sliceLength, 40.0f);
        UIView* newView = [[UIView alloc] initWithFrame:viewRect];
        newView.backgroundColor = [UIColor clearColor];
        newView.layer.anchorPoint = CGPointMake(1.0f, 0.5f);
        
        // view-layer's position is expressed in its super-layer's coordinate system
        // which is the center of the wheel
        newView.layer.position = CGPointMake(_radius, _radius);
        
        // transform starts at negative x-axis and rotates counter-clockwise;
        // that's why it's angle is opposite of the mid,min,max logical angles
        newView.transform = CGAffineTransformMakeRotation(angle * index);
        newView.hidden = YES;
        
        _view = newView;
        _contentBubble = nil;
    }
    return self;
}

#pragma mark - public methods
- (void) wheel:(WheelControl*)wheel setContentBubble:(WheelBubble*)bubble
{
    if(_contentBubble)
    {
        [_contentBubble removeFromSuperview];
        [wheel queueForReuse:_contentBubble];
        _contentBubble = nil;
    }
    if(bubble)
    {
        [_view addSubview:bubble];
        _contentBubble = bubble;
    }
}

- (WheelBubble*) contentBubble
{
    return _contentBubble;
}

@end
