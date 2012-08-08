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

@interface FlyerAnnotation ()
{
    CLLocationCoordinate2D _coord;
}
@property (nonatomic) CLLocationCoordinate2D coord;
@end

@implementation FlyerAnnotation
@synthesize flyer = _flyer;
@synthesize coord = _coord;
@synthesize transform = _transform;

- (id) initWithFlyer:(Flyer *)flyer
{
    self = [super init];
    if(self)
    {
        _flyer = flyer;
        _coord = [flyer coord];
        _transform = [flyer transform];
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
    /*
    self.curLocation = [[[CLLocation alloc] initWithLatitude:newCoordinate.latitude longitude:newCoordinate.longitude] autorelease];
    if(_flyerAnnotView)
    {
        // mapView can decide to throw annotation-views into its reuse queue any time
        // so, if the view we have retained no longer belongs to us, clear it
        if(_flyerAnnotView && ([_flyerAnnotView annotation] != self))
        {
            NSLog(@"coordinate: flyer annotation recycled %@ (%@, %@)", _name, self, [_flyerAnnotView annotation]);
            [_flyerAnnotView release];
            _flyerAnnotView = nil;
        }
        else
        {
            [_flyerAnnotView setAnnotation:self];
        }
    }
     */
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
    annotationView.transform = [self transform];
    return annotationView;
}


@end
