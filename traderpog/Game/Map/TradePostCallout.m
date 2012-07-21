//
//  TradePostCallout.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/21/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "TradePostCallout.h"
#import "TradePost.h"

@implementation TradePostCallout
@synthesize tradePost = _tradePost;

- (id) initWithTradePost:(TradePost*)tradePost
{
    self = [super init];
    if(self)
    {
        _tradePost = tradePost;
        _coord = [tradePost coord];
    }
    return self;
}

#pragma mark - MKAnnotation
- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    _coord = newCoordinate;
    /*
    if(_calloutView) 
    {
        // mapView can decide to throw annotation-views into its reuse queue any time
        // so, if the view we have retained no longer belongs to us, clear it
        if([_calloutView annotation] != self)
        {
            NSLog(@"coordinate: post callout annotation recycled %@", self.tradePost.name);
            [_calloutView release];
            _calloutView = nil;
        }
        else 
        {
            // update coordinate of callout
            [_calloutView setAnnotation:self];
        }
    }
     */
}

- (CLLocationCoordinate2D)coordinate
{
    return _coord;
}

#pragma mark - MapAnnotationProtocol
- (MKAnnotationView*)annotationViewInMap:(MKMapView *)mapView;
{
    return nil;
    /*
    // mapView can decide to throw annotation-views into its reuse queue any time
    // so, if the view we have retained no longer belongs to us, clear it
    if(_calloutView && ([_calloutView annotation] != self))
    {
        NSLog(@"post callout annotation recycled %@ (%@) (%@)", self.tradePost.name, self, [_calloutView annotation]);
        [_calloutView release];
        _calloutView = nil;
    }
    
    if(!_calloutView)
    {
        _calloutView = [(PostCalloutView*) [mapView dequeueReusableAnnotationViewWithIdentifier:kPostCalloutViewReuseId] retain];
        if(!_calloutView) 
        {
            _calloutView = [[PostCalloutView alloc] initWithAnnotation:self];
        } 
        else 
        {
            _calloutView.annotation = self;
        }
        [_calloutView reset];
        _calloutView.parentAnnotationView = self.parentAnnotationView;
        _calloutView.mapView = mapView;
        if([_tradePost supplyLevelSufficientForSaleForIdentifier:[_tradeItem identifier]])
        {
            // setup trade variables
            [_calloutView.amountLabel setText:[PogUIUtility commaSeparatedStringFromUnsignedInt:_supplyUnits]];
            [_calloutView.unitsToBuyLabel setText:[PogUIUtility commaSeparatedStringFromUnsignedInt:_unitsToTrade]];
            [_calloutView.itemLabel setText:[_tradeItem name]];
            [_calloutView.expandedItemLabel setText:[_tradeItem name]];
            
            NSString* priceString = [PogUIUtility commaSeparatedStringFromUnsignedInt:[_tradeItem price]];
            [_calloutView.priceLabel setText:[NSString stringWithFormat:@"%@ each",priceString]];
            
            FlyerObjC* curFlyer = [[GameManagerObjC getInstance] getCurFlyer];
            if(FLYER_STATE_ENROUTE == [curFlyer curState])
            {
                // flyer is enroute, disable order button
                [_calloutView.priceLabel setText:@"Flyer busy"];
                [_calloutView.plusButton setHidden:YES];
            }
            else if(0 == _unitsToTrade)
            {
                // flyer can't afford items at this post
                [_calloutView.priceLabel setText:@"Can't afford"];
                [_calloutView.plusButton setHidden:YES];
            }
            else 
            {
                [_calloutView.plusButton setHidden:NO];
            }
        }
        else 
        {
            // Replenishing
            // TODO: move this into it's own Callout class
            [_calloutView.amountLabel setText:@"0"];
            [_calloutView.priceLabel setText:@"Replenishing..."];
            [_calloutView.plusButton setHidden:YES];
        }
    }
    return _calloutView;
     */
}


@end
