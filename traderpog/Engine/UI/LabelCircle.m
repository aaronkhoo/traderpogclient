//
//  LabelCircle.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/4/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "LabelCircle.h"
#import "PogUIUtility.h"
#import <QuartzCore/QuartzCore.h>

@implementation LabelCircle
@synthesize label;

- (id) initWithFrame:(CGRect)frame
         borderWidth:(CGFloat)borderWidth
         borderColor:(UIColor*)borderColor
             bgColor:(UIColor*)bgColor
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = bgColor;
        self.layer.masksToBounds = YES;
        [PogUIUtility setCircleForView:self withBorderWidth:borderWidth borderColor:borderColor];
        
        self.label = [[UILabel alloc] initWithFrame:[self bounds]];
        [self.label setBackgroundColor:[UIColor clearColor]];
        [self.label setFont:[UIFont fontWithName:@"Marker Felt" size:20.0f]];
        [self.label setTextAlignment:UITextAlignmentCenter];
        [self.label setTextColor:[UIColor whiteColor]];
        [self.label setAdjustsFontSizeToFitWidth:YES];
        [self addSubview:[self label]];
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
