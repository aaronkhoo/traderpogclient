//
//  PlayerPostCalloutView.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/17/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "PlayerPostCalloutView.h"
#import "PlayerPostCallout.h"
#import "PostRestockConfirmScreen.h"
#import "BeaconMgr.h"
#import "MyTradePost.h"
#import "PogUIUtility.h"
#import "GameColors.h"
#import "ImageManager.h"
#import "GameManager.h"
#import "GameViewController.h"
#import "MapControl.h"
#import "FlyerLabViewController.h"
#import <QuartzCore/QuartzCore.h>

NSString* const kPlayerPostCalloutViewReuseId = @"PlayerPostCalloutView";
static const float kCircleBorderWidth = 3.0f;
@interface PlayerPostCalloutView ()
- (void) initRender;
@end

@implementation PlayerPostCalloutView
@synthesize beaconButton;
@synthesize restockBubble;
@synthesize beaconBubble;
@synthesize destroyBubble;
@synthesize flyerLabBubble;
@synthesize beaconLabelContainer;
@synthesize restockLabelContainer;
@synthesize destroyLabelContainer;
@synthesize flyerLabLabelContainer;

- (id) initWithAnnotation:(id<MKAnnotation>)annotation
{
    self = [super initWithAnnotation:annotation reuseIdentifier:kPlayerPostCalloutViewReuseId];
    if(self)
    {
        [[NSBundle mainBundle] loadNibNamed:@"PlayerPostCalloutView" owner:self options:nil];
        [self initRender];
    }
    return self;
}

#pragma mark - internal methods
- (void) initRender
{
    // images
    CGRect imageFrame = [self.beaconBubble frame];
    imageFrame.origin = CGPointMake(0.0f, 0.0f);
    imageFrame = CGRectInset(imageFrame, 2.0f, 2.0f);
    UIImage* beaconImage = [[ImageManager getInstance] getImage:@"bubble_set_beacon.png" fallbackNamed:@"bubble_set_beacon.png"];
    UIImageView* beaconView = [[UIImageView alloc] initWithFrame:imageFrame];
    [beaconView setImage:beaconImage];
    UIImage* restockImage = [[ImageManager getInstance] getImage:@"bubble_restock.png" fallbackNamed:@"bubble_restock.png"];
    UIImageView* restockView = [[UIImageView alloc] initWithFrame:imageFrame];
    [restockView setImage:restockImage];
    UIImage* destroyImage = [[ImageManager getInstance] getImage:@"icon_removepost.png" fallbackNamed:@"icon_removepost.png"];
    UIImageView* destroyView = [[UIImageView alloc] initWithFrame:imageFrame];
    [destroyView setImage:destroyImage];
    
    UIColor* bubbleBgColor = [UIColor colorWithRed:114.0f/255.0f
                                             green:179.0f/255.0f
                                              blue:186.0f/255.0f
                                             alpha:1.0f];
    
    [self.restockBubble insertSubview:restockView belowSubview:[self restockLabelContainer]];
    [self.restockBubble setBackgroundColor:bubbleBgColor];
    [self.beaconBubble insertSubview:beaconView belowSubview:[self beaconLabelContainer]];
    [self.beaconBubble setBackgroundColor:bubbleBgColor];
    [self.destroyBubble insertSubview:destroyView belowSubview:[self destroyLabelContainer]];
    [self.destroyBubble setBackgroundColor:bubbleBgColor];
    //[self.flyerLabBubble insertSubview:flyerView belowSubview:[self flyerLabLabelContainer]];
    [self.flyerLabBubble setBackgroundColor:bubbleBgColor];
    
    // shape
    [self.restockLabelContainer setBackgroundColor:[GameColors borderColorScanWithAlpha:1.0f]];
    [PogUIUtility setCircleForView:[self restockBubble]
                   withBorderWidth:kCircleBorderWidth
                       borderColor:[GameColors borderColorScanWithAlpha:1.0f]];
    [PogUIUtility setCircleShadowOnView:[self restockBubble] shadowColor:[UIColor blackColor]];
    
    [self.beaconLabelContainer setBackgroundColor:[GameColors borderColorBeaconsWithAlpha:1.0f]];
    [PogUIUtility setCircleForView:[self beaconBubble]
                   withBorderWidth:kCircleBorderWidth
                       borderColor:[GameColors borderColorBeaconsWithAlpha:1.0f]];
    [PogUIUtility setCircleShadowOnView:[self beaconBubble] shadowColor:[UIColor blackColor]];

    [self.destroyLabelContainer setBackgroundColor:[GameColors borderColorPostsWithAlpha:1.0f]];
    [PogUIUtility setCircleForView:[self destroyBubble]
                   withBorderWidth:kCircleBorderWidth
                       borderColor:[GameColors borderColorPostsWithAlpha:1.0f]];
    [PogUIUtility setCircleShadowOnView:[self destroyBubble] shadowColor:[UIColor blackColor]];

    [self.flyerLabLabelContainer setBackgroundColor:[GameColors borderColorPostsWithAlpha:1.0f]];
    [PogUIUtility setCircleForView:[self flyerLabBubble]
                   withBorderWidth:kCircleBorderWidth
                       borderColor:[GameColors borderColorPostsWithAlpha:1.0f]];
    [PogUIUtility setCircleShadowOnView:[self flyerLabBubble] shadowColor:[UIColor blackColor]];
}

- (void) handleFlyerLabClose:(id)sender
{
    NSLog(@"close");
    
    // explicitly close it
    GameViewController* controller = [[GameManager getInstance] gameViewController];
    [controller closeModalViewWithOptions:kGameViewModalFlag_Strict animated:YES];
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
}

- (void)setHiddenOnRestock:(BOOL)hide
{
    [self.restockBubble setHidden:hide];
}

#pragma mark - button actions

- (IBAction)didPressSetBeacon:(id)sender
{
    MyTradePost* thisPost = (MyTradePost*)[self.parentAnnotationView annotation];
    if(thisPost)
    {
        NSLog(@"Set Beacon for PostId %@", [thisPost postId]);
        [thisPost setBeacon];
        beaconButton.enabled = NO;
    }
}

- (IBAction)didPressRestock:(id)sender
{
    MyTradePost* thisPost = (MyTradePost*)[self.parentAnnotationView annotation];
    if(thisPost)
    {        
        [[GameManager getInstance] haltMapAnnotationCalloutsForDuration:0.5];
        GameViewController* game = [[GameManager getInstance] gameViewController];
        PostRestockConfirmScreen* next = [[PostRestockConfirmScreen alloc] initWithNibName:@"PostRestockConfirmScreen" bundle:nil];
        next.post = thisPost;
        [game showModalNavViewController:next completion:nil];
    }
}

- (IBAction)didPressDestroy:(id)sender
{
    NSLog(@"Relocate");
}

- (IBAction)didPressFlyerLab:(id)sender
{
    MyTradePost* thisPost = (MyTradePost*)[self.parentAnnotationView annotation];
    if(thisPost)
    {
        [[GameManager getInstance] haltMapAnnotationCalloutsForDuration:0.5];
        [self showFlyerLabForPost:thisPost];
    }
}
@end
