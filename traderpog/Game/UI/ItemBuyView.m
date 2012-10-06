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
#import "CircleButton.h"

NSString* const kItemBuyViewReuseIdentifier = @"ItemBuyView";
static const float kBorderWidth = 6.0f;
static const float kBuyCircleBorderWidth = 6.0f;
static const float kBorderCornerRadius = 8.0f;

@interface ItemBuyView ()
- (void) removeButtonTargets;
@end

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
    if([target respondsToSelector:@selector(handleBuyOk:)])
    {
        [self.buyButton addTarget:target action:@selector(handleBuyOk:) forControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
        NSLog(@"Error: ItemBuyView button target must respond to handleBuyOk:");
    }
    if([target respondsToSelector:@selector(handleBuyClose:)])
    {
        [self.closeButton addTarget:target action:@selector(handleBuyClose:) forControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
        NSLog(@"Error: ItemBuyView button target must respond to handleBuyClose:");
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
    [self.buyButton removeTarget:nil action:@selector(handleBuyOk:) forControlEvents:UIControlEventTouchUpInside];
    [self.closeButton removeTarget:nil action:@selector(handleBuyClose:) forControlEvents:UIControlEventTouchUpInside];    
}

#pragma mark - ViewReuseDelegate
- (NSString*) reuseIdentifier
{
    return kItemBuyViewReuseIdentifier;
}

- (void) prepareForQueue
{
    [self removeButtonTargets];
}

@end
