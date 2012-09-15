//
//  LoadingCircle.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/14/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "LoadingCircle.h"
#import "CircleView.h"
#import "ImageManager.h"
#import <QuartzCore/QuartzCore.h>

static const float kRotationSpeed = M_PI * 1.4f;
static const NSInteger kDisplayLinkFrameInterval = 1;
static const CFTimeInterval kDisplayLinkMaxFrametime = 1.0 / 20.0;

static const float kCircleRadiusInWidth = 0.25f;
static const float kCircleVisibleFrac = 0.8f;
static const float kCircleBorderFrac = 0.95f;
static const float kYunOriginXInCircleWidth = 0.2f;
static const float kYunOriginYInCircleHeight = 0.2f;
static const float kYunSizeInCircleWidth = 0.3f;
static const float kYunAlpha = 0.1f;
static const float kLabelWidthInCircleWidth = 0.9f;
static const float kLabelHeightInCircleHeight = 0.25f;

static const float kBorderWidthNotUsed = 0.2f;
static UIColor* kBorderColorNotUsed = nil;

@interface LoadingCircle ()
{
    UIColor* _circleColor;
    UIColor* _borderColor;
    UIImage* _decalImage;
    UIImage* _rotateIcon;
    
    CircleView* _circle;
    UIImageView* _yunView;
    UIImageView* _flyerView;
    UILabel* _circleLabel;
    
    // icon anim
    CGAffineTransform _transformToBorder;
    float _angle;
    CADisplayLink* _displayLink;
    BOOL _displayLinkActive;
    CFTimeInterval _prevTime;
}
- (void) initCircle;
- (void) initIcon;

- (void) startDisplayLink;
- (void) displayUpdate;

@end

@implementation LoadingCircle


- (id) initWithFrame:(CGRect)frame
{
    [NSException raise:NSInternalInconsistencyException
                format:@"Call the initWithFrame:color:borderColor:decalImage method instead"];
    return nil;
}

- (id)initWithFrame:(CGRect)frame
              color:(UIColor*)color
        borderColor:(UIColor*)borderColor
         decalImage:(UIImage*)decalImage
         rotateIcon:(UIImage *)rotateIcon
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _displayLinkActive = NO;
        _circleColor = color;
        _borderColor = borderColor;
        _decalImage = decalImage;
        _rotateIcon = rotateIcon;
        
        [self initCircle];
        [self initIcon];
        
        // step one frame so that all transforms are in place
        [self update:0.0f];
    }
    return self;
}

- (void) startAnim
{
    [self startDisplayLink];
}

- (void) stopAnim
{
    [self stopDisplayLink];
}

#pragma mark - internal

- (void) initCircle
{
    float radius = kCircleRadiusInWidth * self.bounds.size.width;
    float originX = (0.5f * self.bounds.size.width) - radius;
    float originY = self.bounds.size.height - (kCircleVisibleFrac * radius * 2.0f);
    CGRect circleFrame = CGRectMake(originX, originY, radius * 2.0f, radius * 2.0f);
    _circle = [[CircleView alloc] initWithFrame:circleFrame
                                     borderFrac:kCircleBorderFrac
                                    borderWidth:kBorderWidthNotUsed
                                    borderColor:kBorderColorNotUsed];
    _circle.borderCircle.backgroundColor = _borderColor;
    _circle.coloredView.layer.shadowColor = _circleColor.CGColor;
    [self addSubview:_circle];
    
    float yunX = kYunOriginXInCircleWidth * circleFrame.size.width;
    float yunY = kYunOriginYInCircleHeight * circleFrame.size.height;
    float yunSize = kYunSizeInCircleWidth * circleFrame.size.width;
    CGRect yunRect = CGRectMake(yunX, yunY, yunSize, yunSize);
    _yunView = [[UIImageView alloc] initWithFrame:yunRect];
    [_yunView setImage:_decalImage];
    [_yunView setAlpha:kYunAlpha];
    [_circle addSubview:_yunView];
    
    // label
    float labelWidth = kLabelWidthInCircleWidth * circleFrame.size.width;
    float labelHeight = kLabelHeightInCircleHeight * circleFrame.size.height;
    CGRect labelFrame = CGRectMake(0.5f * (circleFrame.size.width - labelWidth),
                                   (0.5f * ((circleFrame.size.height * (1.0f + kCircleVisibleFrac)/2.0f) - labelHeight)),
                                   labelWidth, labelHeight);
    _circleLabel = [[UILabel alloc] initWithFrame:labelFrame];
    [_circleLabel setFont:[UIFont fontWithName:@"Marker Felt" size:25.0f]];
    [_circleLabel setAdjustsFontSizeToFitWidth:YES];
    [_circleLabel setText:@"loading"];
    [_circleLabel setTextColor:[UIColor whiteColor]];
    [_circleLabel setTextAlignment:UITextAlignmentCenter];
    [_circleLabel setBackgroundColor:[UIColor clearColor]];
    [_circle addSubview:_circleLabel];
}

static const float kFlyerSizeInCircleWidth = 0.5f;
- (void) initIcon
{
    float flyerSize = _circle.bounds.size.width * kFlyerSizeInCircleWidth;
    float centerX = (_circle.bounds.size.width * 0.5f) - (0.5f * flyerSize);
    float centerY = (_circle.bounds.size.height * 0.5f) - (0.5f * flyerSize);
    CGRect flyerRect = CGRectMake(centerX, centerY, flyerSize, flyerSize);
    _flyerView = [[UIImageView alloc] initWithFrame:flyerRect];
    [_flyerView setImage:_rotateIcon];
    [_circle addSubview:_flyerView];
    
    CGAffineTransform orient = CGAffineTransformMakeRotation(-M_PI_2);
    CGAffineTransform t = CGAffineTransformMakeTranslation(0.0f, 0.5f * _circle.bounds.size.width);
    _transformToBorder = CGAffineTransformConcat(orient, t);
    _angle = 0.0f;
}

- (void) startDisplayLink
{
    if(!_displayLinkActive)
    {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayUpdate)];
        [_displayLink setFrameInterval:kDisplayLinkFrameInterval];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        _displayLinkActive = YES;
        _prevTime = 0.0f;
    }
}

- (void) stopDisplayLink
{
    if(_displayLinkActive)
    {
        [_displayLink invalidate];
        _displayLink = nil;
        _displayLinkActive = NO;
    }
}


- (void) displayUpdate
{
    CFTimeInterval displayElapsed = 0.0;
    
    // update time
    if(_prevTime > 0.0)
    {
        displayElapsed = [_displayLink timestamp] - _prevTime;
    }
    else
    {
        displayElapsed = [_displayLink timestamp];
    }
    _prevTime = [_displayLink timestamp];
    if(displayElapsed > kDisplayLinkMaxFrametime)
    {
        displayElapsed = kDisplayLinkMaxFrametime;
    }
    
    [self update:displayElapsed];
}


- (void) update:(NSTimeInterval)elapsed
{
    _angle += (elapsed * kRotationSpeed);
    if(_angle >= (2.0f * M_PI))
    {
        _angle = 0.0f;
    }
    CGAffineTransform rotate = CGAffineTransformMakeRotation(_angle);
    CGAffineTransform transform = CGAffineTransformConcat(_transformToBorder, rotate);
    [_flyerView setTransform:transform];
}

@end
