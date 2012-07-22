//
//  FlyerAnnotationView.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/22/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerAnnotationView.h"
#import "FlyerAnnotation.h"

NSString* const kFlyerAnnotationViewReuseId = @"FlyerAnnotationView";

@implementation FlyerAnnotationView
- (id) initWithAnnotation:(FlyerAnnotation *)annotation
{
    self = [super initWithAnnotation:annotation reuseIdentifier:kFlyerAnnotationViewReuseId];
    if(self)
    {
        // handle our own callout
        self.canShowCallout = NO;
        
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
        
//        _calloutAnnotation = nil;
    }
    return self;
}

#pragma mark - MKAnnotationView
- (void)setAnnotation:(id<MKAnnotation>)annotation
{
//    if(_calloutAnnotation) 
//    {
//        [_calloutAnnotation setCoordinate:annotation.coordinate];
//    }
    [super setAnnotation:annotation];
    self.enabled = YES;
}

#pragma mark - PogMapAnnotationViewProtocol
- (void)didSelectAnnotationViewInMap:(MKMapView*) mapView;
{    
//    if(!_calloutAnnotation)
//    {
//        TradePostAnnotation* tradePostAnnotation = (TradePostAnnotation*) [self annotation];
//        _calloutAnnotation = [[TradePostCallout alloc] initWithTradePost:[tradePostAnnotation tradePost]];
//        _calloutAnnotation.parentAnnotationView = self;
//        [mapView addAnnotation:_calloutAnnotation];
//    }
}

- (void)didDeselectAnnotationViewInMap:(MKMapView*) mapView;
{
//    if(_calloutAnnotation)
///    {
//        [mapView removeAnnotation:_calloutAnnotation];
//        _calloutAnnotation = nil;
//    }
}



@end