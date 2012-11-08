//
//  TradePostAnnotationView.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/15/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "TradePostAnnotationView.h"
#import "ImageManager.h"
#import "MyTradePost.h"
#import "TradePost.h"
#import "TradePost+Render.h"
#import "TradeManager.h"
#import "GameManager.h"
#import "GameViewController.h"
#import "TradeManager.h"
#import "Flyer.h"
#import "FlyerPath.h"
#import "FlyerMgr.h"
#import "GameNotes.h"
#import "GameColors.h"
#import "MapControl.h"
#import "ItemBubble.h"
#import "ItemBuyView.h"
#import "PostAccelView.h"
#import "PogUIUtility.h"
#import "SoundManager.h"
#import "Player.h"
#import "Player+Shop.h"
#import "FlyerInfoView.h"
#import "CircleButton.h"
#import "GameAnim.h"
#import "FlyerGo.h"
#import <QuartzCore/QuartzCore.h>

NSString* const kTradePostAnnotationViewReuseId = @"PostAnnotationView";
NSString* const kKeyFlyerAtPost = @"flyerAtPost";
static const float kSmallLabelHeight = 20.0f;
static const float kBubbleSize = 60.0f;
static const float kBubbleYOffset = -0.2f;
static const float kBubbleBorderWidth = 2.0f;
static const float kExclamationSize = 40.0f;
static const float kExclamationYOffset = 0.0f;
static const float kCountdownWidth = 60.0f;
static const float kCountdownHeight = 25.0f;
static const float kCountdownBorderWidth = 2.0f;
static const float kCountdownCornerRadius = 8.0f;
static const float kCountdownYOffset = 1.0f;

@interface TradePostAnnotationView ()
- (void) handleFlyerStateChanged:(NSNotification*)note;
- (void) handleFlyerLoadTimerChanged:(NSNotification*)note;
- (void) handleFlyerAtPostChanged:(NSNotification*)note;
- (void) handleBuyOk:(id)sender;
- (void) handleAccelOk:(id)sender;
@end

@implementation TradePostAnnotationView
@synthesize imageView = _imageView;
@synthesize frontImageView = _frontImageView;
@synthesize frontLeftView = _frontLeftView;
@synthesize excImageView = _excImageView;
@synthesize itemBubble = _itemBubble;
@synthesize countdownView = _countdownView;

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

        // item bubble
        float bubbleX = (0.5f * (myFrame.size.width - kBubbleSize));
        float bubbleY = imageRect.origin.y + (kBubbleYOffset * imageRect.size.height);
        CGRect bubbleRect = CGRectMake(bubbleX, bubbleY, kBubbleSize, kBubbleSize);
        _itemBubble = [[ItemBubble alloc] initWithFrame:bubbleRect borderWidth:kBubbleBorderWidth
                                                  color:[GameColors bubbleColorScanWithAlpha:1.0f]
                                            borderColor:[GameColors bubbleColorPostsWithAlpha:1.0f]];
        [_itemBubble setHidden:YES];
        [contentView addSubview:_itemBubble];
        
        // countdown view
        float countdownX = (0.5f * (myFrame.size.width - kCountdownWidth));
        float countdownY = bubbleY - kCountdownHeight + kCountdownYOffset;
        CGRect countdownRect = CGRectMake(countdownX, countdownY, kCountdownWidth, kCountdownHeight);
        _countdownView = [[UIView alloc] initWithFrame:countdownRect];
        [_countdownView setBackgroundColor:[GameColors bubbleColorScanWithAlpha:1.0f]];
        [PogUIUtility setBorderOnView:_countdownView
                                width:kCountdownBorderWidth
                                color:[GameColors borderColorPostsWithAlpha:1.0f]
                         cornerRadius:kCountdownCornerRadius];
        [_countdownView setHidden:YES];
        [contentView addSubview:_countdownView];
        
        CGRect countdownLabelRect = CGRectInset(_countdownView.bounds, kCountdownBorderWidth, kCountdownBorderWidth);
        _countdownLabel = [[UILabel alloc] initWithFrame:countdownLabelRect];
        [_countdownLabel setAdjustsFontSizeToFitWidth:YES];
        [_countdownLabel setFont:[UIFont fontWithName:@"Marker Felt" size:20.0f]];
        [_countdownLabel setText:@"Hello"];
        [_countdownLabel setTextColor:[GameColors gliderWhiteWithAlpha:1.0f]];
        [_countdownLabel setTextAlignment:UITextAlignmentCenter];
        [_countdownLabel setBackgroundColor:[UIColor clearColor]];
        [_countdownView addSubview:_countdownLabel];
        
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
                
        // small-frame for top image view (for exclamation mark)
        float excX = (0.5f * (myFrame.size.width - kExclamationSize));
        float excY = imageRect.origin.y + (kExclamationYOffset * imageRect.size.height);
        CGRect exclamationRect = CGRectMake(excX, excY, kExclamationSize, kExclamationSize);
        _excImageView = [[UIImageView alloc] initWithFrame:exclamationRect];
        [_excImageView setBackgroundColor:[UIColor clearColor]];
        [_excImageView setHidden:YES];
        [contentView addSubview:_excImageView];
        
        // observe flyer-state-changed notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFlyerStateChanged:) name:kGameNoteFlyerStateChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFlyerLoadTimerChanged:) name:kGameNoteFlyerLoadTimerChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFlyerAtPostChanged:) name:kGameNotePostFlyerChanged object:nil];
    }
    return self;
}

