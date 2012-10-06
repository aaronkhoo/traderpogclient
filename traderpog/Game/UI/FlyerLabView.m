//
//  FlyerLabView.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/5/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerLabView.h"
#import "PogUIUtility.h"
#import "GameColors.h"
#import "CircleButton.h"

NSString* const kFlyerLabViewReuseIdentifier = @"FlyerLabView";
static const float kBorderWidth = 6.0f;
static const float kBuyCircleBorderWidth = 6.0f;
static const float kBorderCornerRadius = 8.0f;


@implementation FlyerLabView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        [[NSBundle mainBundle] loadNibNamed:@"FlyerLabView" owner:self options:nil];
        [PogUIUtility setBorderOnView:self.contentView
                                width:kBorderWidth
                                color:[GameColors borderColorScanWithAlpha:1.0f]
                         cornerRadius:kBorderCornerRadius];
        [self.closeCircle setBorderColor:[GameColors borderColorScanWithAlpha:1.0f]];
        [self addSubview:self.nibView];
        [self setBackgroundColor:[UIColor clearColor]];
        [self setClipsToBounds:NO];
    }
    return self;
}

- (void) dealloc
{
    [self removeButtonTargets];
}

- (void) addButtonTarget:(id)target
{
    if([target respondsToSelector:@selector(handleFlyerLabClose:)])
    {
        [self.closeButton addTarget:target action:@selector(handleFlyerLabClose:) forControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
        NSLog(@"Error: ItemBuyView button target must respond to handleFlyerLabClose:");
    }
}

#pragma mark - internal methods
- (void) removeButtonTargets
{
    [self.closeButton removeTarget:nil action:@selector(handleFlyerLabClose:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - ViewReuseDelegate
- (NSString*) reuseIdentifier
{
    return kFlyerLabViewReuseIdentifier;
}

- (void) prepareForQueue
{
    [self removeButtonTargets];
}

@end