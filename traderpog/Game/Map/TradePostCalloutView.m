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
#import "BeaconAnnotationView.h"
#import "TradePostAnnotationView.h"
#import "Beacon.h"
#import "TradePostMgr.h"

NSString* const kTradePostCalloutViewReuseId = @"PostCalloutView";

@interface TradePostCalloutView ()

@end

@implementation TradePostCalloutView
@synthesize itemName;
@synthesize itemSupplyLevel;
@synthesize orderButton;

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
    TradePost* destPost = nil;
    if([self.parentAnnotationView isMemberOfClass:[TradePostAnnotationView class]])
    {
        // parent is tradePost
        destPost = (TradePost*)[[self parentAnnotationView] annotation];
    }
    else if([self.parentAnnotationView isMemberOfClass:[BeaconAnnotationView class]])
    {
        // parent is a beacon
        destPost = (TradePost*) [self.parentAnnotationView annotation];
    }

    if(destPost)
    {
        if([destPost isMemberOfClass:[MyTradePost class]])
        {
            // TODO: handle going home
        }
        else
        {
            // other's post
            if(![[TradeManager getInstance] playerHasIdleFlyers])
            {
                // inform player they cannot afford the order
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Flyers busy"
                                                                message:@"Need idle Flyer to place this order"
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
                [alert show];                
            }
            else if(![[TradeManager getInstance] playerCanAffordItemsAtPost:destPost])
            {
                // inform player they cannot afford the order
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not enough coins"
                                                                message:@"More coins needed to place this order"
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            else
            {
                // player can order
                [[GameManager getInstance] showFlyerSelectForBuyAtPost:destPost];
//                Flyer* flyer = [[[FlyerMgr getInstance] playerFlyers] objectAtIndex:0];
//                [[TradeManager getInstance] flyer:flyer buyFromPost:destPost numItems:[destPost supplyLevel]];
//                [[GameManager getInstance] flyer:flyer departForTradePost:destPost];
            }
            
        }
        
        // halt all other callouts for a second so that we don't get touch-through callouts popping up when
        // player presses Go
        [[GameManager getInstance] haltMapAnnotationCalloutsForDuration:0.5];
    }
}
@end
