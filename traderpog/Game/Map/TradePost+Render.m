//
//  TradePost+Render.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/11/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "TradePost+Render.h"
#import "TradePost.h"
#import "TradeItemTypes.h"
#import "TradeItemType.h"
#import "TradePostAnnotationView.h"
#import "NPCTradePost.h"
#import "MyTradePost.h"
#import "ForeignTradePost.h"
#import "Flyer.h"
#import "ImageManager.h"
#import "GameAnim.h"
#import "GameColors.h"
#import "ItemBubble.h"
#import "ItemBuyView.h"
#import "Player.h"
#import "Player+Shop.h"
#import "PogUIUtility.h"
#import "CircleButton.h"
#import <QuartzCore/QuartzCore.h>

@implementation TradePost (Render)
- (void) refreshRenderForAnnotationView:(TradePostAnnotationView *)annotationView
{
    BOOL showItemBubble = NO;
    BOOL showItemBubbleFull = NO;
    NSString* itemIdForBubble = [self itemId];
    GameEvent* curGameEvent = nil;
    
    // trade post
    if([self isMemberOfClass:[NPCTradePost class]])
    {
        UIImage* image = [[ImageManager getInstance] getImage:[self imgPath]
                                                fallbackNamed:@"b_tradepost.png"];
        [annotationView.imageView stopAnimating];
        [annotationView.imageView setImage:image];
        showItemBubble = YES;
    }
    else if([self isMemberOfClass:[MyTradePost class]])
    {
        [[GameAnim getInstance] refreshImageView:annotationView.imageView withClipNamed:@"homebase_windy"];
        [annotationView.imageView startAnimating];
        
        showItemBubble = NO;
        if([self flyerAtPost])
        {
            MyTradePost* myPost = (MyTradePost*)self;
            itemIdForBubble = myPost.lastUnloadedItemId;
        }
        else
        {
            itemIdForBubble = nil;
        }
        
        // note game-event for enabling exclamation icon further below
        curGameEvent = [self gameEvent];
    }
    else if([self isMemberOfClass:[ForeignTradePost class]])
    {
        NSString* fallbackName = @"b_homebase.png";
        ForeignTradePost* thisPost = (ForeignTradePost*)self;
        if([thisPost fbId])
        {
            // this post has an FB id; show it as a beacon
            fallbackName = @"b_beacon.png";
        }
        UIImage* image = [[ImageManager getInstance] getImage:[self imgPath]
                                                fallbackNamed:fallbackName];
        [annotationView.imageView stopAnimating];
        [annotationView.imageView setImage:image];
        showItemBubble = YES;
    }
    annotationView.frontImageView.layer.anchorPoint = CGPointMake(0.35f, 0.5f);
    annotationView.frontLeftView.layer.anchorPoint = CGPointMake(0.2f, 0.5f);

    [UIView animateWithDuration:0.1f animations:^(void){
        [annotationView.frontImageView setTransform:CGAffineTransformIdentity];
        [annotationView.frontLeftView setTransform:CGAffineTransformIdentity];
        [annotationView.imageView setTransform:CGAffineTransformIdentity];
    }];
    
    // flyer in front
    if([self flyerAtPost])
    {
        Flyer* flyer = [self flyerAtPost];
        if(kFlyerStateLoading == [flyer state])
        {/*
            BOOL anim = [[GameAnim getInstance] refreshImageView:annotationView.frontLeftView withClipNamed:@"loading"];
            if(anim)
            {
                [annotationView.frontLeftView startAnimating];
                [annotationView.frontLeftView setHidden:NO];
            }*/
            [annotationView.countdownView setHidden:NO];
            showItemBubbleFull = YES;
        }
        else if(kFlyerStateUnloading == [flyer state])
        {/*
            BOOL anim = [[GameAnim getInstance] refreshImageView:annotationView.frontLeftView withClipNamed:@"unloading"];
            if(anim)
            {
                [annotationView.frontLeftView startAnimating];
                [annotationView.frontLeftView setHidden:NO];
            }*/
            [annotationView.countdownView setHidden:NO];
            showItemBubbleFull = YES;
        }
        else
        {
            [annotationView.frontLeftView stopAnimating];
            [annotationView.frontLeftView setAnimationImages:nil];
            [annotationView.frontLeftView setHidden:YES];
            [annotationView.countdownView setHidden:YES];
            showItemBubble = NO;
        }
        UIImage* image = [flyer imageForCurrentState];
        [annotationView.frontImageView setImage:image];
        [annotationView.frontImageView setHidden:NO];
        
        if([flyer gameEvent])
        {
            // flyer game-event always override post game-event
            // (post game-event potentially added earlier for MyTradePost)
            curGameEvent = [flyer gameEvent];
        }
    }
    else
    {
        [annotationView.frontImageView setImage:nil];
        [annotationView.frontImageView setHidden:YES];
        [annotationView.frontLeftView setImage:nil];
        [annotationView.frontLeftView setHidden:YES];
        [annotationView.countdownView setHidden:YES];
    }
    
    // exclamation alert icon
    if(curGameEvent)
    {
        if(kGameEvent_PostNeedsRestocking == [curGameEvent eventType])
        {
            [[GameAnim getInstance] refreshImageView:annotationView.excImageView withClipNamed:@"alert_post"];            
        }
        else
        {
            [[GameAnim getInstance] refreshImageView:annotationView.excImageView withClipNamed:@"alert_flyer"];
        }
        [annotationView.excImageView startAnimating];
        [annotationView.excImageView setHidden:NO];
    }
    else
    {
        [annotationView.excImageView stopAnimating];
        [annotationView.excImageView setAnimationImages:nil];
        [annotationView.excImageView setHidden:YES];
    }
    
    if(itemIdForBubble && (showItemBubbleFull || (showItemBubble && [self supplyLevel])))
    {
        NSString* itemImagePath = @"checkerboard.png";
        TradeItemType* itemType = [[TradeItemTypes getInstance] getItemTypeForId:itemIdForBubble];
        NSString* itemName = nil;
        if(itemType)
        {
            itemImagePath = [itemType imgPath];
            itemName = [itemType name];
        }
        UIImage* itemImage = [[ImageManager getInstance] getImage:itemImagePath];
        [annotationView.itemBubble.imageView setImage:itemImage];
        [annotationView.itemBubble.itemLabel setText:itemName];
        [annotationView.itemBubble setHidden:NO];
        if(showItemBubbleFull)
        {
            // full alpha
            [annotationView.itemBubble.backgroundView setAlpha:1.0f];
            [annotationView.itemBubble.layer setBorderColor:[GameColors borderColorPostsWithAlpha:1.0f].CGColor];
        }
        else
        {
            // semi-transparent
            [annotationView.itemBubble.backgroundView setAlpha:0.7f];
            [annotationView.itemBubble.layer setBorderColor:[GameColors bubbleColorPostsWithAlpha:0.8f].CGColor];
        }
    }
    else
    {
        [annotationView.itemBubble setHidden:YES];        
    }
}

