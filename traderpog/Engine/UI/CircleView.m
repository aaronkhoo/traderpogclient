//
//  CircleView.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/4/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "CircleView.h"
#import <QuartzCore/QuartzCore.h>

@implementation CircleView

- (id)initWithFrame:(CGRect)frame
        borderWidth:(CGFloat)borderWidth
        borderColor:(UIColor*)borderColor
{
    self = [super initWithFrame:frame];
    if (self)
    {
        CGPoint circleCenter = CGPointMake(self.bounds.origin.x + (self.bounds.size.width * 0.5f),
                                           self.bounds.origin.y + (self.bounds.size.height * 0.5f));
        UIBezierPath* circlePath = [UIBezierPath bezierPathWithArcCenter:circleCenter
                                                                  radius:self.bounds.size.width * 0.49f
                                                              startAngle:0.0f
                                                                endAngle:2.0f * M_PI
                                                               clockwise:YES];
        self.backgroundColor = [UIColor blackColor];
        self.layer.shadowOpacity = 1.0f;
        self.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
        self.layer.shadowRadius = 3.0f;
        self.layer.masksToBounds = NO;
        [self.layer setShadowPath:circlePath.CGPath];
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
