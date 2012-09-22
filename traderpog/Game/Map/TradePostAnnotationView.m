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
#import "TradePost+Render.h"
#import "PlayerPostCallout.h"
#import "PlayerPostCalloutView.h"
#import "GameManager.h"
#import "Flyer.h"
#import "FlyerPath.h"
#import "FlyerCallout.h"

NSString* const kTradePostAnnotationViewReuseId = @"PostAnnotationView";
NSString* const kKeyFlyerAtPost = @"flyerAtPost";

@interface TradePostAnnotationView ()
{
    NSObject<MKAnnotation,MapAnnotationProtocol>* _calloutAnnotation;
}
@end

@implementation TradePostAnnotationView
@synthesize imageView = _imageView;
@synthesize frontImageView = _frontImageView;

- (id) initWithAnnotation:(NSObject<MKAnnotation>*)annotation
{
    self = [super initWithAnnotation:annotation reuseIdentifier:kTradePostAnnotationViewReuseId];
    if(self)
    {
        // handle our own callout
        self.canShowCallout = NO;
        self.enabled = YES;
        
        // set size of view
        CGRect myFrame = self.frame;
        myFrame.size = CGSizeMake(50.0f, 50.0f);
        self.frame = myFrame;
        
        // offset annotation so that anchor point is about the bottom of the frame
        // (primarily so that flight-path end-points are positioned right underneath the post)
        self.centerOffset = CGPointMake(0.0f, -(myFrame.size.height * 0.3f));

        float imageWidth = 80.0f;
        float imageHeight = 80.0f;
        float imageOriginX = myFrame.origin.x - (0.5f * (imageWidth - myFrame.size.width));
        float imageOriginY = myFrame.origin.y - (imageWidth - myFrame.size.height);
        CGRect imageRect = CGRectMake(imageOriginX, imageOriginY, imageWidth, imageHeight);
        self.opaque = NO;
        
        UIView* contentView = [[UIView alloc] initWithFrame:myFrame];
        [self addSubview:contentView];

        // create two layers of image-views for rendering
        _imageView = [[UIImageView alloc] initWithFrame:imageRect];
        [contentView addSubview:_imageView];
        _frontImageView = [[UIImageView alloc] initWithFrame:imageRect];
        [_frontImageView setHidden:YES];
        [contentView addSubview:_frontImageView];
        
        _calloutAnnotation = nil;
    }
    return self;
}

- (void) dealloc
{
    TradePost* post = (TradePost*) [self annotation];
    [post removeObserver:self forKeyPath:kKeyFlyerAtPost];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
    if([keyPath isEqualToString:kKeyFlyerAtPost])
    {
        TradePost* selfPost = (TradePost*)[self annotation];
        TradePost* observedPost = (TradePost*)object;
        if([selfPost isEqual:observedPost])
        {
            NSLog(@"refreshed view for observedPost %@", [observedPost postId]);
            [observedPost refreshRenderForAnnotationView:self];
        }
        else
        {
            NSLog(@"this view has been reused by another post %@; remove observation on observed post %@",
                  [selfPost postId], [observedPost postId]);
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
}

- (void) prepareForReuse
{
    TradePost* post = (TradePost*) [self annotation];
    if(post)
    {
        [post removeObserver:self forKeyPath:kKeyFlyerAtPost];
    }
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
                Flyer* flyer = [tradePost flyerAtPost];
                if(!flyer || (kFlyerStateIdle == [flyer state]))
                {
                    // show player-post callout if own post and flyer is idle
                    PlayerPostCallout* callout = [[PlayerPostCallout alloc] initWithTradePost:tradePost];
                    callout.parentAnnotationView = self;
                    _calloutAnnotation = callout;
                }
                else if((kFlyerStateWaitingToUnload == [flyer state]) ||
                        (kFlyerStateUnloading == [flyer state]))
                {
                    // show flyer callout if flyer is waiting to unload
                    FlyerCallout* callout = [[FlyerCallout alloc] initWithFlyer:flyer];
                    callout.parentAnnotationView = self;
                    _calloutAnnotation = callout;
                }
            }
            else if([tradePost flyerAtPost])
            {
                // if not own post and there's a flyer at post, then show flyer callout instead
                Flyer* flyer = [tradePost flyerAtPost];
                if(![[flyer path] isEnroute])
                {
                    // show Flyer Callout if not enroute
                    FlyerCallout* callout = [[FlyerCallout alloc] initWithFlyer:flyer];
                    callout.parentAnnotationView = self;
                    _calloutAnnotation = callout;
                }
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
