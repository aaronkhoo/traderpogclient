//
//  FlyerAnnotationView.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/22/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerAnnotationView.h"
#import "Flyer.h"
#import "FlyerCallout.h"
#import "GameManager.h"

NSString* const kFlyerAnnotationViewReuseId = @"FlyerAnnotationView";
static NSString* const kFlyerTransformKey = @"transform";
static NSString* const kKeyFlyerIsAtOwnPost = @"isAtOwnPost";

@interface FlyerAnnotationView ()
{
    FlyerCallout* _calloutAnnotation;
}
@end

@implementation FlyerAnnotationView
- (id) initWithAnnotation:(NSObject<MKAnnotation>*)annotation
{
    self = [super initWithAnnotation:annotation reuseIdentifier:kFlyerAnnotationViewReuseId];
    if(self)
    {
        // handle our own callout
        self.canShowCallout = NO;
        self.enabled = YES;

        // set size of view
        CGRect myFrame = self.frame;
        myFrame.size = CGSizeMake(80.0f, 80.0f);
        self.frame = myFrame;
        
        // setup tradepost image
        UIImage *annotationImage = [UIImage imageNamed:@"Flyer.png"];
        CGRect resizeRect = CGRectMake(0.0f, 0.0f, 80.0f, 80.0f);
        UIGraphicsBeginImageContext(resizeRect.size);
        [annotationImage drawInRect:resizeRect];
        UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        self.opaque = NO;
        
        // annotation-view anchor is at the center of the view;
        UIView* contentView = [[UIView alloc] initWithFrame:myFrame];
        UIImageView* imageView = [[UIImageView alloc] initWithImage:resizedImage];
        [contentView addSubview:imageView];
        
        [self addSubview:contentView];
        
        _calloutAnnotation = nil;
        
        // observe flyer transform and isAtOwnPost
        [annotation addObserver:self forKeyPath:kFlyerTransformKey options:0 context:nil];
        [annotation addObserver:self forKeyPath:kKeyFlyerIsAtOwnPost options:0 context:nil];
    }
    return self;
}

- (void) dealloc
{
    Flyer* flyer = (Flyer*)[self annotation];
    [flyer removeObserver:self forKeyPath:kFlyerTransformKey];
    [flyer removeObserver:self forKeyPath:kKeyFlyerIsAtOwnPost];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
    if([object isMemberOfClass:[Flyer class]])
    {
        Flyer* flyer = (Flyer*)object;
        if([keyPath isEqualToString:kFlyerTransformKey])
        {
            [self setTransform:[flyer transform]];
        }
        else if([keyPath isEqualToString:kKeyFlyerIsAtOwnPost])
        {
            if([flyer isAtOwnPost])
            {
                // disable touch for Flyer when it is at own post
                // own-post's callout will handle interaction with the user
                [self setEnabled:NO];
            }
            else
            {
                [self setEnabled:YES];
            }
        }
    }
}

#pragma mark - MKAnnotationView
- (void)setAnnotation:(id<MKAnnotation>)annotation
{
    if(_calloutAnnotation)
    {
        [_calloutAnnotation setCoordinate:annotation.coordinate];
    }
    [super setAnnotation:annotation];
    //self.enabled = YES;
}

#pragma mark - PogMapAnnotationViewProtocol
- (void)didSelectAnnotationViewInMap:(MKMapView*) mapView;
{   
    if(!_calloutAnnotation)
    {
        if([[GameManager getInstance] canShowMapAnnotationCallout])
        {
            Flyer* flyer = (Flyer*) [self annotation];
            if(![[flyer path] isEnroute])
            {
                // show Flyer Callout if not enroute
                _calloutAnnotation = [[FlyerCallout alloc] initWithFlyer:flyer];
                _calloutAnnotation.parentAnnotationView = self;
                [mapView addAnnotation:_calloutAnnotation];
            }
        }
        else
        {
            // disallow callout
            [mapView deselectAnnotation:[self annotation] animated:NO];
        }
    }
}

- (void)didDeselectAnnotationViewInMap:(MKMapView*) mapView;
{
    if(_calloutAnnotation)
    {
        [mapView removeAnnotation:_calloutAnnotation];
        _calloutAnnotation = nil;
    }
}



@end
