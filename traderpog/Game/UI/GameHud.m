//
//  GameHud.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/5/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "GameHud.h"
#import "CircleBarView.h"
#import "GameColors.h"

static const float kHudCoinsX = 40.0f;
static const float kHudCoinsY = 30.0f;
static const float kHudCoinsWidth = 120.0f;
static const float kHudCoinsHeight = 60.0f;
static const float kHudCoinsBorderWidth = 2.5f;
static const float kHudCoinsTextSize = 20.0f;

@implementation GameHud

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // HUD is push only; no user interaction;
        [self setUserInteractionEnabled:NO];
        
        // coins
        CGRect coinsFrame = CGRectMake(kHudCoinsX, kHudCoinsY,
                                       kHudCoinsWidth, kHudCoinsHeight);
        self.coins = [[CircleBarView alloc] initWithFrame:coinsFrame
                                                    color:[GameColors borderColorPostsWithAlpha:1.0f]
                                                textColor:[UIColor whiteColor]
                                              borderColor:[GameColors borderColorScanWithAlpha:1.0f]
                                              borderWidth:kHudCoinsBorderWidth
                                                 textSize:kHudCoinsTextSize
                                            barHeightFrac:0.6f
                                           hasRoundCorner:YES];
        [self addSubview:[self coins]];
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
