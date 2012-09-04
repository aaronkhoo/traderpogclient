//
//  WheelBubble.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 6/30/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "WheelBubble.h"

@implementation WheelBubble
@synthesize labelView = _labelView;
@synthesize imageView = _imageView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        [self setBackgroundColor:[UIColor clearColor]];
        _labelView = [[UILabel alloc] initWithFrame:[self bounds]];
        [_labelView setTextAlignment:UITextAlignmentCenter];
        
        _imageView = [[UIImageView alloc] initWithFrame:[self bounds]];
        [_imageView setBackgroundColor:[UIColor clearColor]];
        [self addSubview:_imageView];
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