- (void) dealloc
{
    NSLog(@"TradePostAnnotationView dealloc");
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
            //[observedPost refreshRenderForAnnotationView:self];
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
            if(self.selected && ((kFlyerStateLoaded == [flyer state]) || (kFlyerStateIdle == [flyer state])))
            {
                // if I am selected across a flyer state-change that put me into a done state, deselect it
                [[GameManager getInstance].gameViewController.mapControl deselectAnnotation:self.annotation animated:NO];
            }
            
            if((kFlyerStateLoading == [flyer state]) || (kFlyerStateUnloading == [flyer state]))
            {
                // initialize countdown text for its appearance prior to the first timer callback
                [self.countdownLabel setText:[PogUIUtility stringFromTimeInterval:[flyer getFlyerLoadDuration]]];
            }
            
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
            [self.countdownLabel setText:[PogUIUtility stringFromTimeInterval:remaining]];
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
    [super setAnnotation:annotation];
}

#pragma mark - popup ui
static const float kBuyViewYOffset = -94.0f;
static const float kAccelViewYOffset = -94.0f;
- (void) showBuyViewForPost:(TradePost*)tradePost
{
    GameViewController* controller = [[GameManager getInstance] gameViewController];
    ItemBuyView* buyView = (ItemBuyView*)[controller dequeueModalViewWithIdentifier:kItemBuyViewReuseIdentifier];
    if(!buyView)
    {
        UIView* parent = [controller view];
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

    // adjust annotation view
    [self.itemBubble setHidden:YES];
    [UIView animateWithDuration:0.1f animations:^(void){
        [self.imageView setTransform:CGAffineTransformMakeScale(2.0f, 2.0f)];
    }];
}

- (void) showAccelViewForPost:(TradePost*)tradePost
{
    GameViewController* controller = [[GameManager getInstance] gameViewController];
    PostAccelView* popup = (PostAccelView*)[controller dequeueModalViewWithIdentifier:kPostAccelViewReuseIdentifier];
    if(!popup)
    {
        UIView* parent = [controller view];
        popup = [[PostAccelView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 0.0f, 0.0f)];
        CGRect popFrame = [PogUIUtility createCenterFrameWithSize:popup.nibContentView.bounds.size
                                                          inFrame:parent.bounds
                                                    withFrameSize:popup.nibView.bounds.size];
        popFrame.origin.y += kAccelViewYOffset;
        [popup setFrame:popFrame];
    }
    [popup addButtonTarget:self];
    
    // refresh content
    [popup refreshViewForFlyer:[tradePost flyerAtPost]];
    
    // show it
    [controller showModalView:popup animated:YES];
    
    // show anim
    if([tradePost flyerAtPost])
    {
        Flyer* flyer = [tradePost flyerAtPost];
        if(kFlyerStateLoading == [flyer state])
        {
            BOOL anim = [[GameAnim getInstance] refreshImageView:self.frontLeftView withClipNamed:@"loading"];
            if(anim)
            {
                [self.frontLeftView startAnimating];
                [self.frontLeftView setHidden:NO];
            }
        }
        else if(kFlyerStateUnloading == [flyer state])
        {
            BOOL anim = [[GameAnim getInstance] refreshImageView:self.frontLeftView withClipNamed:@"unloading"];
            if(anim)
            {
                [self.frontLeftView startAnimating];
                [self.frontLeftView setHidden:NO];
            }
        }
    }
    
    // adjust annotation view
    [self.itemBubble setHidden:YES];
    _frontImageView.layer.anchorPoint = CGPointMake(0.3f, 0.5f);
    _frontLeftView.layer.anchorPoint = CGPointMake(0.5f, 0.5f);
    [UIView animateWithDuration:0.1f animations:^(void){
        [self.frontImageView setTransform:CGAffineTransformMakeScale(1.5f, 1.5f)];
        [self.frontLeftView setTransform:CGAffineTransformMakeScale(1.5f, 1.5f)];
    }];
}

- (void) handleModalClose:(id)sender
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
            [[SoundManager getInstance] playClip:@"Pog_SFX_PopUP_Level2"];
            GameViewController* game = [[GameManager getInstance] gameViewController];
            FlyerGo* next = [[FlyerGo alloc] initWithNibName:@"FlyerGo" bundle:nil];
            [game showModalNavViewController:next completion:nil];
/*
            if(1 == [[FlyerMgr getInstance].playerFlyers count])
            {
                // if the player only has one flyer, skip the flyer wheel and send the flyer straight away
                if(![[TradeManager getInstance] playerHasIdleFlyers])
                {
                    // inform player they cannot afford the order
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Flyers busy"
                                                                    message:@"Need idle Flyer to visit this post"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"Ok"
                                                          otherButtonTitles:nil];
                    [alert show];
                }
                else
                {
                    Flyer* flyer = [[FlyerMgr getInstance].playerFlyers objectAtIndex:0];
                    [[TradeManager getInstance] flyer:flyer buyFromPost:destPost numItems:[destPost supplyLevel]];
                    [[GameManager getInstance] flyer:flyer departForTradePost:destPost];
                }
            }
            else
            {
                // multi-flyer, just show Flyer-Select
                [[[[GameManager getInstance] gameViewController] mapControl] defaultZoomCenterOn:[destPost coord] animated:YES];
                [[GameManager getInstance] showFlyerSelectForBuyAtPost:destPost];
            }
 */            
        }
    }
