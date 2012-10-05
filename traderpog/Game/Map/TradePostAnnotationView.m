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
#import "TradeManager.h"
#import "Flyer.h"
#import "FlyerPath.h"
#import "FlyerCallout.h"
#import "GameNotes.h"
#import "GameColors.h"
#import "MapControl.h"
#import "ItemBubble.h"
#import "ItemBuyView.h"
#import "PogUIUtility.h"

NSString* const kTradePostAnnotationViewReuseId = @"PostAnnotationView";
NSString* const kKeyFlyerAtPost = @"flyerAtPost";
static const float kSmallLabelHeight = 20.0f;
static const float kBubbleSize = 60.0f;
static const float kBubbleYOffset = -0.2f;
static const float kBubbleBorderWidth = 2.0f;
static const float kExclamationSize = 40.0f;
static const float kExclamationYOffset = -0.1f;

@interface TradePostAnnotationView ()
{
    NSObject<MKAnnotation,MapAnnotationProtocol>* _calloutAnnotation;
}
- (void) handleFlyerStateChanged:(NSNotification*)note;
- (void) handleFlyerLoadTimerChanged:(NSNotification*)note;
- (void) handleFlyerAtPostChanged:(NSNotification*)note;
- (void) handleBuyClose:(id)sender;
- (void) handleBuyOk:(id)sender;
@end

@implementation TradePostAnnotationView
@synthesize imageView = _imageView;
@synthesize frontImageView = _frontImageView;
@synthesize frontLeftView = _frontLeftView;
@synthesize excImageView = _excImageView;
@synthesize itemBubble = _itemBubble;
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
        myFrame.size = CGSizeMake(35.0f, 75.0f);
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
        
        // item bubble
        float bubbleX = (0.5f * (myFrame.size.width - kBubbleSize));
        float bubbleY = imageRect.origin.y + (kBubbleYOffset * imageRect.size.height);
        CGRect bubbleRect = CGRectMake(bubbleX, bubbleY, kBubbleSize, kBubbleSize);
        _itemBubble = [[ItemBubble alloc] initWithFrame:bubbleRect borderWidth:kBubbleBorderWidth
                                                  color:[GameColors bubbleColorScanWithAlpha:0.8f]
                                            borderColor:[GameColors bubbleColorPostsWithAlpha:1.0f]];
        [_itemBubble setHidden:YES];
        [contentView addSubview:_itemBubble];
        
        // small-frame for top image view (for exclamation mark)
        float excX = (0.5f * (myFrame.size.width - kExclamationSize));
        float excY = imageRect.origin.y + (kExclamationYOffset * imageRect.size.height);
        CGRect exclamationRect = CGRectMake(excX, excY, kExclamationSize, kExclamationSize);
        _excImageView = [[UIImageView alloc] initWithFrame:exclamationRect];
        [_excImageView setBackgroundColor:[UIColor clearColor]];
        [_excImageView setHidden:YES];
        [contentView addSubview:_excImageView];
        
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFlyerAtPostChanged:) name:kGameNotePostFlyerChanged object:nil];
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:kGameNotePostFlyerChanged];
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
            //NSLog(@"flyer-state-changed post %@ refreshRender", [post postId]);
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

