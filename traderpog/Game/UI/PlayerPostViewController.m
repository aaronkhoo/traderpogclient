//
//  PlayerPostViewController.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/19/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "PlayerPostViewController.h"
#import "CircleButton.h"
#import "GameColors.h"
#import "PogUIUtility.h"
#import "GameManager.h"
#import "MyTradePost.h"
#import "FlyerLabViewController.h"
#import "TradeManager.h"
#import "GameManager.h"
#import "GameViewController.h"
#import "MapControl.h"
#import "PostRestockConfirmScreen.h"
#import "TradePostMgr.h"

NSString* const kMyPostMenuCloseId = @"MyPostMenuClose";

static const float kCircleDist = 80.0f;
static const float kCloseBorderWidth = 4.0f;
static const float kBorderWidth = 3.0f;
static const float kBubbleOutScale = 1.4f;
static const float kBubbleInitScale = 0.1f;
static const float kBubbleDisabledAlpha = 0.6f;

@interface PlayerPostViewController ()
{
    __weak NSObject<ModalNavDelegate>* _delegate;
}
- (void) didPressBeacon:(id)sender;
- (void) didPressFlyer:(id)sender;
- (void) didPressRestock:(id)sender;
- (void) didPressClose:(id)sender;
- (void) refreshSubframesWithFrame:(CGRect)targetFrame;
- (void) setupContent;
@end

@implementation PlayerPostViewController
@synthesize centerFrame = _centerFrame;
@synthesize myPost = _myPost;
- (id)initWithCenterFrame:(CGRect)centerFrame
                 delegate:(NSObject<ModalNavDelegate> *)delegate
{
    self = [super initWithNibName:@"PlayerPostViewController" bundle:nil];
    if(self)
    {
        _centerFrame = centerFrame;
        _delegate = delegate;
        _myPost = nil;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSAssert(false, @"call initWithCenterFrame: to create InfoViewController");
    return nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.closeCircle setButtonTarget:self action:@selector(didPressClose:)];
    [self.beaconCircle setButtonTarget:self action:@selector(didPressBeacon:)];
    [self.flyerCircle setButtonTarget:self action:@selector(didPressFlyer:)];
    [self.restockCircle setButtonTarget:self action:@selector(didPressRestock:)];
    [self.closeCircle setBackgroundColor:[UIColor clearColor]];
    [self.closeCircle setBorderWidth:0.0f];

    [self refreshSubframesWithFrame:_centerFrame];
    [self setupContent];
    
}

- (void) viewWillAppear:(BOOL)animated
{
    [self setupContent];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    [self.closeCircle removeButtonTarget];
    [self.beaconCircle removeButtonTarget];
    [self.flyerCircle removeButtonTarget];
    [self.restockCircle removeButtonTarget];
    [self setCloseCircle:nil];
    [self setBeaconCircle:nil];
    [self setFlyerCircle:nil];
    [self setRestockCircle:nil];
    [self setBeaconBar:nil];
    [self setFlyerBar:nil];
    [self setRestockBar:nil];
    [self setFlyerLabel:nil];
    [super viewDidUnload];
}


