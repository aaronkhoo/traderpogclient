//
//  TradePost+Render.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/11/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "TradePost+Render.h"
#import "TradePost.h"
#import "TradePostAnnotationView.h"
#import "NPCTradePost.h"
#import "MyTradePost.h"
#import "ForeignTradePost.h"
#import "Flyer.h"
#import "ImageManager.h"
#import "AnimMgr.h"
#import "AnimClip.h"

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
            [annotationView.topImageView setImage:iconImage];
            [annotationView.topImageView setHidden:NO];
        }
        else
        {
            [annotationView.topImageView setHidden:YES];
        }
    }
    else
    {
        [annotationView.frontImageView setImage:nil];
        [annotationView.frontImageView setHidden:YES];
        [annotationView.frontLeftView setImage:nil];
        [annotationView.frontLeftView setHidden:YES];
        [annotationView.topImageView setHidden:YES];
        [annotationView.smallLabel setHidden:YES];
    }
}
@end
