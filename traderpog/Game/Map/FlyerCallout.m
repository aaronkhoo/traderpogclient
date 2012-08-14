//
//  FlyerCallout.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerCallout.h"
#import "Flyer.h"
#import "FlyerCalloutView.h"

@interface FlyerCallout ()
{
    FlyerCalloutView* _calloutView;
}
@end

@implementation FlyerCallout
@synthesize flyer = _flyer;
@synthesize parentAnnotationView;

- (id) initWithFlyer:(Flyer *)flyer
{
    self = [super init];
    if(self)
    {
        _flyer = flyer;
        _coord = [flyer coordinate];
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
        FlyerCalloutView* annotationView = (FlyerCalloutView*) [mapView dequeueReusableAnnotationViewWithIdentifier:kFlyerCalloutViewReuseId];
        if(!annotationView)
        {
            annotationView = [[FlyerCalloutView alloc] initWithAnnotation:self];
        }
        else
        {
            annotationView.annotation = self;
        }
        annotationView.parentAnnotationView = self.parentAnnotationView;
        annotationView.mapView = mapView;
        _calloutView = annotationView;
    }
    return _calloutView;
}


@end