- (void) presentInView:(UIView *)parentView belowSubview:(UIView*)subview animated:(BOOL)isAnimated
{
    if(subview)
    {
        [parentView insertSubview:self.view belowSubview:subview];
    }
    else
    {
        [parentView addSubview:self.view];
    }
    [self refreshSubframesWithFrame:_centerFrame];
    
    CGPoint downVec = CGPointMake(0.0f, -kCircleDist * 1.1f);
    CGPoint downVec2 = CGPointMake(0.0f, -kCircleDist);
    CGAffineTransform leaderTransform = CGAffineTransformMakeRotation(-1.75f * M_PI_4);
    CGAffineTransform memberTransform = CGAffineTransformMakeRotation(0.0f);
    CGAffineTransform moreTransform = CGAffineTransformMakeRotation(1.75f * M_PI_4);
    CGPoint leaderVec = CGPointApplyAffineTransform(downVec, leaderTransform);
    CGPoint leaderVec2 = CGPointApplyAffineTransform(downVec2, leaderTransform);
    CGPoint memberVec = CGPointApplyAffineTransform(downVec, memberTransform);
    CGPoint memberVec2 = CGPointApplyAffineTransform(downVec2, memberTransform);
    CGPoint moreVec = CGPointApplyAffineTransform(downVec, moreTransform);
    CGPoint moreVec2 = CGPointApplyAffineTransform(downVec2, moreTransform);
    
    if(isAnimated)
    {
        static const float kOutwardDur = 0.1f;
        static const float kBounceDur = 0.05f;
        static const float kSpacingDur = 0.02f;
        
        [self.closeCircle setTransform:CGAffineTransformMakeScale(kBubbleInitScale, kBubbleInitScale)];
        [UIView animateWithDuration:0.2f
                         animations:^(void){
                             [self.closeCircle setTransform:CGAffineTransformMakeScale(1.0f, 1.0f)];
                         }
                         completion:nil];
        
        [self.beaconCircle setTransform:CGAffineTransformMakeScale(kBubbleInitScale, kBubbleInitScale)];
        [UIView animateWithDuration:kOutwardDur
                              delay:0.0f
                            options:UIViewAnimationCurveEaseIn
                         animations:^(void){
                             CGAffineTransform s = CGAffineTransformMakeScale(kBubbleOutScale, kBubbleOutScale);
                             CGAffineTransform t = CGAffineTransformTranslate(s, leaderVec.x, leaderVec.y);
                             [self.beaconCircle setTransform:t];
                         }
                         completion:^(BOOL finished){
                             if(finished)
                             {
                                 [UIView animateWithDuration:kBounceDur
                                                       delay:0.0f
                                                     options:UIViewAnimationCurveEaseIn
                                                  animations:^(void){
                                                      CGAffineTransform s = CGAffineTransformMakeScale(1.0f, 1.0f);
                                                      CGAffineTransform t = CGAffineTransformTranslate(s, leaderVec2.x, leaderVec2.y);
                                                      [self.beaconCircle setTransform:t];
                                                  }
                                                  completion:nil];
                             }
                         }];
        
        [self.flyerCircle setTransform:CGAffineTransformMakeScale(kBubbleInitScale, kBubbleInitScale)];
        [UIView animateWithDuration:kOutwardDur
                              delay:kSpacingDur
                            options:UIViewAnimationCurveEaseIn
                         animations:^(void){
                             CGAffineTransform s = CGAffineTransformMakeScale(kBubbleOutScale, kBubbleOutScale);
                             CGAffineTransform t = CGAffineTransformTranslate(s, memberVec.x, memberVec.y);
                             [self.flyerCircle setTransform:t];
                         }
                         completion:^(BOOL finished){
                             if(finished)
                             {
                                 [UIView animateWithDuration:kBounceDur
                                                       delay:0.0f
                                                     options:UIViewAnimationCurveEaseIn
                                                  animations:^(void){
                                                      CGAffineTransform s = CGAffineTransformMakeScale(1.0f, 1.0f);
                                                      CGAffineTransform t = CGAffineTransformTranslate(s, memberVec2.x, memberVec2.y);
                                                      [self.flyerCircle setTransform:t];
                                                  }
                                                  completion:nil];
                             }
                         }];
        
        [self.restockCircle setTransform:CGAffineTransformMakeScale(kBubbleInitScale, kBubbleInitScale)];
        [UIView animateWithDuration:kOutwardDur
                              delay:kSpacingDur * 2.0f
                            options:UIViewAnimationCurveEaseIn
                         animations:^(void){
                             CGAffineTransform s = CGAffineTransformMakeScale(kBubbleOutScale, kBubbleOutScale);
                             CGAffineTransform t = CGAffineTransformTranslate(s, moreVec.x, moreVec.y);
                             [self.restockCircle setTransform:t];
                         }
                         completion:^(BOOL finished){
                             if(finished)
                             {
                                 [UIView animateWithDuration:kBounceDur
                                                       delay:0.0f
                                                     options:UIViewAnimationCurveEaseIn
                                                  animations:^(void){
                                                      CGAffineTransform s = CGAffineTransformMakeScale(1.0f, 1.0f);
                                                      CGAffineTransform t = CGAffineTransformTranslate(s, moreVec2.x, moreVec2.y);
                                                      [self.restockCircle setTransform:t];
                                                  }
                                                  completion:nil];
                             }
                         }];
    }
    else
    {
        [self.closeCircle setTransform:CGAffineTransformMakeScale(1.0f, 1.0f)];
        
        CGAffineTransform s = CGAffineTransformMakeScale(1.0f, 1.0f);
        [self.beaconCircle setTransform:CGAffineTransformTranslate(s, leaderVec2.x, leaderVec2.y)];
        [self.flyerCircle setTransform:CGAffineTransformTranslate(s, memberVec2.x, memberVec2.y)];
        [self.restockCircle setTransform:CGAffineTransformTranslate(s, moreVec2.x, moreVec2.y)];
    }
}

