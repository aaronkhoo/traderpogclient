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

static const float kContentWInset = 20.0f;
static const float kContentHInset = 20.0f;
static const float kCloseSize = 40.0f;
static const float kCloseBorderWidth = 3.0f;
static const float kBorderWidth = 3.0f;

@implementation ItemBuyView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        [[NSBundle mainBundle] loadNibNamed:@"ItemBuyView" owner:self options:nil];
        [PogUIUtility setBorderOnView:self.nibContentView width:kBorderWidth color:[GameColors borderColorPostsWithAlpha:1.0f]];
        [self.nibContentView setBackgroundColor:[GameColors bubbleColorScanWithAlpha:1.0f]];
        [self addSubview:self.nibView];
    }
    return self;
}
/*
- (id) initWithFrame:(CGRect)frame borderWidth:(float)borderWidth color:(UIColor*)color borderColor:(UIColor*)borderColor
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setBackgroundColor:[UIColor whiteColor]];
        
        // content view
        CGRect contentRect = CGRectInset(self.bounds, kContentWInset, kContentHInset);
        self.contentView = [[UIView alloc] initWithFrame:contentRect];
        [self addSubview:self.contentView];
        [self.contentView setBackgroundColor:[UIColor blackColor]];
        
        // close bubble on the top right
        float closeX = (contentRect.origin.x + contentRect.size.width) - (0.5f * kCloseSize);
        float closeY = contentRect.origin.y - (0.5f * kCloseSize);
        CGRect closeRect = CGRectMake(closeX, closeY, kCloseSize, kCloseSize);
        self.closeView = [[UIView alloc] initWithFrame:closeRect];
        [PogUIUtility setCircleForView:self.closeView
                       withBorderWidth:kCloseBorderWidth
                           borderColor:[GameColors borderColorPostsWithAlpha:1.0f]];
        [self.closeView setBackgroundColor:[GameColors bubbleColorScanWithAlpha:1.0f]];
        [self addSubview:self.closeView];
        
        // ok bubble on the bottom right
        
    }
    return self;
}
*/


@end
