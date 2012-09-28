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
#import "ImageManager.h"
#import "PogUIUtility.h"
#import "Player.h"

static const float kHudCoinsX = 40.0f;
static const float kHudCoinsY = 40.0f;
static const float kHudCoinsWidth = 150.0f;
static const float kHudCoinsHeight = 60.0f;
static const float kHudCoinsBarHeightFrac = 0.55f;
static const float kHudCoinsBorderWidth = 2.5f;
static const float kHudCoinsTextSize = 20.0f;
static const float kHudCoinsIconX = 0.3f * kHudCoinsWidth;

@interface GameHud ()
{
    UIImageView* _coinIcon;
}
@end

@implementation GameHud
@synthesize coins = _coins;
@synthesize holdNextCoinsUpdate = _holdNextCoinsUpdate;

- (id)initWithFrameWithHeight:(CGRect)frame bannershift:(CGFloat)bannershift
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // HUD is push only; no user interaction;
        [self setUserInteractionEnabled:NO];
        
        // coins HUD
        CGRect coinsFrame = CGRectMake(kHudCoinsX, kHudCoinsY + bannershift,
                                       kHudCoinsWidth, kHudCoinsHeight);
        self.coins = [[CircleBarView alloc] initWithFrame:coinsFrame
                                                    color:[GameColors borderColorPostsWithAlpha:1.0f]
                                                textColor:[UIColor whiteColor]
                                              borderColor:[GameColors borderColorScanWithAlpha:1.0f]
                                              borderWidth:kHudCoinsBorderWidth
                                                 textSize:kHudCoinsTextSize
                                            barHeightFrac:kHudCoinsBarHeightFrac
                                           hasRoundCorner:YES];
        [self.coins setImage:[[ImageManager getInstance] getImage:@"icon_member.png" fallbackNamed:@"icon_member.png"]];        
        [self addSubview:[self coins]];
         
         // shiny coin in coins HUD
        float iconSize = kHudCoinsBarHeightFrac * kHudCoinsHeight;
        float iconY = 0.5f * (kHudCoinsHeight - iconSize);
        CGRect iconCoinFrame = CGRectMake(kHudCoinsIconX, iconY, iconSize, iconSize);
        _coinIcon = [[UIImageView alloc] initWithFrame:iconCoinFrame];
        const unsigned int kNumFrames = 20;
        unsigned int animFrames[kNumFrames] = {1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 4, 5, 1, 1, 1, 1, 1, 1, 1, 1};
        NSMutableArray* coinImages = [NSMutableArray arrayWithCapacity:kNumFrames];
        for(unsigned int i = 0; i < kNumFrames; ++i)
        {
            NSString* name = [NSString stringWithFormat:@"coin_00%d.png", animFrames[i]];
            UIImage* image = [[ImageManager getInstance] getImage:name fallbackNamed:name];
            [coinImages addObject:image];
        }
        [_coinIcon setAnimationImages:coinImages];
        [_coinIcon setAnimationDuration:1.5f];
        [_coinIcon startAnimating];
        [self.coins addSubview:_coinIcon];
        
        // when _holdNextCoinsUpdate is true, the next coins-changed note will not skip updating
        // GameHud coins; instead, the coins will be set when _holdNextCoinsUpdate gets unset
        _holdNextCoinsUpdate = NO;
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
