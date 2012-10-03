//
//  ItemBuyView.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/2/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "ItemBuyView.h"
#import "PogUIUtility.h"
#import "GameColors.h"
#import "GameAnim.h"

static const float kBorderWidth = 4.0f;
static const float kBorderCornerRadius = 8.0f;

@implementation ItemBuyView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        [[NSBundle mainBundle] loadNibNamed:@"ItemBuyView" owner:self options:nil];
        [PogUIUtility setBorderOnView:self.nibContentView
                                width:kBorderWidth
                                color:[GameColors borderColorPostsWithAlpha:1.0f]
                         cornerRadius:kBorderCornerRadius];
        [self.nibContentView setBackgroundColor:[GameColors bubbleColorScanWithAlpha:1.0f]];
        [[GameAnim getInstance] refreshImageView:self.coinImageView withClipNamed:@"coin_shimmer"];
        [self.coinImageView startAnimating];
        [self addSubview:self.nibView];
    }
    return self;
}

@end
