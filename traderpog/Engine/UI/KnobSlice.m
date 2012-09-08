//
//  KnobSlice.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "KnobSlice.h"
#import <QuartzCore/QuartzCore.h>

static const float kSliceTextSmallScale = 0.3f;
static const float kSliceTextBigScale = 0.7f;
static const float kSliceTextPopoutScale = 1.0f;

@interface KnobSlice ()
{
    UIView* _contentContainer;
    UILabel* _contentLabel;
    CGAffineTransform _labelTransformSmall;
    CGAffineTransform _labelTransformBig;
    CGAffineTransform _labelTransformPopout;
    CGAffineTransform _decalTransformSmall;
    CGAffineTransform _decalTransformBig;
}
@end

@implementation KnobSlice
@synthesize view = _view;
@synthesize minAngle = _minAngle;
@synthesize midAngle = _midAngle;
@synthesize maxAngle = _maxAngle;
@synthesize decal = _decal;

- (id) initWithMin:(float)min mid:(float)mid max:(float)max 
            radius:(float)radius angle:(float)angle
             index:(unsigned int)index
{
    self = [super init];
    if(self)
    {
        _minAngle = min;
        _midAngle = mid;
        _maxAngle = max;
        _radius = radius;
        
        // create slice view
        CGRect viewRect = CGRectMake(0.0f, 0.0f, _radius, 40.0f);
        UIView* newView = [[UIView alloc] initWithFrame:viewRect];
        newView.backgroundColor = [UIColor clearColor];
        newView.layer.anchorPoint = CGPointMake(1.0f, 0.5f);
        
        // view-layer's position is expressed in its super-layer's coordinate system
        // which is the center of the wheel
        newView.layer.position = CGPointMake(_radius, _radius);
        
        // transform starts at negative x-axis and rotates counter-clockwise;
        // that's why it's angle is opposite of the mid,min,max logical angles
        newView.transform = CGAffineTransformMakeRotation(angle * index);
        
        _view = newView;   
        
        // create content-container that is attached to the outer edge of the container and oriented
        // such that it is horizontal when the container view is pointing up
        CGRect contentRect = CGRectMake(0.0f, 0.0f, _radius, 40.0f);
        UIView* newContainer = [[UIView alloc] initWithFrame:contentRect];
        newContainer.layer.position = CGPointMake(contentRect.size.width * 0.4f, contentRect.size.height * 0.5f);
        newContainer.backgroundColor = [UIColor clearColor];
        CGAffineTransform contentTransform = CGAffineTransformMakeRotation(-M_PI_2);
        newContainer.transform = contentTransform;
        [_view addSubview:newContainer];
        _contentContainer = newContainer;

        CGRect labelRect = CGRectInset(contentRect, -55.0f, -25.0f);//-15.0f, -15.0f);

        // decal
        CGRect decalRect = CGRectMake(0.0f, 0.0f,
                                      labelRect.size.height,
                                      labelRect.size.height);
        _decal = [[UIImageView alloc] initWithFrame:decalRect];
        [_decal setBackgroundColor:[UIColor clearColor]];
        [_contentContainer addSubview:_decal];

        // label
        UILabel* sliceLabel = [[UILabel alloc] initWithFrame:labelRect];
        [sliceLabel setTextAlignment:UITextAlignmentCenter];
        [sliceLabel setFont:[UIFont fontWithName:@"Marker Felt" size:55.0f]];
        [sliceLabel setBackgroundColor:[UIColor clearColor]];
        [sliceLabel setTextColor:[UIColor whiteColor]];
        [_contentContainer addSubview:sliceLabel];
        _contentLabel = sliceLabel;
        
        // setup preset transforms for text label
        _labelTransformPopout = CGAffineTransformMakeScale(kSliceTextPopoutScale, kSliceTextPopoutScale);
        _labelTransformPopout = CGAffineTransformTranslate(_labelTransformPopout, 0.0f, -labelRect.size.height * 0.8f);
        _labelTransformBig = CGAffineTransformMakeScale(kSliceTextBigScale, kSliceTextBigScale);
        _labelTransformBig = CGAffineTransformTranslate(_labelTransformBig, 0.0f, labelRect.size.height * 0.2f);
        _labelTransformSmall = CGAffineTransformMakeScale(kSliceTextSmallScale, kSliceTextSmallScale);
        _decalTransformBig = CGAffineTransformIdentity;
        _decalTransformSmall = CGAffineTransformMakeScale(kSliceTextSmallScale, kSliceTextSmallScale);
        _decalTransformSmall = CGAffineTransformTranslate(_decalTransformSmall, 0.0f, -labelRect.size.height * 0.2f);
        
        // init all slices as small (Knob will make them big when selected)
        [self useSmallText];
    }
    return self;
}

- (void) setText:(NSString *)text
{
    [_contentLabel setText:text];
}

- (void) useBigTextWithColor:(UIColor *)color
{
    [_contentLabel setTextColor:color];
    [_contentLabel setTransform:_labelTransformBig];
    [_decal setTransform:_decalTransformBig];
}

- (void) useSmallText
{
    [_contentLabel setTransform:_labelTransformSmall];
    [_decal setTransform:_decalTransformSmall];
    [_decal setAlpha:0.5];
}

- (void) usePopoutTextWithColor:(UIColor *)color
{
    [_contentLabel setTextColor:color];
    [_contentLabel setTransform:_labelTransformPopout];
    [_decal setTransform:_decalTransformSmall];
}

@end
