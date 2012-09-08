//
//  KnobSlice.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "KnobSlice.h"
#import "PogUIUtility.h"
#import <QuartzCore/QuartzCore.h>

static const float kSliceTextSmallScale = 0.3f;
static const float kSliceTextBigScale = 0.8f;
static const float kSliceTextPopoutScale = 0.55f;

@interface KnobSlice ()
{
    UIView* _contentContainer;
    UILabel* _contentLabel;
    UIView* _popoutCircle;
    UIView* _popoutShadow;
    CGAffineTransform _labelTransformSmall;
    CGAffineTransform _labelTransformBig;
    CGAffineTransform _labelTransformPopout;
    CGAffineTransform _decalTransformPopout;
    CGAffineTransform _decalTransformBig;
    CGAffineTransform _popoutTransformIdle;
    CGAffineTransform _popoutTransformOut;
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

        // popout circle
        CGRect popoutRect = CGRectMake(0.0f, 0.0f, _radius, _radius);
        popoutRect = CGRectInset(popoutRect, -2.0f, -2.0f);
        _popoutShadow = [[UIView alloc] initWithFrame:popoutRect];
        [_popoutShadow setBackgroundColor:[UIColor clearColor]];
        [PogUIUtility setCircleForView:_popoutShadow withBorderWidth:0.0f borderColor:[UIColor clearColor]];
        _popoutShadow.layer.masksToBounds = NO;
        _popoutShadow.layer.shadowColor = [UIColor colorWithRed:9.0f/255.0f green:1.0f/255.0f blue:51.0f/255.0f alpha:1.0f].CGColor;
        _popoutShadow.layer.shadowOpacity = 0.4f;
        _popoutShadow.layer.shadowOffset = CGSizeMake(4.0f, 8.0f);
        _popoutCircle = [[UIView alloc] initWithFrame:popoutRect];
        [_popoutCircle setBackgroundColor:[UIColor grayColor]];
        [PogUIUtility setCircleForView:_popoutCircle withBorderWidth:3.0f borderColor:[UIColor darkGrayColor]];
        [_popoutShadow addSubview:_popoutCircle];
        [_contentContainer addSubview:_popoutShadow];
        
        CGRect labelRect = CGRectInset(contentRect, -55.0f, -25.0f);

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
        _labelTransformBig = CGAffineTransformMakeScale(kSliceTextBigScale, kSliceTextBigScale);
        _labelTransformBig = CGAffineTransformTranslate(_labelTransformBig, 0.0f, labelRect.size.height * 0.2f);
        _labelTransformSmall = CGAffineTransformMakeScale(kSliceTextSmallScale, kSliceTextSmallScale);
        _decalTransformBig = CGAffineTransformIdentity;
        _popoutTransformIdle = CGAffineTransformMakeScale(0.5f, 0.5f);

        // popout
        _labelTransformPopout = CGAffineTransformMakeScale(kSliceTextPopoutScale, kSliceTextPopoutScale);
        _labelTransformPopout = CGAffineTransformTranslate(_labelTransformPopout, 0.0f, -popoutRect.size.height * 1.9f);
        _popoutTransformOut = CGAffineTransformMakeScale(1.0f, 1.0f);
        _popoutTransformOut = CGAffineTransformTranslate(_popoutTransformOut, 0.0f, -popoutRect.size.height * 1.3f);
        _decalTransformPopout = CGAffineTransformMakeScale(kSliceTextPopoutScale, kSliceTextPopoutScale);
        _decalTransformPopout = CGAffineTransformTranslate(_decalTransformPopout, 0.0f, -popoutRect.size.height * 2.0f);
        
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
//    [_contentLabel setTextColor:color];
    [_contentLabel setTransform:_labelTransformBig];
    [_decal setTransform:_decalTransformBig];
    [_popoutShadow setTransform:_popoutTransformIdle];
    [_popoutShadow setAlpha:0.0f];
    [_popoutCircle setBackgroundColor:[UIColor grayColor]];
    [[_popoutCircle layer] setBorderColor:[UIColor darkGrayColor].CGColor];
}

- (void) useSmallText
{
    [_contentLabel setTransform:_labelTransformSmall];
    [_decal setTransform:_decalTransformPopout];
    [_decal setAlpha:0.5];
}

- (void) usePopoutWithColor:(UIColor *)color borderColor:(UIColor *)borderColor
{
//    [_contentLabel setTextColor:color];
    [_contentLabel setTransform:_labelTransformPopout];
    [_decal setTransform:_decalTransformPopout];
    [_popoutShadow setTransform:_popoutTransformOut];
    [_popoutShadow setAlpha:1.0f];
    [_popoutCircle setBackgroundColor:color];
    [[_popoutCircle layer] setBorderColor:borderColor.CGColor];
}

@end
