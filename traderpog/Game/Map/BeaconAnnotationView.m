//
//  BeaconAnnotationView.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/11/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "BeaconAnnotationView.h"
#import "Beacon.h"

NSString* const kBeaconAnnotationViewReuseId = @"BeaconAnnotationView";

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
    [super setAnnotation:annotation];
}

#pragma mark - PogMapAnnotationViewProtocol
- (void)didSelectAnnotationViewInMap:(MKMapView*) mapView;
{
}

- (void)didDeselectAnnotationViewInMap:(MKMapView*) mapView;
{
}



@end
