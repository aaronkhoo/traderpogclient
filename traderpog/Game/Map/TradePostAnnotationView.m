//
//  TradePostAnnotationView.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/15/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "TradePostAnnotationView.h"
#import "TradePostCallout.h"
#import "ImageManager.h"
#import "MyTradePost.h"
#import "TradePost.h"
#import "PlayerPostCallout.h"
#import "PlayerPostCalloutView.h"
#import "GameManager.h"

NSString* const kTradePostAnnotationViewReuseId = @"PostAnnotationView";
static NSString* const kKeyTradePostHasFlyer = @"hasFlyer";

@interface TradePostAnnotationView ()
{
    NSObject<MKAnnotation,MapAnnotationProtocol>* _calloutAnnotation;
}
@end

@implementation TradePostAnnotationView
@synthesize imageView = _imageView;
- (id) initWithAnnotation:(NSObject<MKAnnotation>*)annotation
{
    self = [super initWithAnnotation:annotation reuseIdentifier:kTradePostAnnotationViewReuseId];
    if(self)
    {
        // handle our own callout
        self.canShowCallout = NO;
        self.enabled = YES;
        
        TradePost* tradePost = (TradePost*)annotation;
        
        // set size of view
        CGRect myFrame = self.frame;
        myFrame.size = CGSizeMake(50.0f, 50.0f);
        self.frame = myFrame;
        
        // offset annotation so that anchor point is at the bottom of the frame
        self.centerOffset = CGPointMake(0.0f, -(myFrame.size.height * 0.5f));
        
        // setup tradepost image
        UIImage* annotationImage = nil;
        if([tradePost isMemberOfClass:[MyTradePost class]])
        {
            annotationImage = [[ImageManager getInstance] getImage:[tradePost imgPath]
                                                     fallbackNamed:@"b_flyerlab.png"];
        }
        else
        {
            annotationImage = [[ImageManager getInstance] getImage:[tradePost imgPath]
                                                     fallbackNamed:@"b_flyerlab.png"];
        }
        float imageWidth = 80.0f;
        float imageHeight = 80.0f;
        float imageOriginX = myFrame.origin.x - (0.5f * (imageWidth - myFrame.size.width));
        float imageOriginY = myFrame.origin.y - (imageWidth - myFrame.size.height);
        CGRect imageRect = CGRectMake(imageOriginX, imageOriginY, imageWidth, imageHeight);
        /*
        CGRect resizeRect = CGRectMake(0.0f, 0.0f, 120.0f, 120.0f);
        UIGraphicsBeginImageContext(resizeRect.size);
        [annotationImage drawInRect:resizeRect];
        UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
         */
        UIImage* resizedImage = annotationImage;
        self.opaque = NO;
        
        // annotation-view anchor is at the center of the view;
        // so, shift the image so that its bottom is at the coordinate
        UIView* contentView = [[UIView alloc] initWithFrame:myFrame];
        _imageView = [[UIImageView alloc] initWithImage:resizedImage];
        [_imageView setFrame:imageRect];
        [contentView addSubview:_imageView];
        
        [self addSubview:contentView];
        
        _calloutAnnotation = nil;
        
        [tradePost addObserver:self forKeyPath:kKeyTradePostHasFlyer options:0 context:nil];
    }
    return self;
}

- (void) dealloc
{
    TradePost* post = (TradePost*) [self annotation];
    [post removeObserver:self forKeyPath:kKeyTradePostHasFlyer];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
    if([keyPath isEqualToString:kKeyTradePostHasFlyer])
    {
        TradePost* post = (TradePost*)object;
        if(![post isMemberOfClass:[MyTradePost class]])
        {
            // foreign Posts' touchability depends on whether they
            // have flyers on them
            if([post hasFlyer])
            {
                // if a flyer landed on this Post, disable it from receiving touch events
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
//    self.enabled = YES;
}

#pragma mark - PogMapAnnotationViewProtocol
- (void)didSelectAnnotationViewInMap:(MKMapView*) mapView;
{    
    if(!_calloutAnnotation)
    {
        if([[GameManager getInstance] canShowMapAnnotationCallout])
        {
            TradePost* tradePost = (TradePost*) [self annotation];
            if([tradePost isMemberOfClass:[MyTradePost class]])
            {
                // show player-post callout if own post
                PlayerPostCallout* callout = [[PlayerPostCallout alloc] initWithTradePost:tradePost];
                callout.parentAnnotationView = self;
                _calloutAnnotation = callout;
            }
            else
            {
                // otherwise, show tradepost callout
                TradePostCallout* callout = [[TradePostCallout alloc] initWithTradePost:tradePost];
                callout.parentAnnotationView = self;
                _calloutAnnotation = callout;
            }
            [mapView addAnnotation:_calloutAnnotation];
        }
        else
        {
            // selection not allowed; deselect it
            [mapView deselectAnnotation:[self annotation] animated:NO];
        }
    }
}

- (void)didDeselectAnnotationViewInMap:(MKMapView*) mapView;
{
    if(_calloutAnnotation)
    {
        if([_calloutAnnotation isMemberOfClass:[PlayerPostCallout class]])
        {
            PlayerPostCalloutView* calloutView = (PlayerPostCalloutView*) [mapView viewForAnnotation:_calloutAnnotation];
            [calloutView animateOut];
        }
        else
        {
            [mapView removeAnnotation:_calloutAnnotation];
        }
        _calloutAnnotation = nil;
    }
}

@end
