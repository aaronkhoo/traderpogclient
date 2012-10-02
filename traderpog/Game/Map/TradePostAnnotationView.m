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
#import "GameNotes.h"
#import "MapControl.h"
#import "PogUIUtility.h"

NSString* const kTradePostAnnotationViewReuseId = @"PostAnnotationView";
NSString* const kKeyFlyerAtPost = @"flyerAtPost";
static const float kSmallLabelHeight = 20.0f;
static const float kTopImageSize = 40.0f;
static const float kTopImageYOffset = -0.1f;

@interface TradePostAnnotationView ()
{
    NSObject<MKAnnotation,MapAnnotationProtocol>* _calloutAnnotation;
}
- (void) handleFlyerStateChanged:(NSNotification*)note;
- (void) handleFlyerLoadTimerChanged:(NSNotification*)note;
@end

@implementation TradePostAnnotationView
@synthesize imageView = _imageView;
@synthesize frontImageView = _frontImageView;
@synthesize frontLeftView = _frontLeftView;
@synthesize topImageView = _topImageView;
@synthesize smallLabel = _smallLabel;

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

        // create primary image view
        _imageView = [[UIImageView alloc] initWithFrame:imageRect];
        [contentView addSubview:_imageView];

        // create two front image views for rendering various anim states
        CGRect frRect = imageRect;
        frRect.origin = CGPointMake(frRect.origin.x + (0.5f * frRect.size.width), frRect.origin.y);
        _frontImageView = [[UIImageView alloc] initWithFrame:frRect];
        [_frontImageView setHidden:YES];
        [contentView addSubview:_frontImageView];
        CGRect flRect = imageRect;
        flRect.origin = CGPointMake(flRect.origin.x - (0.5f * frRect.size.width), flRect.origin.y);
        _frontLeftView = [[UIImageView alloc] initWithFrame:flRect];
        [_frontLeftView setHidden:YES];
        [contentView addSubview:_frontLeftView];
        
        // create top image (used for alert icon)
        float topX = (0.5f * (myFrame.size.width - kTopImageSize));
        float topY = imageRect.origin.y + (kTopImageYOffset * imageRect.size.height);
        CGRect topRect = CGRectMake(topX, topY, kTopImageSize, kTopImageSize);
        _topImageView = [[UIImageView alloc] initWithFrame:topRect];
        [_topImageView setBackgroundColor:[UIColor clearColor]];
        [_topImageView setHidden:YES];
        [contentView addSubview:_topImageView];
        
        // small text label at bottom
        CGRect smallLabelRect = CGRectMake(imageRect.origin.x, imageRect.origin.y + imageRect.size.height,
                                           imageRect.size.width, kSmallLabelHeight);
        _smallLabel = [[UILabel alloc] initWithFrame:smallLabelRect];
        [_smallLabel setAdjustsFontSizeToFitWidth:YES];
        [_smallLabel setFont:[UIFont fontWithName:@"Marker Felt" size:20.0f]];
        [_smallLabel setText:@"Hello"];
        [_smallLabel setTextAlignment:UITextAlignmentCenter];
        [_smallLabel setBackgroundColor:[UIColor clearColor]];
        [_smallLabel setHidden:YES];
        [contentView addSubview:_smallLabel];
        
        _calloutAnnotation = nil;

        // observe flyer-state-changed notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFlyerStateChanged:) name:kGameNoteFlyerStateChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFlyerLoadTimerChanged:) name:kGameNoteFlyerLoadTimerChanged object:nil];
    }
    return self;
}

- (void) dealloc
{
    TradePost* post = (TradePost*) [self annotation];
    [post removeFlyerAtPostObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:kGameNoteFlyerStateChanged];
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:kGameNoteFlyerLoadTimerChanged];
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

- (void) handleFlyerStateChanged:(NSNotification *)note
{
    Flyer* flyer = (Flyer*)[note object];
    //NSLog(@"flyer state changed to %d", [flyer state]);
    TradePost* post = (TradePost*)[self annotation];
    if(post)
    {
        //NSLog(@"flyer-state-changed post %@", [post postId]);
        if([flyer isEqual:[post flyerAtPost]])
        {
            NSLog(@"flyer-state-changed post %@ refreshRender", [post postId]);
            [post refreshRenderForAnnotationView:self];
        }
    }
}

- (void) handleFlyerLoadTimerChanged:(NSNotification *)note
{
    Flyer* flyer = (Flyer*)[note object];
    TradePost* post = (TradePost*)[self annotation];
    if(post)
    {
        if([flyer isEqual:[post flyerAtPost]])
        {
            NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:[flyer stateBegin]];
            NSTimeInterval remaining = [flyer getFlyerLoadDuration] - elapsed;
            if(0.0f > remaining)
            {
                remaining = 0.0f;
            }
            [self.smallLabel setText:[PogUIUtility stringFromTimeInterval:remaining]];
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
        [post removeFlyerAtPostObserver:self];
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
            [[[[GameManager getInstance] gameViewController] mapControl] defaultZoomCenterOn:[tradePost coord] animated:YES];
        }
        else
        {
            // selection not allowed; deselect it
            [mapView deselectAnnotation:[self annotation] animated:NO];
        }
    }

    // remove game-event alert icon if one is being displayed on this post
    TradePost* post = (TradePost*)[self annotation];
    Flyer* flyer = [post flyerAtPost];
    if(flyer && [flyer gameEvent])
    {
        flyer.gameEvent = nil;
        [post refreshRenderForAnnotationView:self];
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
