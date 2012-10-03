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
#import "AnimMgr.h"
#import "AnimClip.h"
#import "ItemBubble.h"

@implementation TradePost (Render)
- (void) refreshRenderForAnnotationView:(TradePostAnnotationView *)annotationView
{
    // trade post
    if([self isMemberOfClass:[NPCTradePost class]])
    {
        UIImage* image = [[ImageManager getInstance] getImage:[self imgPath]
                                                fallbackNamed:@"b_tradepost.png"];
        [annotationView.imageView setImage:image];
    }
    else if([self isMemberOfClass:[MyTradePost class]])
    {
        UIImage* image = [[ImageManager getInstance] getImage:[self imgPath]
                                                fallbackNamed:@"b_flyerlab.png"];
        [annotationView.imageView setImage:image];
    }
    else if([self isMemberOfClass:[ForeignTradePost class]])
    {
        UIImage* image = [[ImageManager getInstance] getImage:[self imgPath]
                                                fallbackNamed:@"b_homebase.png"];
        [annotationView.imageView setImage:image];
    }
    
    // flyer in front
    if([self flyerAtPost])
    {
        Flyer* flyer = [self flyerAtPost];
        if(kFlyerStateLoading == [flyer state])
        {
            AnimClip* clip = [[AnimMgr getInstance] getClipWithName:@"loading"];
            if(clip)
            {
                [annotationView.frontLeftView setAnimationImages:[clip imagesArray]];
                [annotationView.frontLeftView setAnimationDuration:[clip secondsPerLoop]];
                [annotationView.frontLeftView startAnimating];
                [annotationView.frontLeftView setHidden:NO];
            }
            [annotationView.smallLabel setHidden:NO];
        }
        else if(kFlyerStateUnloading == [flyer state])
        {
            AnimClip* clip = [[AnimMgr getInstance] getClipWithName:@"unloading"];
            if(clip)
            {
                [annotationView.frontLeftView setAnimationImages:[clip imagesArray]];
                [annotationView.frontLeftView setAnimationDuration:[clip secondsPerLoop]];
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
            UIImage* iconImage = [[ImageManager getInstance] getImage:@"icon_alert_flyer.png"];
            [annotationView.excImageView setImage:iconImage];
            [annotationView.excImageView setHidden:NO];
        }
        else
        {
            [annotationView.excImageView setHidden:YES];
        }
        [annotationView.itemBubble setHidden:YES];
    }
    else
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
        
        [annotationView.frontImageView setImage:nil];
        [annotationView.frontImageView setHidden:YES];
        [annotationView.frontLeftView setImage:nil];
        [annotationView.frontLeftView setHidden:YES];
        [annotationView.excImageView setImage:nil];
        [annotationView.excImageView setHidden:YES];
        [annotationView.smallLabel setHidden:YES];
    }
}

@end
