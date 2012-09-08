//
//  CircleView.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/4/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "CircleView.h"
#import "PogUIUtility.h"
#import <QuartzCore/QuartzCore.h>

static const float kBorderCircleSmallScale = 0.75f;
static const float kBorderCircleBigScale = 0.8f;
static const NSTimeInterval kBorderCircleAnimDuration = 0.2f;

@implementation CircleView
@synthesize coloredView;
@synthesize borderCircle;
@synthesize centerBg;
// 9, 1, 51
- (id)initWithFrame:(CGRect)frame
         borderFrac:(float)borderFrac
        borderWidth:(CGFloat)borderWidth
        borderColor:(UIColor*)borderColor
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];

        self.borderCircle = [[UIView alloc] initWithFrame:[self bounds]];
        [self.borderCircle setBackgroundColor:[UIColor clearColor]];
        [PogUIUtility setCircleForView:[self borderCircle] withBorderWidth:0.0f borderColor:[UIColor clearColor]];
        [self addSubview:[self borderCircle]];

        float coloredSize = borderFrac * frame.size.width;
        CGRect centerRect = CGRectMake(0.5f * (frame.size.width - coloredSize),
                                        0.5f * (frame.size.width - coloredSize),
                                        coloredSize, coloredSize);
        self.centerBg = [[UIView alloc] initWithFrame:centerRect];
        [self.centerBg setBackgroundColor:[UIColor colorWithRed:9.0f/255.0f green:1.0f/255.0f blue:51.0f/255.0f alpha:1.0f]];
        [self addSubview:[self centerBg]];
        [PogUIUtility setCircleForView:[self centerBg] withBorderWidth:0.0f borderColor:[UIColor clearColor]];

        CGRect coloredRect = CGRectMake(0.0f, 0.0f,
                                        coloredSize, coloredSize);
        self.coloredView = [[UIView alloc] initWithFrame:coloredRect];
        [self.coloredView setBackgroundColor:[UIColor clearColor]];
        
        CGPoint circleCenter = CGPointMake((coloredRect.size.width * 0.5f),
                                           (coloredRect.size.height * 0.5f));
        UIBezierPath* circlePath = [UIBezierPath bezierPathWithArcCenter:circleCenter
                                                                  radius:coloredRect.size.width * 0.48f
                                                              startAngle:0.0f
                                                                endAngle:2.0f * M_PI
                                                               clockwise:YES];
        self.coloredView.layer.shadowOpacity = 1.0f;
        self.coloredView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        self.coloredView.layer.shadowRadius = 4.0f;
        self.coloredView.layer.masksToBounds = NO;
        [self.coloredView.layer setShadowPath:circlePath.CGPath];
        [self.centerBg addSubview:[self coloredView]];
    }
    return self;
}

- (void) showBigBorder
{
    CGAffineTransform t = CGAffineTransformMakeScale(kBorderCircleBigScale, kBorderCircleBigScale);
    [UIView animateWithDuration:kBorderCircleAnimDuration
                     animations:^(void){
                         [self.borderCircle setTransform:t];
                     }];
}

- (void) showSmallBorder
{
    CGAffineTransform t = CGAffineTransformMakeScale(kBorderCircleSmallScale, kBorderCircleSmallScale);
    [UIView animateWithDuration:kBorderCircleAnimDuration
                     animations:^(void){
                         [self.borderCircle setTransform:t];
                     }];    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
