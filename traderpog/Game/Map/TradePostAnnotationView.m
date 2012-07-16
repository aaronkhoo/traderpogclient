//
//  TradePostAnnotationView.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/15/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "TradePostAnnotationView.h"
#import "TradePostAnnotation.h"

NSString* const kTradePostAnnotationViewReuseId = @"PostAnnotationView";
@implementation TradePostAnnotationView

- (id) initWithAnnotation:(TradePostAnnotation *)annotation
{
    self = [super initWithAnnotation:annotation reuseIdentifier:kTradePostAnnotationViewReuseId];
    if(self)
    {
        // handle our own callout
        self.canShowCallout = NO;
        
        // set size of view
        CGRect myFrame = self.frame;
        myFrame.size = CGSizeMake(80.0f, 80.0f);
        self.frame = myFrame;
        
        // setup tradepost image
        UIImage *annotationImage = [UIImage imageNamed:@"Homebase.png"];
        CGRect resizeRect = CGRectMake(0.0f, 0.0f, 80.0f, 80.0f);
        UIGraphicsBeginImageContext(resizeRect.size);
        [annotationImage drawInRect:resizeRect];
        UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        self.opaque = NO;
        
        // annotation-view anchor is at the center of the view;
        // so, shift the image so that its bottom is at the coordinate
        UIView* contentView = [[UIView alloc] initWithFrame:myFrame];
        UIImageView* imageView = [[UIImageView alloc] initWithImage:resizedImage];
        [imageView setFrame:CGRectMake(myFrame.origin.x, 
                                       myFrame.origin.y-(resizeRect.size.height/4.0f), 
                                       resizeRect.size.width, resizeRect.size.height)];
        [contentView addSubview:imageView];
        
        [self addSubview:contentView];
    }
    return self;
}

#pragma mark - MKAnnotationView
- (void)setAnnotation:(id<MKAnnotation>)annotation
{
    [super setAnnotation:annotation];
    self.enabled = YES;
}

#pragma mark - PogMapAnnotationViewProtocol
- (void)didSelectAnnotationViewInMap:(MKMapView*) mapView;
{    
    NSLog(@"tradepost selected");
}

- (void)didDeselectAnnotationViewInMap:(MKMapView*) mapView;
{
    NSLog(@"tradepost deselected");
}

@end
