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
#import "TradePostAnnotation.h"

NSString* const kTradePostCalloutViewReuseId = @"PostCalloutView";

@interface TradePostCalloutView ()

@end

@implementation TradePostCalloutView

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
    Flyer* flyer = [[[FlyerMgr getInstance] playerFlyers] objectAtIndex:0];
    TradePostAnnotation* destPostAnnotation = (TradePostAnnotation*)[[self parentAnnotationView] annotation];
    [[GameManager getInstance] flyer:flyer departForTradePost:[destPostAnnotation tradePost]];
}
@end