//    [[GameManager getInstance] haltMapAnnotationCalloutsForDuration:0.5];
}

- (void) handleAccelOk:(id)sender
{
    TradePost* destPost = (TradePost*)[self annotation];
    [[GameManager getInstance] haltMapAnnotationCalloutsForDuration:0.5];
    if(destPost && [destPost flyerAtPost])
    {
        Flyer* flyer = [destPost flyerAtPost];
        if((kFlyerStateLoaded == [flyer state]) ||
                (kFlyerStateIdle == [flyer state]))
        {
            // DISABLE_POSTWHEEL
            // TODO: Commented out from now since there's only one post for this release. Just send the
            //       flyer straight to that single post.
            // [[GameManager getInstance] showHomeSelectForFlyer:flyer];
            
            BOOL goingHome = [[GameManager getInstance] sendFlyerHome:flyer];
            if(goingHome)
            {
                [[SoundManager getInstance] playClip:@"Pog_SFX_PopUP_Level2"];
            }
            else
            {
                [[SoundManager getInstance] playClip:@"Pog_SFX_Select"];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Home Occupied"
                                                                message:@"Another Flyer is home or homebound. Send it somewhere else first."
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        }
        else
        {
            // extra help accelerated loading/unloading
            if([[Player getInstance] canAffordExtraHelp])
            {
                [[SoundManager getInstance] playClip:@"Pog_SFX_PopUP_Level2"];
                [[Player getInstance] buyExtraHelp];
                if(kFlyerStateLoading == [flyer state])
                {
                    [flyer gotoState:kFlyerStateLoaded];
                }
                else if(kFlyerStateUnloading == [flyer state])
                {
                    [flyer gotoState:kFlyerStateIdle];
                }
            }
            else
            {
                // player can't afford the extra help
                [[SoundManager getInstance] playClip:@"Pog_SFX_Select"];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not enough coins"
                                                                message:@"Sorry, gotta do it yourself this time"
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        }
    }
}

- (void) handleGoHomeFromFlyerInfo:(id)sender
{
    TradePost* curPost = (TradePost*)[self annotation];
    [[GameManager getInstance] haltMapAnnotationCalloutsForDuration:0.5];
    if(curPost && [curPost flyerAtPost])
    {
        Flyer* flyer = [curPost flyerAtPost];
        
        // DISABLE_POSTWHEEL
        // TODO: Commented out from now since there's only one post for this release. Just send the
        //       flyer straight to that single post.
        // [[GameManager getInstance] showHomeSelectForFlyer:flyer];
        
        BOOL goingHome = [[GameManager getInstance] sendFlyerHome:flyer];
        if(goingHome)
        {
            [[SoundManager getInstance] playClip:@"Pog_SFX_PopUP_Level2"];           
        }
        else
        {
            [[SoundManager getInstance] playClip:@"Pog_SFX_Select"];
            [[GameManager getInstance].gameViewController setKnobToSlice:kKnobSlicePost animated:YES];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Home Occupied"
                                                            message:@"Another Flyer is home or homebound. Send it somewhere else first."
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }
}

#pragma mark - flyer info
- (void) showInfoViewForFlyer:(Flyer*)flyer withTitle:(NSString*)title
{
    GameViewController* controller = [[GameManager getInstance] gameViewController];
    FlyerInfoView* popup = (FlyerInfoView*)[controller dequeueModalViewWithIdentifier:kFlyerInfoViewReuseIdentifier];
    if(!popup)
    {
        UIView* parent = [controller view];
        popup = [[FlyerInfoView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 0.0f, 0.0f)];
        CGRect popFrame = [PogUIUtility createCenterFrameWithSize:popup.nibContentView.bounds.size
                                                          inFrame:parent.bounds
                                                    withFrameSize:popup.nibView.bounds.size];
        [popup setFrame:popFrame];
    }
    [popup.closeCircle setButtonTarget:self action:@selector(handleModalClose:)];
    [popup.goCircle setButtonTarget:self action:@selector(handleGoHomeFromFlyerInfo:)];
    
    // refresh content
    [popup refreshViewForFlyer:flyer];
    if(title)
    {
        [popup.titleLabel setText:title];
    }
    
    // show it
    [controller showModalView:popup animated:YES];
}



#pragma mark - PogMapAnnotationViewProtocol
static const float kBuyViewCenterYOffset = -10.0f;
- (CLLocationCoordinate2D) buyViewCenterCoordForTradePost:(TradePost*)tradePost
                                                inMapView:(MKMapView*)mapView
{
    CLLocationCoordinate2D result = [tradePost coord];
    
    UIView* modalView = [[[GameManager getInstance] gameViewController] view];
    if(modalView)
    {
        CGPoint resultPoint = [mapView convertCoordinate:result toPointToView:modalView];
        resultPoint.y += kBuyViewCenterYOffset;
        result = [mapView convertPoint:resultPoint toCoordinateFromView:modalView];
    }
    return result;
}

- (void)didSelectAnnotationViewInMap:(MKMapView*) mapView;
{
    TradePost* tradePost = (TradePost*) [self annotation];
    BOOL dismissGameEvent = YES;
    
    [[SoundManager getInstance] playClip:@"Pog_SFX_PopUP_Level1"];

    CLLocationCoordinate2D centerCoord = [mapView centerCoordinate];
    BOOL doZoomAdjustment = NO;
    // if map not in callout zoom-level or not zoomEnabled, address that by setting the map to the necessary zoom-level
    // so that player can select it more readily the next time they tap
    if((![[GameManager getInstance] mapIsInCalloutZoomLevelRange]) || (![[GameManager getInstance] mapIsZoomEnabled]))
    {
        doZoomAdjustment = YES;
        centerCoord = [tradePost coord];
    }
    
    if([[GameManager getInstance] canShowPostAnnotationCallout])
    {
        if([tradePost isMemberOfClass:[MyTradePost class]])
        {
            Flyer* flyer = [tradePost flyerAtPost];
            if(!flyer || (kFlyerStateIdle == [flyer state]))
            {
                MyTradePost* myPost = (MyTradePost*)tradePost;
                [[GameManager getInstance].gameViewController showMyPostMenuForPost:myPost];
                centerCoord = [tradePost coord];
                doZoomAdjustment = YES;
            }
            else if(kFlyerStateWaitingToUnload == [flyer state])
            {
                // if in waiting state, proceed to next state without a callout
                [flyer gotoState:kFlyerStateUnloading];
                [mapView deselectAnnotation:[self annotation] animated:NO];
            }
            else if(kFlyerStateUnloading == [flyer state])
            {
                [self showAccelViewForPost:tradePost];
                centerCoord = [self buyViewCenterCoordForTradePost:tradePost inMapView:mapView];
                doZoomAdjustment = YES;
            }
            else
            {
                // should not get here, but if we somehow do, it's an error;
                // show MyPost's menu anyway
                MyTradePost* myPost = (MyTradePost*)tradePost;
                [[GameManager getInstance].gameViewController showMyPostMenuForPost:myPost];
                centerCoord = [tradePost coord];
                doZoomAdjustment = YES;
            }
        }
        else if([tradePost flyerAtPost])
        {
            // if not own post and there's a flyer at post
            Flyer* flyer = [tradePost flyerAtPost];
            if(![[flyer path] isEnroute])
            {
                // if in a waiting state, proceed to next state right away without a callout
                if(kFlyerStateWaitingToLoad == [flyer state])
                {
                    [flyer gotoState:kFlyerStateLoading];
                    [mapView deselectAnnotation:[self annotation] animated:NO];
                }
                else if(kFlyerStateLoaded == [flyer state])
                {
                    // flyer loaded and ready to go, show Flyer Info
                    [self showInfoViewForFlyer:flyer withTitle:nil];
                    centerCoord = [self buyViewCenterCoordForTradePost:tradePost inMapView:mapView];
                    doZoomAdjustment = YES;
                }
                else
                {
                    [self showAccelViewForPost:tradePost];
                    centerCoord = [self buyViewCenterCoordForTradePost:tradePost inMapView:mapView];
                    doZoomAdjustment = YES;
                }
            }
        }
        else if([tradePost getInboundFlyer])
        {
            // if there is a flyer inbound, show its Flyer Info instead and disallow
            // player from sending another flyer
            [self showInfoViewForFlyer:[tradePost getInboundFlyer] withTitle:@"Inbound"];
            centerCoord = [self buyViewCenterCoordForTradePost:tradePost inMapView:mapView];
            doZoomAdjustment = YES;            
        }
        else
        {
            // otherwise, let player Buy from this post
            [self showBuyViewForPost:tradePost];
            centerCoord = [self buyViewCenterCoordForTradePost:tradePost inMapView:mapView];
            doZoomAdjustment = YES;
        }
    }
    else
    {
        // selection not allowed; deselect it
        [mapView deselectAnnotation:[self annotation] animated:NO];
        dismissGameEvent = NO;
    }
    
    if(doZoomAdjustment)
    {
        [[[[GameManager getInstance] gameViewController] mapControl] defaultZoomCenterOn:centerCoord animated:YES];
    }

    if(dismissGameEvent)
    {
        // remove game-event alert icon if one is being displayed on this post
        TradePost* post = (TradePost*)[self annotation];
        Flyer* flyer = [post flyerAtPost];
        if(flyer && [flyer gameEvent])
        {
            flyer.gameEvent = nil;
            [post refreshRenderForAnnotationView:self];
        }
        else if ([tradePost gameEvent])
        {
            tradePost.gameEvent = nil;
            [post refreshRenderForAnnotationView:self];
        }
    }
}

- (void)didDeselectAnnotationViewInMap:(MKMapView*) mapView;
{
    [[[GameManager getInstance] gameViewController] closeModalViewAnimated:NO];
    TradePost* post = (TradePost*)[self annotation];
    [post refreshRenderForAnnotationView:self];

    [self.frontLeftView stopAnimating];
    [self.frontLeftView setAnimationImages:nil];
    [self.frontLeftView setHidden:YES];

    if([post isMemberOfClass:[MyTradePost class]])
    {
        [[GameManager getInstance].gameViewController dismissMyPostMenuAnimated:YES];
    }
}

@end
