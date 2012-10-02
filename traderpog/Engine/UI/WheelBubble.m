//
//  WheelBubble.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 6/30/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "WheelBubble.h"

@implementation WheelBubble
@synthesize imageView = _imageView;
@synthesize exclamationView = _exclamationView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        [self setBackgroundColor:[UIColor clearColor]];
        
        _imageView = [[UIImageView alloc] initWithFrame:[self bounds]];
        [_imageView setBackgroundColor:[UIColor clearColor]];
        [self addSubview:_imageView];
        
        CGRect exRect = CGRectMake(0.0f, -(0.5f * self.bounds.size.height),
                                   self.bounds.size.width, self.bounds.size.height);
        _exclamationView = [[UIImageView alloc] initWithFrame:exRect];
        [_exclamationView setBackgroundColor:[UIColor clearColor]];
        [_exclamationView setHidden:YES];
        [self addSubview:_exclamationView];
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