- (void) dismissAnimated:(BOOL)isAnimated
{
    if([self.view superview])
    {
        CGPoint downVec = CGPointMake(0.0f, -kCircleDist * 1.1f);
        CGAffineTransform leaderTransform = CGAffineTransformMakeRotation(-1.75f * M_PI_4);
        CGAffineTransform memberTransform = CGAffineTransformMakeRotation(0.0f);
        CGAffineTransform moreTransform = CGAffineTransformMakeRotation(1.75f * M_PI_4);
        CGPoint leaderVec = CGPointApplyAffineTransform(downVec, leaderTransform);
        CGPoint memberVec = CGPointApplyAffineTransform(downVec, memberTransform);
        CGPoint moreVec = CGPointApplyAffineTransform(downVec, moreTransform);
        
        if(isAnimated)
        {
            static const float kOutwardDur = 0.1f;
            static const float kBounceDur = 0.05f;
            static const float kSpacingDur = 0.02f;
            
            [UIView animateWithDuration:0.3f
                             animations:^(void){
                                 [self.closeCircle setTransform:CGAffineTransformMakeScale(0.1f, 0.1f)];
                             }
                             completion:^(BOOL finished){
                                 [self.view removeFromSuperview];
                             }];
            
            [UIView animateWithDuration:kBounceDur
                                  delay:0.0f
                                options:UIViewAnimationCurveEaseIn
                             animations:^(void){
                                 CGAffineTransform s = CGAffineTransformMakeScale(1.8f, 1.8f);
                                 CGAffineTransform t = CGAffineTransformTranslate(s, leaderVec.x, leaderVec.y);
                                 [self.beaconCircle setTransform:t];
                             }
                             completion:^(BOOL finished){
                                 if(finished)
                                 {
                                     [UIView animateWithDuration:kOutwardDur
                                                           delay:0.0f
                                                         options:UIViewAnimationCurveEaseIn
                                                      animations:^(void){
                                                          CGAffineTransform s = CGAffineTransformMakeScale(0.1f, 0.1f);
                                                          [self.beaconCircle setTransform:s];
                                                      }
                                                      completion:nil];
                                 }
                             }];
            
            [UIView animateWithDuration:kBounceDur
                                  delay:kSpacingDur
                                options:UIViewAnimationCurveEaseIn
                             animations:^(void){
                                 CGAffineTransform s = CGAffineTransformMakeScale(1.8f, 1.8f);
                                 CGAffineTransform t = CGAffineTransformTranslate(s, memberVec.x, memberVec.y);
                                 [self.flyerCircle setTransform:t];
                             }
                             completion:^(BOOL finished){
                                 if(finished)
                                 {
                                     [UIView animateWithDuration:kOutwardDur
                                                           delay:0.0f
                                                         options:UIViewAnimationCurveEaseIn
                                                      animations:^(void){
                                                          CGAffineTransform s = CGAffineTransformMakeScale(0.1f, 0.1f);
                                                          [self.flyerCircle setTransform:s];
                                                      }
                                                      completion:nil];
                                 }
                             }];
            
            [UIView animateWithDuration:kBounceDur
                                  delay:kSpacingDur * 2.0f
                                options:UIViewAnimationCurveEaseIn
                             animations:^(void){
                                 CGAffineTransform s = CGAffineTransformMakeScale(1.8f, 1.8f);
                                 CGAffineTransform t = CGAffineTransformTranslate(s, moreVec.x, moreVec.y);
                                 [self.restockCircle setTransform:t];
                             }
                             completion:^(BOOL finished){
                                 if(finished)
                                 {
                                     [UIView animateWithDuration:kOutwardDur
                                                           delay:0.0f
                                                         options:UIViewAnimationCurveEaseIn
                                                      animations:^(void){
                                                          CGAffineTransform s = CGAffineTransformMakeScale(0.1f, 0.1f);
                                                          [self.restockCircle setTransform:s];
                                                      }
                                                      completion:nil];
                                 }
                             }];
        }
        else
        {
            CGAffineTransform s = CGAffineTransformMakeScale(0.1f, 0.1f);
            [self.beaconCircle setTransform:s];
            [self.flyerCircle setTransform:s];
            [self.restockCircle setTransform:s];
            
            [self.view removeFromSuperview];
        }
    }
}

- (IBAction)didPressBackground:(id)sender
{
    // if user presses anywhere else in this view, close it
    [self didPressClose:sender];
}

#pragma mark - internals
- (void) refreshSubframesWithFrame:(CGRect)targetFrame
{
    // set up the frame so that it places right where the info button is
    CGRect infoRect = [PogUIUtility createCenterFrameWithSize:self.view.bounds.size inFrame:targetFrame];
    self.view.frame = infoRect;
    
    // distribute sub-circles equidistance from center
    CGRect subCircleFrame = [PogUIUtility createCenterFrameWithSize:self.beaconCircle.frame.size inFrame:self.closeCircle.frame];
    [self.beaconCircle setFrame:subCircleFrame];
    [self.beaconCircle setTransform:CGAffineTransformIdentity];
    [self.flyerCircle setFrame:subCircleFrame];
    [self.restockCircle setFrame:subCircleFrame];
}