- (void) refreshRenderForItemBuyView:(ItemBuyView *)buyView
{
    // trade item info
    TradeItemType* itemType = [[TradeItemTypes getInstance] getItemTypeForId:[self itemId]];
    NSString* itemName = nil;
    if(itemType)
    {
        itemName = [itemType name];

        // item image
        NSString* itemImagePath = [itemType imgPath];
        UIImage* itemImage = [[ImageManager getInstance] getImage:itemImagePath];
        [buyView.nibImageView setImage:itemImage];
        [buyView.nibImageView setHidden:NO];
    }
    else
    {
        [buyView.nibImageView setHidden:YES];
    }
    
    // num player can buy
    unsigned int bucks = [[Player getInstance] bucks];
    unsigned int numAfford = bucks / [itemType price];
    unsigned int numSupply = [self supplyLevel];
    unsigned int cost = 0;
    unsigned int num = 0;
    if(!numAfford || !numSupply)
    {
        // if player can't afford any or if post has no supply, cost is the Go Fee
        cost = [[Player getInstance] goFee];
        num = 0;
    }
    else
    {
        num = MIN([self supplyLevel], numAfford);
        cost = num * [itemType price];
    }
    
    [buyView.buyCircle setHidden:NO];
    [buyView.nibZeroStockView setHidden:YES];
    [buyView.nibContentView setHidden:NO];
    [buyView.costLabel setText:[PogUIUtility commaSeparatedStringFromUnsignedInt:cost]];
    
    if(num)
    {
        [buyView.buyCircleLabel setText:@"BUY"];
        [buyView.numItemsLabel setText:[PogUIUtility commaSeparatedStringFromUnsignedInt:num]];
        [buyView.numItemsLabel setHidden:NO];
        [buyView.smallFeeLabel setHidden:YES];
        [buyView.itemNameLabel setText:itemName];
    }
    else
    {
        [buyView.buyCircleLabel setText:@"GO"];
        [buyView.numItemsLabel setHidden:YES];
        [buyView.smallFeeLabel setHidden:NO];
        if(cost)
        {
            [buyView.smallFeeLabel setText:@"for a fee"];
        }
        else
        {
            [buyView.smallFeeLabel setText:@"for free"];
        }
        [buyView.itemNameLabel setText:@"Visit"];
    }
}

@end
