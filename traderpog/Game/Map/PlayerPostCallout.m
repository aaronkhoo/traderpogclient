//
//  PlayerPostCallout.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/17/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "MyTradePost.h"
#import "PlayerPostCallout.h"
#import "PlayerPostCalloutView.h"
#import "TradePost.h"

@interface PlayerPostCallout ()
{
    PlayerPostCalloutView* _calloutView;
}
@end

@implementation PlayerPostCallout
@synthesize tradePost = _tradePost;
@synthesize parentAnnotationView;

- (id) initWithTradePost:(TradePost *)tradePost
{
    self = [super init];
    if(self)
    {
        _tradePost = tradePost;
        _coord = [tradePost coordinate];
    }
    return self;
}

#pragma mark - MKAnnotation
- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    _coord = newCoordinate;
    if(_calloutView)
    {
        // mapView can decide to throw annotation-views into its reuse queue any time
        // so, if the view we have retained no longer belongs to us, clear it
        if([_calloutView annotation] != self)
        {
            _calloutView = nil;
        }
        else
        {
            // update coordinate of callout
            [_calloutView setAnnotation:self];
        }
    }
}

- (CLLocationCoordinate2D)coordinate
{
    return _coord;
}

#pragma mark - MapAnnotationProtocol
- (MKAnnotationView*)annotationViewInMap:(MKMapView *)mapView;
{
    // mapView can decide to throw annotation-views into its reuse queue any time
    // so, if the view we have retained no longer belongs to us, clear it
    // HACK (SCC)
    // This seems like it can be problematic;
    // Revisit!!
    
    if(_calloutView && ([_calloutView annotation] != self))
    {
        _calloutView = nil;
    }
    
    // HACK (SCC)
    
    if(!_calloutView)
    {
        PlayerPostCalloutView* annotationView = (PlayerPostCalloutView*) [mapView dequeueReusableAnnotationViewWithIdentifier:kPlayerPostCalloutViewReuseId];
        if(!annotationView)
        {
            annotationView = [[PlayerPostCalloutView alloc] initWithAnnotation:self];
        }
        else
        {
            annotationView.annotation = self;
        }
        
        if([_tradePost isMemberOfClass:[MyTradePost class]])
        {
            BOOL hideRestock = ([_tradePost supplyLevel] > 0);
            [annotationView setHiddenOnRestock:hideRestock];
            [annotationView changeFlyerLabLabelIfNecessary];
        }
        
        annotationView.parentAnnotationView = self.parentAnnotationView;
        annotationView.mapView = mapView;
        _calloutView = annotationView;
    }
    return _calloutView;
}



@end
