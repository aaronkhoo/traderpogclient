//
//  TradePostCalloutView.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/21/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "TradePostCalloutView.h"

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


@end
