//
//  CircleButton.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/3/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "CircleButton.h"
#import "PogUIUtility.h"
#import <QuartzCore/QuartzCore.h>

static const float kImageInset = 2.0f;

@interface CircleButton ()
{
    SEL _closeSelector;
}
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

- (void) dealloc
{
    [self removeButtonTarget];
}

- (void) setBorderWidth:(float)borderWidth
{
    [[self layer] setBorderWidth:borderWidth];
}

- (void) setBorderColor:(UIColor *)borderColor
{
    [[self layer] setBorderColor:[borderColor CGColor]];
}

- (void) setButtonTarget:(id)target action:(SEL)actionSelector
{
    [self removeButtonTarget];
    [self.button addTarget:target action:actionSelector forControlEvents:UIControlEventTouchUpInside];
    [self.button setEnabled:YES];
    _closeSelector = actionSelector;
}

- (void) removeButtonTarget
{
    if([self.button isEnabled])
    {
        [self.button removeTarget:nil action:_closeSelector forControlEvents:UIControlEventTouchUpInside];
        _closeSelector = nil;
        [self.button setEnabled:NO];
    }
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
    return 2.0f;
}

#pragma mark - internal methods
- (void) setup
{
    // make it a circle
    [PogUIUtility setCircleForView:self
                   withBorderWidth:[CircleButton defaultBorderWidth]
                       borderColor:[CircleButton defaultBorderColor]];
    [self setBackgroundColor:[CircleButton defaultBgColor]];
    
    // add a button that covers the view completely
    self.button = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.button setFrame:self.bounds];
    [self addSubview:self.button];
    [self.button setEnabled:NO];
    _closeSelector = nil;
}

@end
