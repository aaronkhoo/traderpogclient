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
        UIImage* image = [flyer imageForCurrentState];
        [annotationView.frontImageView setImage:image];
        [annotationView.frontImageView setHidden:NO];
    }
    else
    {
        [annotationView.frontImageView setImage:nil];
        [annotationView.frontImageView setHidden:YES];
    }
}
@end
