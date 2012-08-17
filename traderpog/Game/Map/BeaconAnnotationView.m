//
//  BeaconAnnotationView.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/11/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "BeaconAnnotationView.h"
#import "Beacon.h"
#import "TradePostCallout.h"
#import "ImageManager.h"
#import "TradePost.h"
#import "TradePostMgr.h"

NSString* const kBeaconAnnotationViewReuseId = @"BeaconAnnotationView";

@interface BeaconAnnotationView ()
{
    NSObject<MKAnnotation,MapAnnotationProtocol>* _calloutAnnotation;
}
@end

@implementation BeaconAnnotationView
- (id) initWithAnnotation:(NSObject<MKAnnotation>*)annotation
{
    self = [super initWithAnnotation:annotation reuseIdentifier:kBeaconAnnotationViewReuseId];
    if(self)
    {
        // set size of view
        CGRect myFrame = self.frame;
        myFrame.size = CGSizeMake(120.0f, 120.0f);
        self.frame = myFrame;
        
        // setup tradepost image
        UIImage *annotationImage = [UIImage imageNamed:@"TradePost.png"];
        CGRect resizeRect = CGRectMake(0.0f, 0.0f, 120.0f, 120.0f);
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
    }
    return self;
}

#pragma mark - MKAnnotationView
- (void)setAnnotation:(id<MKAnnotation>)annotation
{
    if(_calloutAnnotation)
    {
        [_calloutAnnotation setCoordinate:annotation.coordinate];
    }
    [super setAnnotation:annotation];
    self.enabled = YES;
}

#pragma mark - PogMapAnnotationViewProtocol
- (void)didSelectAnnotationViewInMap:(MKMapView*) mapView;
{
    if(!_calloutAnnotation)
    {
        Beacon* beacon = (Beacon*)[self annotation];
        TradePost* tradePost = [[TradePostMgr getInstance] getTradePostWithId:[beacon postId]];
        if(tradePost)
        {
            // otherwise, show tradepost callout
            TradePostCallout* callout = [[TradePostCallout alloc] initWithTradePost:tradePost];
            callout.parentAnnotationView = self;
            _calloutAnnotation = callout;
        }
        [mapView addAnnotation:_calloutAnnotation];
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