- (void) handleFlyerAtPostChanged:(NSNotification *)note
{
    TradePost* post = (TradePost*)[note object];
    TradePost* selfPost = (TradePost*)[self annotation];
    if(post  && [selfPost isEqual:post])
    {
        // if this notification was sent by my annotation, refresh myself
        [selfPost refreshRenderForAnnotationView:self];
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

#pragma mark - popup ui
static const float kBuyViewYOffset = -94.0f;
- (void) showBuyViewInMap:(MKMapView*)mapView forPost:(TradePost*)tradePost
{
    GameViewController* controller = [[GameManager getInstance] gameViewController];
    ItemBuyView* buyView = (ItemBuyView*)[controller dequeueModalViewWithIdentifier:kItemBuyViewReuseIdentifier];
    if(!buyView)
    {
        UIView* parent = [mapView superview];
        buyView = [[ItemBuyView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 0.0f, 0.0f)];
        CGRect buyFrame = [PogUIUtility createCenterFrameWithSize:buyView.nibContentView.bounds.size
                                                          inFrame:parent.bounds
                                                    withFrameSize:buyView.nibView.bounds.size];
        buyFrame.origin.y += kBuyViewYOffset;
        [buyView setFrame:buyFrame];
    }
    [buyView addButtonTarget:self];
    
    // trade item info
    [tradePost refreshRenderForItemBuyView:buyView];

    // show it
    [controller showModalView:buyView animated:YES];
}

- (void) handleBuyClose:(id)sender
{
    [[GameManager getInstance] haltMapAnnotationCalloutsForDuration:0.5];
}

- (void) handleBuyOk:(id)sender
{
    TradePost* destPost = (TradePost*)[self annotation];
    if(destPost)
    {
        if([destPost isMemberOfClass:[MyTradePost class]])
        {
            // TODO: handle going home
        }
        else
        {
            // other's post
            if(![[TradeManager getInstance] playerHasIdleFlyers])
            {
                // inform player they cannot afford the order
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Flyers busy"
                                                                message:@"Need idle Flyer to place this order"
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            else if(![[TradeManager getInstance] playerCanAffordItemsAtPost:destPost])
            {
                // inform player they cannot afford the order
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not enough coins"
                                                                message:@"More coins needed to place this order"
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            else
            {
                // player can order
                [[[[GameManager getInstance] gameViewController] mapControl] defaultZoomCenterOn:[destPost coord] animated:YES];
                [[GameManager getInstance] showFlyerSelectForBuyAtPost:destPost];
            }
            
        }
    }
    [[GameManager getInstance] haltMapAnnotationCalloutsForDuration:0.5];
}

#pragma mark - PogMapAnnotationViewProtocol
static const float kBuyViewCenterYOffset = -10.0f;
- (CLLocationCoordinate2D) buyViewCenterCoordForTradePost:(TradePost*)tradePost
                                                inMapView:(MKMapView*)mapView
{
    CLLocationCoordinate2D result = [tradePost coord];
    
    UIView* modalView = [[[GameManager getInstance] gameViewController] view];
    CGPoint resultPoint = [mapView convertCoordinate:result toPointToView:modalView];
    resultPoint.y += kBuyViewCenterYOffset;
    result = [mapView convertPoint:resultPoint toCoordinateFromView:modalView];
    return result;
}

- (void)didSelectAnnotationViewInMap:(MKMapView*) mapView;
{
    TradePost* tradePost = (TradePost*) [self annotation];

    CLLocationCoordinate2D centerCoord = [mapView centerCoordinate];
    BOOL doZoomAdjustment = NO;
    // if map not in callout zoom-level or not zoomEnabled, address that by setting the map to the necessary zoom-level
    // so that player can select it more readily the next time they tap
    if((![[GameManager getInstance] mapIsInCalloutZoomLevelRange]) || (![[GameManager getInstance] mapIsZoomEnabled]))
    {
        doZoomAdjustment = YES;
        centerCoord = [tradePost coord];
    }
    
    if(!_calloutAnnotation)
    {
        if([[GameManager getInstance] canShowMapAnnotationCallout])
        {
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
                [self showBuyViewInMap:mapView forPost:tradePost];
                [self.itemBubble setHidden:YES];
                [self.imageView setTransform:CGAffineTransformMakeScale(2.0f, 2.0f)];
                centerCoord = [self buyViewCenterCoordForTradePost:tradePost inMapView:mapView];
                doZoomAdjustment = YES;
            }
            if(_calloutAnnotation)
            {
                [mapView addAnnotation:_calloutAnnotation];
            }
        }
        else
        {
            // selection not allowed; deselect it
            [mapView deselectAnnotation:[self annotation] animated:NO];
        }
        
        if(doZoomAdjustment)
        {
            [[[[GameManager getInstance] gameViewController] mapControl] defaultZoomCenterOn:centerCoord animated:YES];
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
    [[[GameManager getInstance] gameViewController] hideModalViewAnimated:YES];
    TradePost* post = (TradePost*)[self annotation];
    [post refreshRenderForAnnotationView:self];

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
