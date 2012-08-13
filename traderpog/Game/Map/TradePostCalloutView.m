//
//  TradePostCalloutView.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/21/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "TradePostCalloutView.h"
#import "GameManager.h"
#import "FlyerMgr.h"
#import "Flyer.h"
#import "TradeManager.h"
#import "TradePost.h"

NSString* const kTradePostCalloutViewReuseId = @"PostCalloutView";

@interface TradePostCalloutView ()

@end

@implementation TradePostCalloutView
@synthesize itemName;
@synthesize itemSupplyLevel;

- (id) initWithAnnotation:(id<MKAnnotation>)annotation
{
    self = [super initWithAnnotation:annotation reuseIdentifier:kTradePostCalloutViewReuseId];
    if(self)
    {
        [[NSBundle mainBundle] loadNibNamed:@"TradePostCalloutView" owner:self options:nil];
    }
    return self;
}


- (IBAction)didPressGo:(id)sender 
{
    TradePost* destPost = (TradePost*)[[self parentAnnotationView] annotation];

    if([destPost isOwnPost])
    {
        // TODO: handle going home
    }
    else
    {
        // other's post
        if([[TradeManager getInstance] playerCanAffordItemsAtPost:destPost])
        {
            // player has money
            Flyer* flyer = [[[FlyerMgr getInstance] playerFlyers] objectAtIndex:0];
            [[TradeManager getInstance] flyer:flyer buyFromPost:destPost numItems:[destPost supplyLevel]];
            [[GameManager getInstance] flyer:flyer departForTradePost:destPost];
        }
        else
        {
            // inform player they cannot afford the order
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not enough coins"
                                                            message:@"More coins needed to place this order"
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        
    }
}
@end
