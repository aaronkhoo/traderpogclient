//
//  PostAccelView.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/11/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "PostAccelView.h"
#import "PogUIUtility.h"
#import "GameColors.h"
#import "GameAnim.h"
#import "ImageManager.h"
#import "CircleButton.h"
#import "Flyer.h"
#import "Player.h"
#import "Player+Shop.h"

NSString* const kPostAccelViewReuseIdentifier = @"PostAccelView";
static const float kBorderWidth = 6.0f;
static const float kBuyCircleBorderWidth = 6.0f;
static const float kBorderCornerRadius = 8.0f;

@interface PostAccelView ()
- (void) removeButtonTargets;
@end

@implementation PostAccelView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [[NSBundle mainBundle] loadNibNamed:@"PostAccelView" owner:self options:nil];
        [PogUIUtility setBorderOnView:self.nibContentView
                                width:kBorderWidth
                                color:[GameColors borderColorPostsWithAlpha:1.0f]
                         cornerRadius:kBorderCornerRadius];
        [self.nibContentView setBackgroundColor:[GameColors bubbleColorScanWithAlpha:1.0f]];
        [self.buyCircle setBorderWidth:kBuyCircleBorderWidth];
        [[GameAnim getInstance] refreshImageView:self.coinImageView withClipNamed:@"coin_shimmer"];
        [self.coinImageView startAnimating];
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
    if([target respondsToSelector:@selector(handleAccelOk:)])
    {
        [self.buyCircle setButtonTarget:target action:@selector(handleAccelOk:)];
    }
    else
    {
        NSLog(@"Error: ItemBuyView button target must respond to handleAccelOk:");
    }
    if([target respondsToSelector:@selector(handleModalClose:)])
    {
        [self.closeCircle setButtonTarget:target action:@selector(handleModalClose:)];
    }
    else
    {
        NSLog(@"Error: ItemBuyView button target must respond to handleModalClose:");
    }
}

- (void) refreshViewForFlyer:(Flyer *)flyer
{
    if((kFlyerStateLoading == [flyer state]) ||
       (kFlyerStateUnloading == [flyer state]))
    {
        [self.titleLabel setText:@"Extra help?"];
        [[GameAnim getInstance] refreshImageView:self.imageView withClipNamed:@"resting"];
        [self.imageView startAnimating];

        // cost
        Player* player = [Player getInstance];
        unsigned int cost = [player priceForExtraHelp];
        [self.costLabel setText:[PogUIUtility commaSeparatedStringFromUnsignedInt:cost]];
        [self.costLabel setHidden:NO];
        [self.coinImageView setHidden:NO];
        
        if([player canAffordExtraHelp])
        {
            [self.okLabel setTextColor:[UIColor whiteColor]];
            [self.okLabel setAlpha:1.0f];
        }
        else
        {
            // player can't afford to buy this upgrade
            [self.okLabel setTextColor:[UIColor lightGrayColor]];
            [self.okLabel setAlpha:0.4f];
        }
    }
    else if(kFlyerStateLoaded == [flyer state])
    {
        [self.titleLabel setText:@"Go home?"];
        [[GameAnim getInstance] refreshImageView:self.imageView withClipNamed:@"homebase_windy"];
        [self.imageView startAnimating];

        // no cost
        [self.costLabel setHidden:YES];
        [self.coinImageView setHidden:YES];
        [self.okLabel setTextColor:[UIColor whiteColor]];
        [self.okLabel setAlpha:1.0f];
    }
    
}

static const float kTriangleWidth = 10.0f;
static const float kTriangleHeight = 40.0f;
- (void)drawRect:(CGRect)rect
{
    CGRect contentFrame = self.nibContentView.frame;
    CGPoint contentMidBot = CGPointMake(contentFrame.origin.x + (0.5f * contentFrame.size.width),
                                        contentFrame.origin.y + (0.9f * contentFrame.size.height));
    UIColor* triColor = [GameColors borderColorPostsWithAlpha:1.0f];
    
    
	CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, contentMidBot.x - kTriangleWidth, contentMidBot.y);
    CGPathAddLineToPoint(path, NULL, contentMidBot.x, contentMidBot.y + kTriangleHeight);
    CGPathAddLineToPoint(path, NULL, contentMidBot.x + kTriangleWidth, contentMidBot.y);
    CGPathCloseSubpath(path);
    
    // draw triangle
	CGContextRef context = UIGraphicsGetCurrentContext();
	[triColor setFill];
	CGContextAddPath(context, path);
	CGContextSaveGState(context);
	CGContextFillPath(context);
	CGContextRestoreGState(context);
    
    CGPathRelease(path);
}

#pragma mark - internal methods
- (void) removeButtonTargets
{
    [self.buyCircle removeButtonTarget];
    [self.closeCircle removeButtonTarget];
}

#pragma mark - ViewReuseDelegate
- (NSString*) reuseIdentifier
{
    return kPostAccelViewReuseIdentifier;
}

- (void) prepareForQueue
{
    [self removeButtonTargets];
}

@end
