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


@implementation CircleView
@synthesize coloredView;

- (id)initWithFrame:(CGRect)frame
        borderWidth:(CGFloat)borderWidth
        borderColor:(UIColor*)borderColor
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:1.0f];
        self.layer.masksToBounds = YES;
        [PogUIUtility setCircleForView:self withBorderWidth:borderWidth borderColor:borderColor];

        self.coloredView = [[UIView alloc] initWithFrame:frame];
        [self.coloredView setBackgroundColor:[UIColor clearColor]];
        
        CGPoint circleCenter = CGPointMake(self.bounds.origin.x + (self.bounds.size.width * 0.5f),
                                           self.bounds.origin.y + (self.bounds.size.height * 0.5f));
        UIBezierPath* circlePath = [UIBezierPath bezierPathWithArcCenter:circleCenter
                                                                  radius:self.bounds.size.width * 0.46f
                                                              startAngle:0.0f
                                                                endAngle:2.0f * M_PI
                                                               clockwise:YES];
        self.coloredView.layer.shadowOpacity = 1.0f;
        self.coloredView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        self.coloredView.layer.shadowRadius = 2.0f;
        self.coloredView.layer.masksToBounds = NO;
        [self.coloredView.layer setShadowPath:circlePath.CGPath];
        
        [self addSubview:[self coloredView]];
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

@end
