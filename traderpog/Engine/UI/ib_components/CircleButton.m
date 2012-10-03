//
//  CircleButton.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/3/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "CircleButton.h"
#import "PogUIUtility.h"

static const float kImageInset = 2.0f;

@interface CircleButton ()
- (void) setup;
@end

@implementation CircleButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        [self setup];
    }
    return self;
}

#pragma mark - default values
+ (UIColor*) defaultBgColor
{
    UIColor* result = [UIColor colorWithRed:8.0f/255.0f green:67.0f/255.0f blue:67.0f/255.0f alpha:1.0f];
    return result;
}

+ (UIColor*) defaultBorderColor
{
    UIColor* result = [UIColor colorWithRed:177.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:1.0f];
    return result;
}

+ (float) defaultBorderWidth
{
    return 3.0f;
}

#pragma mark - internal methods
- (void) setup
{
    // make it a circle
    [PogUIUtility setCircleForView:self
                   withBorderWidth:[CircleButton defaultBorderWidth]
                       borderColor:[CircleButton defaultBorderColor]];
    [self setBackgroundColor:[CircleButton defaultBgColor]];
    
    // add an imageView in the middle
    CGRect imageRect = CGRectInset(self.bounds, kImageInset, kImageInset);
    self.imageView = [[UIImageView alloc] initWithFrame:imageRect];
    [self addSubview:self.imageView];
}

@end
