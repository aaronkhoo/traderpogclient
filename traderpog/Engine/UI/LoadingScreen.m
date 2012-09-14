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

@interface LoadingScreen ()
{
    CircleView* _circle;
    UIImageView* _yunView;
}
- (void) initBackgroundColor;
- (void) initCircle;
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
}

- (void)viewDidUnload
{
    _bigLabel = nil;
    _progressLabel = nil;
    _activityIndicator = nil;
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
@end
