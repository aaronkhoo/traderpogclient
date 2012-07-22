//
//  FlyerAnnotation.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/22/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerAnnotation.h"
#import "Flyer.h"
#import "FlyerAnnotationView.h"

@implementation FlyerAnnotation
@synthesize flyer = _flyer;

- (id) initWithFlyer:(Flyer *)flyer
{
    self = [super init];
    if(self)
    {
        _flyer = flyer;
        flyer.annotation = self;
    }
    return self;
}

- (void) dealloc
{
    self.flyer.annotation = nil;
}

#pragma mark - MKAnnotation delegate
- (CLLocationCoordinate2D) coordinate
{
    return [self.flyer coord];
}

#pragma mark - MapAnnotationProtocol
- (MKAnnotationView*) annotationViewInMap:(MKMapView *)mapView
{
    MKAnnotationView* annotationView = (FlyerAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:kFlyerAnnotationViewReuseId];
    if(annotationView)
    {
        annotationView.annotation = self;
    }
    else
    {
        annotationView = [[FlyerAnnotationView alloc] initWithAnnotation:self];
    }
    
    return annotationView;
}


@end
