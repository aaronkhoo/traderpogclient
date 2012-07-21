//
//  TradePostAnnotation.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/15/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "TradePostAnnotation.h"
#import "TradePost.h"
#import "TradePostAnnotationView.h"

@implementation TradePostAnnotation
@synthesize tradePost = _tradePost;

- (id) initWithTradePost:(TradePost *)tradePost
{
    self = [super init];
    if(self)
    {
        _tradePost = tradePost;
        tradePost.annotation = self;
    }
    return self;
}

- (void) dealloc
{
    self.tradePost.annotation = nil;
}

#pragma mark - MKAnnotation delegate
- (CLLocationCoordinate2D) coordinate
{
    return [self.tradePost coord];
}

#pragma mark - MapAnnotationProtocol
- (MKAnnotationView*) annotationViewInMap:(MKMapView *)mapView
{
    MKAnnotationView* annotationView = (TradePostAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:kTradePostAnnotationViewReuseId];
    if(annotationView)
    {
        annotationView.annotation = self;
    }
    else
    {
        annotationView = [[TradePostAnnotationView alloc] initWithAnnotation:self];
    }
    
    return annotationView;
}

@end