- (void) setupContent
{
    // colors
    [self.beaconCircle setBackgroundColor:[GameColors bubbleBgColorWithAlpha:1.0f]];
    [self.beaconCircle setBorderColor:[GameColors borderColorBeaconsWithAlpha:1.0f]];
    [self.beaconCircle setBorderWidth:kBorderWidth];
    [self.beaconBar setBackgroundColor:[GameColors borderColorBeaconsWithAlpha:1.0f]];
    [self.flyerCircle setBackgroundColor:[GameColors bubbleBgColorWithAlpha:1.0f]];
    [self.flyerCircle setBorderColor:[GameColors borderColorFlyersWithAlpha:1.0f]];
    [self.flyerCircle setBorderWidth:kBorderWidth];
    [self.flyerBar setBackgroundColor:[GameColors borderColorFlyersWithAlpha:1.0f]];
    [self.restockCircle setBackgroundColor:[GameColors bubbleBgColorWithAlpha:1.0f]];
    [self.restockCircle setBorderColor:[GameColors borderColorPostsWithAlpha:1.0f]];
    [self.restockCircle setBorderWidth:kBorderWidth];
    [self.restockBar setBackgroundColor:[GameColors borderColorPostsWithAlpha:1.0f]];
    
    // label
    [self changeFlyerLabLabelIfNecessary];
    
    // semi-transparent restock and beacon if necessary
    if([self myPost])
    {
        // restock
        if([self.myPost supplyLevel] > 0)
        {
            [self.restockCircle setAlpha:kBubbleDisabledAlpha];
        }
        else
        {
            [self.restockCircle setAlpha:1.0f];
        }
        
        // beacon
        if ([[TradePostMgr getInstance] isBeaconActive])
        {
            [self.beaconCircle setAlpha:kBubbleDisabledAlpha];
        }
        else
        {
            [self.beaconCircle setAlpha:1.0f];
        }
    }

}

- (void) showFlyerLabForPost:(MyTradePost*)tradePost
{
    if([tradePost flyerAtPost])
    {
        GameViewController* game = [[GameManager getInstance] gameViewController];
        FlyerLabViewController* next = [[FlyerLabViewController alloc] initWithNibName:@"FlyerLabViewController" bundle:nil];
        next.flyer = [tradePost flyerAtPost];
        [game showModalNavViewController:next completion:nil];
    }
    else
    {
        if([[TradeManager getInstance] playerHasIdleFlyers])
        {
            // player can order
            [[[[GameManager getInstance] gameViewController] mapControl] defaultZoomCenterOn:[tradePost coord] animated:YES];
            [[GameManager getInstance] showFlyerSelectForBuyAtPost:tradePost];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Flyers busy"
                                                            message:@"Flyers must be idle before they can be called back"
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }
}

- (void)changeFlyerLabLabelIfNecessary
{
    if([self myPost])
    {
        if([self.myPost flyerAtPost])
        {
            [self.flyerLabel setText:@"Flyer Lab"];
        }
        else
        {
            [self.flyerLabel setText:@"Call Flyer"];
        }
    }
}


#pragma mark - button actions
- (void) didPressBeacon:(id)sender
{
    // this will deselect the post, which will cause this view-controller to be dismissed
    [[GameManager getInstance] haltMapAnnotationCalloutsForDuration:0.5];
    
    if (![[TradePostMgr getInstance] isBeaconActive])
    {
        if([self myPost])
        {
            NSLog(@"Set Beacon for PostId %@", [self.myPost postId]);
            [self.myPost setBeacon];
        }
    }
}

- (void) didPressFlyer:(id)sender
{
    // this will deselect the post, which will cause this view-controller to be dismissed
    [[GameManager getInstance] haltMapAnnotationCalloutsForDuration:0.5];

    if([self myPost])
    {
        [self showFlyerLabForPost:[self myPost]];
    }
}

- (void) didPressRestock:(id)sender
{
    // this will deselect the post, which will cause this view-controller to be dismissed
    [[GameManager getInstance] haltMapAnnotationCalloutsForDuration:0.5];

    if([self myPost])
    {
        if(0 >= [self.myPost supplyLevel])
        {
            GameViewController* game = [[GameManager getInstance] gameViewController];
            PostRestockConfirmScreen* next = [[PostRestockConfirmScreen alloc] initWithNibName:@"PostRestockConfirmScreen" bundle:nil];
            next.post = [self myPost];
            [game showModalNavViewController:next completion:nil];
        }
    }
}

- (void) didPressClose:(id)sender
{
    // this will deselect the post, which will cause this view-controller to be dismissed
    [[GameManager getInstance] haltMapAnnotationCalloutsForDuration:0.5];
}
@end
