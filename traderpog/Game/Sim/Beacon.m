//
//  Beacon.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "Beacon.h"
#import "TradePostMgr.h"
#import "TradePost.h"
#import "BeaconAnnotationView.h"
#import <CoreLocation/CoreLocation.h>


@implementation Beacon
@synthesize beaconId = _beaconId;
@synthesize postId = _postId;
@synthesize coord = _coord;

- (id) initWithBeaconId:(NSString*)beaconId postId:(NSString *)postId
{
    self = [super init];
    if(self)
    {
        _beaconId = beaconId;
        _postId = postId;
        TradePost* post = [[TradePostMgr getInstance] getTradePostWithId:postId];
        if(post)
        {
            _coord = [post coord];
        }
    }
    return self;
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
- (MKAnnotationView*) annotationViewInMap:(MKMapView *)mapView
{
    MKAnnotationView* annotationView = (BeaconAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:kBeaconAnnotationViewReuseId];
    if(annotationView)
    {
        annotationView.annotation = self;
    }
    else
    {
        annotationView = [[BeaconAnnotationView alloc] initWithAnnotation:self];
    }
    return annotationView;
}

@end
