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
#import "ItemBubble.h"
#import "ItemBuyView.h"
#import "Player.h"
#import "PogUIUtility.h"
#import "CircleButton.h"

@implementation TradePost (Render)
- (void) refreshRenderForAnnotationView:(TradePostAnnotationView *)annotationView
{
    BOOL showItemBubble = NO;
    
    // trade post
    if([self isMemberOfClass:[NPCTradePost class]])
    {
        UIImage* image = [[ImageManager getInstance] getImage:[self imgPath]
                                                fallbackNamed:@"b_tradepost.png"];
        [annotationView.imageView setImage:image];
        showItemBubble = YES;
    }
    else if([self isMemberOfClass:[MyTradePost class]])
    {
        UIImage* image = [[ImageManager getInstance] getImage:[self imgPath]
                                                fallbackNamed:@"b_flyerlab.png"];
        [annotationView.imageView setImage:image];
        showItemBubble = YES;
    }
    else if([self isMemberOfClass:[ForeignTradePost class]])
    {
        UIImage* image = [[ImageManager getInstance] getImage:[self imgPath]
                                                fallbackNamed:@"b_homebase.png"];
        [annotationView.imageView setImage:image];
        showItemBubble = YES;
    }
    [annotationView.imageView setTransform:CGAffineTransformIdentity];
    
    // flyer in front
    if([self flyerAtPost])
    {
        Flyer* flyer = [self flyerAtPost];
        if(kFlyerStateLoading == [flyer state])
        {
            BOOL anim = [[GameAnim getInstance] refreshImageView:annotationView.frontLeftView withClipNamed:@"loading"];
            if(anim)
            {
                [annotationView.frontLeftView startAnimating];
                [annotationView.frontLeftView setHidden:NO];
            }
            [annotationView.smallLabel setHidden:NO];
        }
        else if(kFlyerStateUnloading == [flyer state])
        {
            BOOL anim = [[GameAnim getInstance] refreshImageView:annotationView.frontLeftView withClipNamed:@"unloading"];
            if(anim)
            {
                [annotationView.frontLeftView startAnimating];
                [annotationView.frontLeftView setHidden:NO];
            }
            [annotationView.smallLabel setHidden:NO];
        }
        else
        {
            [annotationView.frontLeftView stopAnimating];
            [annotationView.frontLeftView setAnimationImages:nil];
            [annotationView.frontLeftView setHidden:YES];
            [annotationView.smallLabel setHidden:YES];
        }
        UIImage* image = [flyer imageForCurrentState];
        [annotationView.frontImageView setImage:image];
        [annotationView.frontImageView setHidden:NO];
        
        if([flyer gameEvent])
        {
            [[GameAnim getInstance] refreshImageView:annotationView.excImageView withClipNamed:@"alert_flyer"];
            [annotationView.excImageView startAnimating];
            [annotationView.excImageView setHidden:NO];
        }
        else
        {
            [annotationView.excImageView stopAnimating];
            [annotationView.excImageView setAnimationImages:nil];
            [annotationView.excImageView setHidden:YES];
        }
        showItemBubble = NO;
    }
    else
    {
        [annotationView.frontImageView setImage:nil];
        [annotationView.frontImageView setHidden:YES];
        [annotationView.frontLeftView setImage:nil];
        [annotationView.frontLeftView setHidden:YES];
        [annotationView.excImageView setImage:nil];
        [annotationView.excImageView setHidden:YES];
        [annotationView.smallLabel setHidden:YES];
    }
    
    if(showItemBubble && [self supplyLevel])
    {
        NSString* itemImagePath = @"checkerboard.png";
        TradeItemType* itemType = [[TradeItemTypes getInstance] getItemTypeForId:[self itemId]];
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
    }
    else
    {
        [annotationView.itemBubble setHidden:YES];        
    }
}

- (void) refreshRenderForItemBuyView:(ItemBuyView *)buyView
{
    // trade item info
    NSString* itemImagePath = @"checkerboard.png";
    TradeItemType* itemType = [[TradeItemTypes getInstance] getItemTypeForId:[self itemId]];
    NSString* itemName = nil;
    if(itemType)
    {
        itemImagePath = [itemType imgPath];
        itemName = [itemType name];
    }
    
    // num player can buy
    unsigned int bucks = [[Player getInstance] bucks];
    unsigned int numAfford = bucks / [itemType price];
    unsigned int numCanBuy = MIN([self supplyLevel], numAfford);
    if(numCanBuy)
    {
        [buyView.buyCircle setHidden:NO];
        [buyView.nibZeroStockView setHidden:YES];
        [buyView.nibContentView setHidden:NO];
        [buyView.numItemsLabel setText:[PogUIUtility commaSeparatedStringFromUnsignedInt:numCanBuy]];

        // item image
        UIImage* itemImage = [[ImageManager getInstance] getImage:itemImagePath];
        [buyView.nibImageView setImage:itemImage];
        [buyView.itemNameLabel setText:itemName];
        
        // cost to player
        unsigned int cost = MIN(numCanBuy * [itemType price], bucks);
        [buyView.costLabel setText:[PogUIUtility commaSeparatedStringFromUnsignedInt:cost]];
    }
    else
    {
        [buyView.buyCircle setHidden:YES];
        [buyView.nibZeroStockView setHidden:NO];
        [buyView.nibContentView setHidden:YES];
    }
}

@end
