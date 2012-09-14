//
//  LoadingScreen.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "LoadingScreen.h"
#import "CircleView.h"
#import "GameColors.h"
#import "ImageManager.h"
#import <QuartzCore/QuartzCore.h>

static const float kRotationSpeed = M_PI * 1.4f;
static const NSInteger kDisplayLinkFrameInterval = 1;
static const CFTimeInterval kDisplayLinkMaxFrametime = 1.0 / 20.0;

@interface LoadingScreen ()
{
    CircleView* _circle;
    UIImageView* _yunView;
    UIImageView* _flyerView;
    
    // flyer anim
    CGAffineTransform _transformToBorder;
    float _angle;
    CADisplayLink* _displayLink;
    BOOL _displayLinkActive;
    CFTimeInterval _prevTime;
}
- (void) initBackgroundColor;
- (void) initCircle;
- (void) initFlyer;

- (void) startDisplayLink;
- (void) displayUpdate;
- (void) update:(NSTimeInterval)elapsed;
@end

@implementation LoadingScreen
@synthesize bigLabel = _bigLabel;
@synthesize progressLabel = _progressLabel;
@synthesize activityIndicator = _activityIndicator;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initBackgroundColor];
    [self initCircle];
    [self initFlyer];
    [self startDisplayLink];
}

- (void)viewDidUnload
{
    [self stopDisplayLink];
    _bigLabel = nil;
    _progressLabel = nil;
    _activityIndicator = nil;
    _flyerView = nil;
    _yunView = nil;
    _circle = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - internal methods
- (void) initBackgroundColor
{
    [self.view setBackgroundColor:[UIColor colorWithRed:237.0f/255.0f green:28.0f/255.0f blue:36.0f/255.0f alpha:1.0f]];
}

static const float kCircleRadiusInWidth = 0.25f;
static const float kCircleVisibleFrac = 0.8f;
static const float kCircleBorderFrac = 0.95f;
static const float kYunOriginXInCircleWidth = 0.2f;
static const float kYunOriginYInCircleHeight = 0.2f;
static const float kYunSizeInCircleWidth = 0.3f;
static const float kYunAlpha = 0.1f;

static const float kBorderWidthNotUsed = 0.2f;
static UIColor* kBorderColorNotUsed = nil;

- (void) initCircle
{
    float radius = kCircleRadiusInWidth * self.view.bounds.size.width;
    float originX = (0.5f * self.view.bounds.size.width) - radius;
    float originY = self.view.bounds.size.height - (kCircleVisibleFrac * radius * 2.0f);
    CGRect circleFrame = CGRectMake(originX, originY, radius * 2.0f, radius * 2.0f);
    _circle = [[CircleView alloc] initWithFrame:circleFrame
                                     borderFrac:kCircleBorderFrac
                                    borderWidth:kBorderWidthNotUsed
                                    borderColor:kBorderColorNotUsed];
    UIColor* circleColor = [GameColors bubbleColorScanWithAlpha:1.0f];
    _circle.borderCircle.backgroundColor = [GameColors borderColorScanWithAlpha:1.0f];
    _circle.coloredView.layer.shadowColor = circleColor.CGColor;
    [self.view addSubview:_circle];
    
    float yunX = kYunOriginXInCircleWidth * circleFrame.size.width;
    float yunY = kYunOriginYInCircleHeight * circleFrame.size.height;
    float yunSize = kYunSizeInCircleWidth * circleFrame.size.width;
    CGRect yunRect = CGRectMake(yunX, yunY, yunSize, yunSize);
    _yunView = [[UIImageView alloc] initWithFrame:yunRect];
    UIImage* yunImage = [[ImageManager getInstance] getImage:@"icon_yun.png"
                                               fallbackNamed:@"icon_yun.png"
                                                   withColor:[GameColors bubbleColorScanWithAlpha:1.0f]];
    [_yunView setImage:yunImage];
    [_yunView setAlpha:kYunAlpha];
    [_circle addSubview:_yunView];
}

static const float kFlyerSizeInCircleWidth = 0.5f;
- (void) initFlyer
{
    float flyerSize = _circle.bounds.size.width * kFlyerSizeInCircleWidth;
    float centerX = (_circle.bounds.size.width * 0.5f) - (0.5f * flyerSize);
    float centerY = (_circle.bounds.size.height * 0.5f) - (0.5f * flyerSize);
    CGRect flyerRect = CGRectMake(centerX, centerY, flyerSize, flyerSize);
    _flyerView = [[UIImageView alloc] initWithFrame:flyerRect];
    UIImage* image = [[ImageManager getInstance] getImage:@"flyer.png" fallbackNamed:@"flyer.png"];
    [_flyerView setImage:image];
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
