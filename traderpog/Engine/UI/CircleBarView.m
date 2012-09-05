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
@synthesize borderColor = _borderColor;
@synthesize borderWidth = _borderWidth;
@synthesize textSize = _textSize;
@synthesize barHeightFrac = _barHeightFrac;
@synthesize hasRoundCorner = _hasRoundCorner;

- (id)initWithFrame:(CGRect)frame
              color:(UIColor*)color
          textColor:(UIColor*)colorForText
        borderColor:(UIColor*)colorForBorder
        borderWidth:(float)widthForBorder
           textSize:(float)sizeForText
      barHeightFrac:(float)heightFracForBar
     hasRoundCorner:(BOOL)roundCorner
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _barColor = color;
        _textColor = colorForText;
        _borderColor = colorForBorder;
        _borderWidth = widthForBorder;
        _textSize = sizeForText;
        _barHeightFrac = heightFracForBar;
        _hasRoundCorner = roundCorner;
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

static const float kLeftCircleSizeFrac = 0.34f;
static const float kRightBarWidthFrac = 1.0f - (0.5f * kLeftCircleSizeFrac);

#pragma mark - internal methods
- (void) createLayout
{
    // setup my frame's size and offset origin so that origin of frame is at
    // center of left-circle
    CGRect myFrame = self.frame;
    float leftCircleSize = kLeftCircleSizeFrac * myFrame.size.width;
    float rightBarWidth = kRightBarWidthFrac * myFrame.size.width;
    float rightBarHeight = [self barHeightFrac] * myFrame.size.height;
    CGPoint kRightBarOrigin = CGPointMake(0.5f * leftCircleSize,
                                          0.5f * (leftCircleSize - rightBarHeight));
    myFrame.size = CGSizeMake(leftCircleSize + (rightBarWidth - kRightBarOrigin.x),
                                 leftCircleSize);
    myFrame.origin = CGPointMake(myFrame.origin.x - (0.5f * leftCircleSize),
                                 myFrame.origin.y - (0.5f * leftCircleSize));
    self.frame = myFrame;
    
    // right bar
    CGRect barFrame = CGRectMake(0.5f * leftCircleSize,
                                 0.5f * (leftCircleSize - rightBarHeight),
                                 rightBarWidth,
                                 rightBarHeight);
    self.rightBar = [[UIView alloc] initWithFrame:barFrame];
    [self.rightBar setBackgroundColor:[self barColor]];
    [PogUIUtility setBorderOnView:[self rightBar] width:[self borderWidth] color:[self borderColor]];
    if([self hasRoundCorner])
    {
        [PogUIUtility setRoundCornersForView:[self rightBar]];
    }
    [self addSubview:[self rightBar]];
    
    // label (subview of rightbar)
    CGRect labelFrame = CGRectMake(0.45f * leftCircleSize, 0.0f,
                                   rightBarWidth - (0.55f * leftCircleSize),
                                   rightBarHeight);
    self.label = [[UILabel alloc] initWithFrame:labelFrame];
    [self.rightBar addSubview:[self label]];
    [self.label setFont:[UIFont fontWithName:@"Marker Felt" size:[self textSize]]];
    [self.label setTextColor:[self textColor]];
    [self.label setBackgroundColor:[UIColor clearColor]];
    [self.label setAdjustsFontSizeToFitWidth:YES];
    [self.label setTextAlignment:UITextAlignmentRight];

    // left circle
    CGRect circleFrame = CGRectMake(0.0f, 0.0f, leftCircleSize, leftCircleSize);
    self.leftCircle = [[UIView alloc] initWithFrame:circleFrame];
    [self.leftCircle setBackgroundColor:[UIColor whiteColor]];
    [PogUIUtility setCircleForView:[self leftCircle]
                   withBorderWidth:[self borderWidth]
                       borderColor:[self borderColor]];
    [self addSubview:[self leftCircle]];
}

@end
