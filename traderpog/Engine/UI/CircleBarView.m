//
//  CircleBarView.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/3/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "CircleBarView.h"
#import "PogUIUtility.h"

@interface CircleBarView ()
- (void) createLayout;
@end

@implementation CircleBarView
@synthesize leftCircle = _leftCircle;
@synthesize rightBar = _rightBar;
@synthesize label = _label;
@synthesize barColor = _barColor;
@synthesize textColor = _textColor;

- (id)initWithFrame:(CGRect)frame color:(UIColor*)color textColor:(UIColor*)colorForText
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _barColor = color;
        _textColor = colorForText;
        [self createLayout];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

static const float kLeftCircleSize = 17.0f * 1.3f;
static const float kRightBarSizeWidth = 40.0f * 1.3f;
static const float kRightBarSizeHeight = 12.0f * 1.3f;
static const float kLeftCircleBorderWidth = 1.2f;
static const float kLabelFontSize = 15.0f;

#pragma mark - internal methods
- (void) createLayout
{
    // setup my frame's size and offset origin so that origin of frame is at
    // center of left-circle
    CGRect myFrame = self.frame;
    CGPoint kRightBarOrigin = CGPointMake(0.5f * kLeftCircleSize,
                                          0.5f * (kLeftCircleSize - kRightBarSizeHeight));
    myFrame.size = CGSizeMake(kLeftCircleSize + (kRightBarSizeWidth - kRightBarOrigin.x),
                                 kLeftCircleSize);
    myFrame.origin = CGPointMake(myFrame.origin.x - (0.5f * kLeftCircleSize),
                                 myFrame.origin.y - (0.5f * kLeftCircleSize));
    self.frame = myFrame;
    
    // right bar
    CGRect barFrame = CGRectMake(0.5f * kLeftCircleSize,
                                 0.5f * (kLeftCircleSize - kRightBarSizeHeight),
                                 kRightBarSizeWidth,
                                 kRightBarSizeHeight);
    self.rightBar = [[UIView alloc] initWithFrame:barFrame];
    [self.rightBar setBackgroundColor:[self barColor]];
    [self addSubview:[self rightBar]];
    
    // label (subview of rightbar)
    CGRect labelFrame = CGRectMake(0.45f * kLeftCircleSize, 0.0f,
                                   kRightBarSizeWidth - (0.55f * kLeftCircleSize),
                                   kRightBarSizeHeight);
    self.label = [[UILabel alloc] initWithFrame:labelFrame];
    [self.rightBar addSubview:[self label]];
    [self.label setFont:[UIFont fontWithName:@"Marker Felt" size:kLabelFontSize]];
    [self.label setTextColor:[self textColor]];
    [self.label setBackgroundColor:[UIColor clearColor]];
    [self.label setAdjustsFontSizeToFitWidth:YES];
    [self.label setTextAlignment:UITextAlignmentRight];

    // left circle
    CGRect circleFrame = CGRectMake(0.0f, 0.0f, kLeftCircleSize, kLeftCircleSize);
    self.leftCircle = [[UIView alloc] initWithFrame:circleFrame];
    [self.leftCircle setBackgroundColor:[UIColor whiteColor]];
    [PogUIUtility setCircleForView:[self leftCircle]
                   withBorderWidth:kLeftCircleBorderWidth
                       borderColor:[self barColor]];
    [self addSubview:[self leftCircle]];
}

@end
