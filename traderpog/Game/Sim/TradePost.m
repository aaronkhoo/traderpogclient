//
//  TradePost.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "Player.h"
#import "TradePost.h"
#import "TradePostMgr.h"

@implementation TradePost
@synthesize postId = _postId;
@synthesize itemId = _itemId;
@synthesize supplyLevel = _supplyLevel;
@synthesize imgPath = _imgPath;
@synthesize supplyMaxLevel = _supplyMaxLevel;
@synthesize beacontime = _beacontime;
@synthesize hasFlyer = _hasFlyer;
@synthesize flyerAtPost = _flyerAtPost;
@synthesize delegate = _delegate;

- (id) init
{
    self = [super init];
    if(self)
    {
        _flyerAtPost = nil;
    }
    return self;
}

#pragma mark - trade
- (void) deductNumItems:(unsigned int)num
{
    unsigned int numToSub = MIN([self supplyLevel], num);
    self.supplyLevel -= numToSub;
}

#pragma mark - getters/setters
- (CLLocationCoordinate2D) coord
{
    return _coord;
}

- (void) setCoord:(CLLocationCoordinate2D)coord
{
    _coord = coord;
}


#pragma mark - MKAnnotation delegate
- (CLLocationCoordinate2D) coordinate
{
    return [self coord];
}

- (void) setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    self.coord = newCoordinate;
}

#pragma mark - MapAnnotationProtocol
- (TradePostAnnotationView*) getAnnotationViewInstance:(MKMapView *)mapView
{
    TradePostAnnotationView* annotationView = (TradePostAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:kTradePostAnnotationViewReuseId];
    if(annotationView)
    {
        annotationView.annotation = self;
    }
    else
    {
        annotationView = [[TradePostAnnotationView alloc] initWithAnnotation:self];
    }
    
    [self addObserver:annotationView forKeyPath:kKeyTradePostHasFlyer options:0 context:nil];
    [self addObserver:annotationView forKeyPath:kKeyFlyerAtPost options:0 context:nil];

    return annotationView;
}

- (MKAnnotationView*) annotationViewInMap:(MKMapView *)mapView
{
    // This function should never be called in the base class.
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

@end
