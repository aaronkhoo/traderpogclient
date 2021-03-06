//
//  GameViewController.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "GameViewController.h"
#import "MapControl.h"
#import "KnobControl.h"
#import "KnobSlice.h"
#import "ScanManager.h"
#import "FlyerMgr.h"
#import "TradePostMgr.h"
#import "BeaconMgr.h"
#import "WheelControl.h"
#import "WheelProtocol.h"
#import "UIImage+Pog.h"
#import "Flyer.h"
#import "Player.h"
#import "PogUIUtility.h"
#import "GameNotes.h"
#import "GameColors.h"
#import "GameHud.h"
#import "CircleBarView.h"
#import "AnimMgr.h"
#import "ImageManager.h"
#import "GameAnim.h"
#import "FlyerLabFactory.h"
#import "DebugMenu.h"
#import "UINavigationController+Pog.h"
#import "GameEventView.h"
#import "GameEventMgr.h"
#import "GameManager.h"
#import "ViewReuseQueue.h"
#import "PlayerSales.h"
#import "PlayerSalesScreen.h"
#import "CircleButton.h"
#import "InfoViewController.h"
#import "LeaderboardsScreen.h"
#import "GuildMembershipUI.h"
#import "SoundManager.h"
#import "PlayerPostViewController.h"
#import "ObjectivesMgr.h"
#import "ObjectivesMgr+Render.h"
#import "GameObjective.h"
#import "FlyerInfoView.h"
#import "MBProgressHUD.h"
#import "CreditsScreen.h"
#import <QuartzCore/QuartzCore.h>

static const NSInteger kDisplayLinkFrameInterval = 2;
static const CFTimeInterval kDisplayLinkMaxFrametime = 1.0 / 20.0;

// by default, modal view keeps the Info button
static const unsigned int kGameViewModalFlag_Default = kGameViewModalFlag_KeepInfoCircle;


@interface GameViewController ()
{
    // display link (for sim-render-loop)
    CADisplayLink* _displayLink;
    BOOL _displayLinkActive;
    CFTimeInterval _prevTime;
    
    CLLocationCoordinate2D _initCoord;
    KnobControl* _knob;
    WheelControl* _flyerWheel;

    // DISABLE_POSTWHEEL
    //WheelControl* _postWheel;
    WheelControl* _beaconWheel;
    Flyer* _trackedFlyer;
    
    GameEventView *_gameEventNote;
    NSDate* _gameEventDisplayBegin;
    
    CGRect _infoRect;
    CircleButton* _infoCircle;
    InfoViewController* _info;
    CGRect _myPostMenuRect;
    PlayerPostViewController* _myPostMenu;
    
    // HACK
    UILabel* _labelScan;
    UIActivityIndicatorView* _scanActivity;
    // HACK
}
@property (nonatomic,strong) KnobControl* knob;
@property (nonatomic,strong) WheelControl* flyerWheel;
// DISABLE_POSTWHEEL
//@property (nonatomic,strong) WheelControl* postWheel;
@property (nonatomic,strong) WheelControl* beaconWheel;
@property (nonatomic,strong) Flyer* trackedFlyer;
@property (nonatomic,strong) CircleButton* infoCircle;
@property (nonatomic,strong) InfoViewController* info;
@property (nonatomic,strong) PlayerPostViewController* myPostMenu;
@property (nonatomic,strong) GameEventView* gameEventNote;

- (void) setup;
- (void) startDisplayLink;
- (void) stopDisplayLink;
- (void) displayUpdate;
- (void) updateSim:(NSTimeInterval)elapsed currenTime:(NSDate*)currentTime;
- (void) updateRender:(NSTimeInterval)elapsed currentTime:(NSDate*)currentTime;

- (void) initKnob;
- (void) shutdownKnob;
- (void) didPressShowKnob:(id)sender;
- (void) handleScanResultTradePosts:(NSArray*)tradePosts atLoc:(CLLocation*)loc;
- (void) initWheels;
- (void) shutdownWheels;
- (void) initHud:(CGFloat)heightChange;
- (void) shutdownHud;

- (void) hudSetCoins:(unsigned int)newCoins;
- (void) handleCoinsChanged:(NSNotification*)note;
- (void) showNotificationViewForGameEvent:(GameEvent*)gameEvent animated:(BOOL)isAnimated;
- (void) hideNotificationViewForGameEventAnimated:(BOOL)isAnimated;
- (void) didPressInfo:(id)sender;
@end

@implementation GameViewController
@synthesize mapView;
@synthesize mapControl = _mapControl;
@synthesize knob = _knob;
@synthesize flyerWheel = _flyerWheel;
// DISABLE_POSTWHEEL
//@synthesize postWheel = _postWheel;
@synthesize beaconWheel = _beaconWheel;
@synthesize coord = _initCoord;
@synthesize trackedFlyer = _trackedFlyer;
@synthesize infoCircle = _infoCircle;
@synthesize info = _info;
@synthesize myPostMenu = _myPostMenu;
@synthesize hud = _hud;
@synthesize gameEventNote = _gameEventNote;
@synthesize modalNav = _modalNav;

- (id)init
{
    self = [super initWithNibName:@"GameViewController" bundle:nil];
    if (self)
    {
        _reusableModals = [[ViewReuseQueue alloc] init];
        [self storeOriginalYPositions];

        // load game resources
        [GameAnim getInstance];
        [FlyerLabFactory getInstance];
        
    }
    return self;
}

- (id)initAtCoordinate:(CLLocationCoordinate2D)coord
{
    self = [super initWithNibName:@"GameViewController" bundle:nil];
    if (self) 
    {
        _initCoord = coord;
        _mapControl = nil;
        _trackedFlyer = nil;
        _reusableModals = [[ViewReuseQueue alloc] init];

        [self storeOriginalYPositions];

        // load game resources
        [GameAnim getInstance];
        [FlyerLabFactory getInstance];
    }
    return self;
}

- (void) dealloc
{
    _modalNav = nil;
    [MBProgressHUD hideHUDForView:self.view animated:YES];

    // unload game resources
    [FlyerLabFactory destroyInstance];
    [GameAnim destroyInstance];
}

// setup all the sub-components of the game view
- (void) setup
{
    // create main mapview
    self.mapControl = [[MapControl alloc] initWithMapView:[self mapView] andCenter:_initCoord atZoomLevel:kDefaultZoomLevel];
    self.trackedFlyer = nil;
    
    // add pre-existing objects in the world as annotations
    // the ORDER of init is IMPORTANT;
    // FlyerMgr creates dummy npc posts for all flight-paths; so,
    // must call it first prior to calling TradePostMgr's annotatePostsOnMap
    [[FlyerMgr getInstance] initFlyersOnMap];
    [[TradePostMgr getInstance] annotatePostsOnMap:[self mapControl]];
    [[BeaconMgr getInstance] addBeaconAnnotationsToMap:[self mapControl]];
    
    // knob and wheel
    [self initKnob];
    [self initWheels];
    
    // modal nav
    _modalView = nil;
    _modalFlags = kGameViewModalFlag_None;
    
    _modalNav = [[ModalNavControl alloc] init];
    [self.view addSubview:_modalNav.view];
    [_modalNav.view setHidden:YES];
    
    // game hud
    if ([[Player getInstance] isMember])
    {
        [self initHud:0];
    }
    else
    {
        // added ad banner underneath the hud so that it doesn't intercept touches to
        // elements above hud (like the Info button)
        // TODO: change it so that the bannerView only gets added when there's an ad and the height is shifted;
        // when ad is done, it should be removed
        [self displayBannerAd];

        CGFloat heightChange = kGADAdSizeBanner.size.height;
        [self initHud:heightChange];
    }

    [self startDisplayLink];
}

// teardown all the sub-components of the game view
// after this function, there should be no more retention on GameViewController
- (void) teardown
{
    [self dismissModal];
    _modalView = nil;
    [_reusableModals clearQueue];
    [self shutdownHud];
    [self shutdownWheels];
    [self shutdownKnob];
    self.mapControl = nil;

    [self stopDisplayLink];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // load game resources event though these have been preloaded in init
    // there may have been a viewDidUnload prior to this due to memory warning, in which case,
    // we need them reloaded
    [GameAnim getInstance];
    [FlyerLabFactory getInstance];

    [self setup];
    [self hudSetCoins:[[Player getInstance] bucks]];
}

- (void)viewDidUnload
{
    [self teardown];
    
    // unload game resources
    [FlyerLabFactory destroyInstance];
    [GameAnim destroyInstance];
    
    [super viewDidUnload];
}

-(void) viewDidAppear:(BOOL)animated
{
    if((![self modalView] || (kGameViewModalFlag_KeepKnob & [self modalFlags])) &&
       ([self.modalNav.view isHidden]))
    {
        // make sure knob is shown (in case view had been unloaded by memory warning)
        [self showKnobAnimated:NO delay:0.0f];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)displayPlayerSalesIfNecessary
{
    BOOL shownScreen = NO;
    if ([[PlayerSales getInstance] hasSales])
    {
        PlayerSalesScreen* sales = [[PlayerSalesScreen alloc] initWithNibName:@"PlayerSalesScreen" bundle:nil];
        [self showModalNavViewController:sales completion:nil];
        shownScreen = YES;
    }
    return shownScreen;
}

- (void) disableMap
{
    if([self.mapControl.view isUserInteractionEnabled])
    {
        [self.mapControl.view setUserInteractionEnabled:NO];
    }
}

- (void) enableMap
{
    if(![self.mapControl.view isUserInteractionEnabled])
    {
        [self.mapControl.view setUserInteractionEnabled:YES];
    }
}

#pragma mark - display link
- (void) startDisplayLink
{
    if(!_displayLinkActive)
    {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayUpdate)];
        [_displayLink setFrameInterval:kDisplayLinkFrameInterval];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        _displayLinkActive = YES;
    }
}

- (void) stopDisplayLink
{
    if(_displayLinkActive)
    {
        [_displayLink invalidate];
        _displayLink = nil;
        _displayLinkActive = NO;
    }
}

- (void) displayUpdate
{
    CFTimeInterval displayElapsed = 0.0;
    
    // update time
    if(_prevTime > 0.0)
    {
        displayElapsed = [_displayLink timestamp] - _prevTime;
    }
    else
    {
        displayElapsed = [_displayLink timestamp];
    }
    _prevTime = [_displayLink timestamp];
    if(displayElapsed > kDisplayLinkMaxFrametime)
    {
        displayElapsed = kDisplayLinkMaxFrametime;
    }
    
    NSDate* currentTime = [NSDate date];
    
    // sim
    [self updateSim:displayElapsed currenTime:currentTime];

    // render
    [self updateRender:displayElapsed currentTime:currentTime];
}

- (void) updateSim:(NSTimeInterval)elapsed currenTime:(NSDate *)currentTime
{
    // tick the flyers
    [[FlyerMgr getInstance] updateFlyersAtDate:currentTime];
    
    // process the menus that are gonna popup during the game
    if([[GameManager getInstance] canProcessGameEventNotifications])
    {
        if([self.modalNav.view isHidden])
        {
            // process objectives first
            BOOL newModalNavPresented = [[ObjectivesMgr getInstance] updateGameViewController:self];
            if(!newModalNavPresented)
            {
                newModalNavPresented = [self displayPlayerSalesIfNecessary];
            }
            if(!newModalNavPresented)
            {
                // then game event notifications
                GameEvent* notify = [[GameEventMgr getInstance] dequeueEvent];
                MKMapRect visibleRect = [self.mapControl.view visibleMapRect];
                MKMapPoint notifyPoint = MKMapPointForCoordinate([notify coord]);
                if(notify && !(MKMapRectContainsPoint(visibleRect, notifyPoint)))
                {
                    // show banner only if the event is not already visible
                    [self showNotificationViewForGameEvent:notify animated:YES];
                }
            }
        }
    }
}

- (void) updateRender:(NSTimeInterval)elapsed currentTime:(NSDate *)currentTime
{
    if(_gameEventDisplayBegin)
    {
        NSTimeInterval gameEventDisplayDur = [currentTime timeIntervalSinceDate:_gameEventDisplayBegin];
        if(kGameEventViewVisibleSecs < gameEventDisplayDur)
        {
            [self hideNotificationViewForGameEventAnimated:YES];
        }
    }
    [[AnimMgr getInstance] update:elapsed];
}


#pragma mark - trade posts
- (void) handleScanResultTradePosts:(NSArray *)tradePosts atLoc:(CLLocation *)loc
{
    // add annotations
    for(TradePost* cur in tradePosts)
    {
        [self.mapControl addAnnotationForTradePost:cur isScan:YES];
    }
    
    if(loc)
    {
        [self.mapControl defaultZoomCenterOn:loc.coordinate animated:YES];
    }
}

#pragma mark - HUD UI controls

static const float kKnobAnimInDuration = 0.5f;
static const float kKnobAnimOutDuration = 0.25f;

// all knob position consts are expressed in terms of fraction of view-width
static const float kKnobRadiusFrac = 0.85f;  // frac of view-width
static const float kKnobFrameYOffsetFrac = (kKnobRadiusFrac * 0.05f);
static const float kKnobHiddenYOffsetFrac = (kKnobRadiusFrac * 0.4f); // frac of view-width
static const float kKnobShowButtonHeightFrac = 0.05f;   // frac of view-height
static const float kWheelRadiusFrac = 0.75f;
static const float kWheelPreviewXViewFrac = 0.03f;
static const float kWheelPreviewYHeightFrac = 1.75f;
static const float kWheelPreviewSizeFrac = 0.35f * 2.5f; // in terms of wheel radius
- (void) initKnob
{
    CGRect viewFrame = self.view.frame;
    float knobRadius = kKnobRadiusFrac * viewFrame.size.width;
    float knobYOffset = kKnobFrameYOffsetFrac * viewFrame.size.width;
    CGRect knobFrame = CGRectMake((viewFrame.size.width - knobRadius)/2.0f, 
                                  knobYOffset + viewFrame.size.height - (knobRadius/2.0f),
                                  knobRadius, knobRadius);
    self.knob = [[KnobControl alloc] initWithFrame:knobFrame delegate:self];
    [self.view addSubview:[self knob]];

    // HACK
    _scanActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    CGRect activityRect = knobFrame;
    activityRect.origin.y += 5.0f;
    activityRect.size.height = knobFrame.size.height / 2.0f;
    [_scanActivity setFrame:activityRect];
    [_scanActivity setHidden:YES];
    [self.view addSubview:_scanActivity];
    // HACK
    
    [self dismissKnobAnimated:NO];
}

- (void) shutdownKnob
{
    [self.knob removeFromSuperview];
    self.knob = nil;    
}

- (void) showKnobAnimated:(BOOL)isAnimated delay:(NSTimeInterval)delay
{
    [self.knob setLocked:NO];
    if(![self.knob isEnabled])
    {
        // always switch back to Scan when we show a dismissed knob
        unsigned int knobIndex = kKnobSliceScan;
        switch([[GameManager getInstance] gameState])
        {
            case kGameStateFlyerSelect:
                knobIndex = kKnobSliceFlyer;
                break;
                
            case kGameStateHomeSelect:
                knobIndex = kKnobSlicePost;
                break;
                
            case kGameStateGameLoop:
            default:
                break;
        }
        [self.knob gotoSliceIndex:knobIndex animated:NO];
        
        
        CGAffineTransform showTransform = CGAffineTransformIdentity;
        [self.knob setEnabled:YES];
        if(isAnimated)
        {
            [UIView animateWithDuration:kKnobAnimOutDuration
                                  delay:delay
                                options:UIViewAnimationCurveEaseInOut
                             animations:^(void){
                                 [self.knob setTransform:showTransform];
                             }
                             completion:^(BOOL finished){
                                 //HACK
                                 [_labelScan setHidden:NO];
                                 //HACK
                             }];
        }
        else
        {
            [self.knob setTransform:showTransform];
            //HACK
            [_labelScan setHidden:NO];
            //HACK
        }
    }
}

- (void) dismissKnobAnimated:(BOOL)isAnimated
{
    if([self.knob isEnabled])
    {
        CGAffineTransform hiddenTransform = CGAffineTransformMakeTranslation(0.0f,
                                                                             kKnobHiddenYOffsetFrac * self.view.frame.size.width);
        if(isAnimated)
        {
            [UIView animateWithDuration:kKnobAnimOutDuration
                             animations:^(void){
                                 [self.knob setTransform:hiddenTransform];
                             }
                             completion:^(BOOL finished){
                                 [self.knob setEnabled:NO];
                             }];
        }
        else
        {
            [self.knob setTransform:hiddenTransform];
            [self.knob setEnabled:NO];
        }
    }
}

- (void) didPressShowKnob:(id)sender
{
    [self showKnobAnimated:YES delay:0.0f];
}

- (void) initWheels
{
    CGRect viewFrame = self.view.frame;
    float radius = kWheelRadiusFrac * viewFrame.size.width;
    float yoffset = kKnobFrameYOffsetFrac * viewFrame.size.width;
    CGRect wheelFrame = CGRectMake((viewFrame.size.width - radius)/2.0f,
                                   yoffset + viewFrame.size.height - (radius/2.0f),
                                   radius, radius);
    float previewSize = radius * kWheelPreviewSizeFrac;
    CGRect previewFrame = CGRectMake(kWheelPreviewXViewFrac * viewFrame.size.width,
                                     viewFrame.size.height - (kWheelPreviewYHeightFrac * previewSize),
                                     previewSize,
                                     previewSize);
    self.flyerWheel = [[WheelControl alloc] initWithFrame:self.view.bounds
                                                 delegate:[FlyerMgr getInstance]
                                               dataSource:[FlyerMgr getInstance]
                                                 superMap:self.mapControl
                                               wheelFrame:wheelFrame
                                             previewFrame:previewFrame
                                                numSlices:12];
    [self.view addSubview:[self flyerWheel]];

    // DISABLE_POSTWHEEL
    /*
    self.postWheel = [[WheelControl alloc] initWithFrame:self.view.bounds
                                                 delegate:[TradePostMgr getInstance]
                                               dataSource:[TradePostMgr getInstance]
                                                 superMap:self.mapControl
                                               wheelFrame:wheelFrame
                                             previewFrame:previewFrame
                                                numSlices:12];
    [self.view addSubview:[self postWheel]];
     */
    self.beaconWheel = [[WheelControl alloc] initWithFrame:self.view.bounds
                                                delegate:[BeaconMgr getInstance]
                                              dataSource:[BeaconMgr getInstance]
                                                superMap:self.mapControl
                                              wheelFrame:wheelFrame
                                            previewFrame:previewFrame
                                               numSlices:12];
    [self.view addSubview:[self beaconWheel]];
}

- (void) shutdownWheels
{
    [self.flyerWheel removeFromSuperview];
    self.flyerWheel = nil;

    // DISABLE_POSTWHEEL
    //[self.postWheel removeFromSuperview];
    //self.postWheel = nil;
    
    [self.beaconWheel removeFromSuperview];
    self.beaconWheel = nil;
}

// DISABLE_POSTWHEEL
/*
- (void) showPostWheelAnimated:(BOOL)isAnimated
{
    [self.postWheel showWheelAnimated:YES withDelay:0.0f];
    [self.knob gotoSliceIndex:kKnobSlicePost animated:YES];
}
 */

- (void) showFlyerWheelAnimated:(BOOL)isAnimated
{
    [self.flyerWheel showWheelAnimated:YES withDelay:0.0f];
    [self.knob gotoSliceIndex:kKnobSliceFlyer animated:NO];
}

- (void) setBeaconWheelText:(NSString*)new_text
{
    [self.beaconWheel.previewLabel setText:new_text];
}

- (void) dismissActiveWheelAnimated:(BOOL)isAnimated
{
    // DISABLE_POSTWHEEL
    /*
    if(![self.postWheel isWheelStateHidden])
    {
        [self.postWheel hideWheelAnimated:isAnimated withDelay:0.0f];
    }
    else
     */
    if(![self.flyerWheel isWheelStateHidden])
    {
        [self.flyerWheel hideWheelAnimated:isAnimated withDelay:0.0f];
    }
    else if(![self.beaconWheel isWheelStateHidden])
    {
        [self.beaconWheel hideWheelAnimated:isAnimated withDelay:0.0f];
    }
}

- (void) lockKnobAtSlice:(unsigned int)sliceIndex
{
    [self.knob gotoSliceIndex:sliceIndex animated:NO];
    [self.knob setLocked:YES];
}

- (void) setKnobToSlice:(unsigned int)sliceIndex animated:(BOOL)animated
{
    [self.knob gotoSliceIndex:sliceIndex animated:animated];
}

- (void) unlockKnob
{
    [self.knob setLocked:NO];
}

- (void) disableKnobButton
{
    [self.knob.centerButton setEnabled:NO];
}

- (void) enableKnobButton
{
    [self.knob.centerButton setEnabled:YES];
}

- (void) didPressInfo:(id)sender
{
    [[SoundManager getInstance] playClip:@"Pog_SFX_PopUP_Level1"];

    [self.mapControl deselectAllAnnotations];
    [self.info presentInView:self.view belowSubview:self.infoCircle animated:YES];
    [self hideInfoCircleAnimated:YES];
}

- (void) dismissInfo
{
    if([self.infoCircle isHidden] && [self.info.view superview])
    {
        [self dismissModalView:self.info.view withModalId:kInfoCloseId];
    }
}

- (void) dismissInfoNotAnimated
{
    if([self.infoCircle isHidden] && [self.info.view superview])
    {
        [self.info dismissAnimated:NO];
        [self showInfoCircleAnimated:NO];
    }
}

- (void) showMyPostMenuForPost:(MyTradePost *)myPost
{
    self.myPostMenu.myPost = myPost;
    [self.myPostMenu presentInView:self.view belowSubview:nil animated:YES];
}

- (void) dismissMyPostMenuAnimated:(BOOL)isAnimated
{
    [self.myPostMenu dismissAnimated:isAnimated];
}

- (void) hideInfoCircleAnimated:(BOOL)isAnimated
{
    if(![self.infoCircle isHidden])
    {
        if(isAnimated)
        {
            [UIView animateWithDuration:0.1f
                             animations:^(void){
                                 [self.infoCircle setTransform:CGAffineTransformMakeScale(0.1f, 0.1f)];
                             }
                             completion:^(BOOL finished){
                                 [self.infoCircle setHidden:YES];
                             }];
        }
        else
        {
            [self.infoCircle setHidden:YES];
        }
    }
}

- (void) showInfoCircleAnimated:(BOOL)isAnimated
{
    if([self.infoCircle isHidden])
    {
        if(isAnimated)
        {
            [self.infoCircle setHidden:NO];
            [self.infoCircle setTransform:CGAffineTransformMakeScale(0.1f, 0.1f)];
            [UIView animateWithDuration:0.2f
                             animations:^(void){
                                 [self.infoCircle setTransform:CGAffineTransformMakeScale(1.0f, 1.0f)];
                             }
                             completion:nil];
        }
        else
        {
            [self.infoCircle setTransform:CGAffineTransformMakeScale(1.0f, 1.0f)];
            [self.infoCircle setHidden:NO];
        }        
    }
}

- (void) hudSetCoins:(unsigned int)newCoins
{
    NSString* coinsString = [PogUIUtility currencyStringForAmount:newCoins];
    [self.hud.coins.label setText:coinsString];
}

- (void) handleCoinsChanged:(NSNotification *)note
{
    Player* player = (Player*)[note object];
    if(player)
    {
        [self hudSetCoins:[player bucks]];
    }
}

static const float kInfoSize = 60.0f;
static const float kInfoXOffset = -8.0f;
static const float kInfoYOffset = 9.0f;
static const float kInfoBorderWidth = 4.0f;
static const float kMyPostMenuSize = 60.0f;
- (void) initHud:(CGFloat)heightChange
{
    CGRect parentRect = self.view.bounds;
    
    // hud
    self.hud = [[GameHud alloc] initWithFrame:[self.view bounds]];
    [self.view addSubview:[self hud]];
    
    // info
    _infoRect = CGRectMake(parentRect.size.width - kInfoSize + kInfoXOffset,
                           kInfoYOffset,
                           kInfoSize, kInfoSize);
    self.infoCircle = [[CircleButton alloc] initWithFrame:_infoRect];
    [self.infoCircle setBackgroundColor:[GameColors bubbleColorScanWithAlpha:1.0f]];
    [self.infoCircle setBorderColor:[GameColors borderColorScanWithAlpha:1.0f]];
    [self.infoCircle setBorderWidth:kInfoBorderWidth];
    [self.infoCircle setButtonTarget:self action:@selector(didPressInfo:)];
    UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectInset(self.infoCircle.bounds, 1.0f, 1.0f)];
    [infoLabel setTextAlignment:UITextAlignmentCenter];
    [infoLabel setFont:[UIFont fontWithName:@"Marker Felt" size:24.0f]];
    [infoLabel setText:@"info"];
    [infoLabel setBackgroundColor:[UIColor clearColor]];
    [infoLabel setTextColor:[GameColors gliderWhiteWithAlpha:1.0f]];
    [self.infoCircle addSubview:infoLabel];
    [self.view addSubview:[self infoCircle]];
    self.info = [[InfoViewController alloc] initWithCenterFrame:_infoRect delegate:self];
    
    // my post menu
    _myPostMenuRect = CGRectMake((parentRect.size.width * 0.5f) - (kMyPostMenuSize * 0.5f),
                                 (parentRect.size.height * 0.5f) - (kMyPostMenuSize * 0.5f),
                                 kMyPostMenuSize, kMyPostMenuSize);
    self.myPostMenu = [[PlayerPostViewController alloc] initWithCenterFrame:_myPostMenuRect delegate:self];
    
    
    // game event notifications
    CGRect noteFrame = CGRectMake(0.0f, heightChange, parentRect.size.width, parentRect.size.height - heightChange);
    self.gameEventNote = [[GameEventView alloc] initWithFrame:noteFrame];
    [self.gameEventNote setHidden:YES];
    [self.view addSubview:[self gameEventNote]];
    _gameEventDisplayBegin = nil;
}

- (void) shutdownHud
{
    _gameEventDisplayBegin = nil;
    [self.gameEventNote removeFromSuperview];
    self.gameEventNote = nil;
    
    self.myPostMenu = nil;
    [self dismissInfoNotAnimated];
    self.info = nil;
    [self.infoCircle removeFromSuperview];
    self.infoCircle = nil;
    
    [self.hud removeFromSuperview];
    self.hud = nil;
}

- (void) showNotificationViewForGameEvent:(GameEvent*)gameEvent animated:(BOOL)isAnimated
{
    _gameEventDisplayBegin = [NSDate date];
    if(isAnimated)
    {
        [self.gameEventNote refreshWithGameEvent:gameEvent targetMap:[self mapControl]];
        [self.gameEventNote setHidden:NO];
        [self.gameEventNote setAlpha:0.0f];
        [UIView animateWithDuration:0.2f delay:0.0f options:(UIViewAnimationCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction)
                         animations:^(void){
                             [self.gameEventNote setAlpha:1.0f];
                         }
                         completion:nil];
    }
    else
    {
        [self.gameEventNote refreshWithGameEvent:gameEvent targetMap:[self mapControl]];
        [self.gameEventNote setHidden:NO];
        [self.gameEventNote setAlpha:1.0f];
    }
}

- (void) hideNotificationViewForGameEventAnimated:(BOOL)isAnimated
{
    if(![self.gameEventNote isHidden])
    {
        if(isAnimated)
        {
            [UIView animateWithDuration:1.0f delay:0.0f options:UIViewAnimationCurveEaseInOut
                             animations:^(void){
                                 [self.gameEventNote setAlpha:0.0f];
                             }
                             completion:^(BOOL finished){
                                 [self.gameEventNote setHidden:YES];
                             }];
        }
        else
        {
            [self.gameEventNote setHidden:YES];
        }
    }
    _gameEventDisplayBegin = nil;
}

- (UIView*) dequeueModalViewWithIdentifier:(NSString *)identifier
{
    UIView* result = [_reusableModals dequeueReusableViewWithIdentifier:identifier];
    return result;
}

- (UIView*) modalView
{
    if(_modalView)
    {
        UIView<ViewReuseDelegate>* cur = (UIView<ViewReuseDelegate>*)_modalView;
        [cur prepareForQueue];        
    }
    return _modalView;
}

- (void) showModalView:(UIView<ViewReuseDelegate>*)view animated:(BOOL)isAnimated
{
    [self showModalView:view options:kGameViewModalFlag_Default animated:isAnimated];
}

- (void) showModalView:(UIView *)view options:(unsigned int)options animated:(BOOL)isAnimated
{
    if(_modalView)
    {
        [self closeModalViewAnimated:NO];
    }
    _modalView = view;
    _modalFlags = options;
    [self.view insertSubview:view aboveSubview:self.modalNav.view];
    if(isAnimated)
    {
        [view setTransform:CGAffineTransformMakeScale(0.1f, 0.1f)];
        [UIView animateWithDuration:0.1f animations:^(void){
            [view setTransform:CGAffineTransformIdentity];
        }];
    }
    else
    {
        [view setTransform:CGAffineTransformIdentity];
    }
    
    if(!(kGameViewModalFlag_KeepKnob & _modalFlags))
    {
        [self dismissKnobAnimated:isAnimated];
    }
    
    if(!(kGameViewModalFlag_KeepInfoCircle & _modalFlags))
    {
        [self hideInfoCircleAnimated:isAnimated];
    }
}

- (void) closeModalViewAnimated:(BOOL)isAnimated
{
    UIView* outgoingModalView = _modalView;
    if(outgoingModalView)
    {
        [self showKnobAnimated:YES delay:0.2f];
        [self showInfoCircleAnimated:isAnimated];
        _modalView = nil;
        _modalFlags = kGameViewModalFlag_None;
        
        if(isAnimated)
        {
            [UIView animateWithDuration:0.1f
                             animations:^(void){
                                 [outgoingModalView setTransform:CGAffineTransformIdentity];
                             }
                             completion:^(BOOL finished){
                                 [outgoingModalView removeFromSuperview];
                                 UIView<ViewReuseDelegate>* cur = (UIView<ViewReuseDelegate>*)outgoingModalView;
                                 [cur prepareForQueue];
                                 [_reusableModals queueView:cur];
                             }];
        }
        else
        {
            [outgoingModalView setTransform:CGAffineTransformIdentity];
            [outgoingModalView removeFromSuperview];
            UIView<ViewReuseDelegate>* cur = (UIView<ViewReuseDelegate>*)outgoingModalView;
            [cur prepareForQueue];
            [_reusableModals queueView:cur];
        }
    }
}

- (void) defaultHandleModalClose:(id)sender
{
    [[[GameManager getInstance] gameViewController] closeModalViewAnimated:NO];
}

- (void) showInfoViewForFlyer:(Flyer*)flyer;
{
    FlyerInfoView* popup = (FlyerInfoView*)[self dequeueModalViewWithIdentifier:kFlyerInfoViewReuseIdentifier];
    if(!popup)
    {
        UIView* parent = [self view];
        popup = [[FlyerInfoView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 0.0f, 0.0f)];
        CGRect popFrame = [PogUIUtility createCenterFrameWithSize:popup.nibContentView.bounds.size
                                                          inFrame:parent.bounds
                                                    withFrameSize:popup.nibView.bounds.size];
        [popup setFrame:popFrame];
    }
    
    // refresh content
    [popup refreshViewForFlyer:flyer];
    
    // assign an action to the close button
    [popup.closeCircle setButtonTarget:self action:@selector(defaultHandleModalClose:)];
    
    // show it
    [self showModalView:popup animated:YES];
}

- (void) showModalNavViewController:(UIViewController*)controller
                         completion:(ModalNavCompletionBlock)completion
{
    ModalNavControl* modal = self.modalNav;
    modal.completionBlock = completion;
    [modal.view setHidden:NO];
    [modal.navController pushFadeInViewController:controller animated:YES];
    modal.delegate = self;
    
    [self dismissKnobAnimated:YES];
    [self hideInfoCircleAnimated:NO];
}

#pragma mark - ModalNavDelegate
- (void) dismissModal
{
    [self.modalNav.view setHidden:YES];
    [self showKnobAnimated:YES delay:0.0f];
    [self showInfoCircleAnimated:NO];
}

- (void) dismissModalView:(UIView *)viewToDismiss withModalId:(NSString *const)modalId
{
    if([modalId isEqualToString:kInfoCloseId])
    {
        [self.info dismissAnimated:YES];
        [self showInfoCircleAnimated:YES];
    }
    else if([modalId isEqualToString:kInfoLeaderboardId])
    {
        [self.info dismissAnimated:NO];
        [self showInfoCircleAnimated:YES];
        LeaderboardsScreen* leaderboards = [[LeaderboardsScreen alloc] initWithNibName:@"LeaderboardsScreen" bundle:nil];
        [self.navigationController pushFromRightViewController:leaderboards animated:YES];
    }
    else if([modalId isEqualToString:kInfoMembershipId])
    {
        [self.info dismissAnimated:NO];
        [self showInfoCircleAnimated:YES];
        GuildMembershipUI* guildmembership = [[GuildMembershipUI alloc] initWithNibName:@"GuildMembershipUI" bundle:nil];
        [self.navigationController pushFromRightViewController:guildmembership animated:YES];
    }
    else if([modalId isEqualToString:kInfoMoreId])
    {
        [self.info dismissAnimated:NO];
        [self showInfoCircleAnimated:YES];
        CreditsScreen* menu = [[CreditsScreen alloc] initWithNibName:@"CreditsScreen" bundle:nil];
        [self.navigationController pushFromRightViewController:menu animated:YES];
//        DebugMenu* menu = [[DebugMenu alloc] initWithNibName:@"DebugMenu" bundle:nil];
//        [self.navigationController pushFromRightViewController:menu animated:YES];
    }
    else if([modalId isEqualToString:kMyPostMenuCloseId])
    {
        [self.myPostMenu dismissAnimated:YES];
    }
    else
    {
        [viewToDismiss removeFromSuperview];
    }
}

#pragma mark - KnobProtocol
- (unsigned int) numItemsInKnob:(KnobControl *)knob
{
    unsigned int result = kKnobSliceNum;
    return result;
}

- (NSString*) knob:(KnobControl *)knob titleAtIndex:(unsigned int)index
{
    NSArray* titles = [NSArray arrayWithObjects:
                       @"Scan",
                       @"Flyers",
                       @"Beacons",
                       @"Home",
                       nil];
    if(index >= [titles count])
    {
        index = 0;
    }
    return [titles objectAtIndex:index];
}

- (UIColor*) colorAtIndex:(unsigned int)index withAlpha:(CGFloat)alpha
{
    UIColor* result = nil;
    switch(index)
    {
        case kKnobSliceFlyer:
            result = [GameColors bubbleColorFlyersWithAlpha:alpha];
            break;
            
        case kKnobSliceBeacon:
            result = [GameColors bubbleColorBeaconsWithAlpha:alpha];
            break;
            
        case kKnobSlicePost:
            result = [GameColors bubbleColorPostsWithAlpha:alpha];
            break;
            
        default:
        case kKnobSliceScan:
            result = [GameColors bubbleColorScanWithAlpha:alpha];
            break;
    }
    return result;
}

- (UIColor*) knob:(KnobControl *)knob colorAtIndex:(unsigned int)index
{
    UIColor* result = [self colorAtIndex:index withAlpha:1.0f];
    return result;
}

- (UIColor*) knob:(KnobControl *)knob borderColorAtIndex:(unsigned int)index
{
    UIColor* result = nil;
    switch(index)
    {
        case kKnobSliceFlyer:
            result = [GameColors borderColorFlyersWithAlpha:1.0f];
            break;
            
        case kKnobSliceBeacon:
            result = [GameColors borderColorBeaconsWithAlpha:1.0f];
            break;
            
        case kKnobSlicePost:
            result = [GameColors borderColorPostsWithAlpha:1.0f];
            break;
            
        default:
        case kKnobSliceScan:
            result = [GameColors borderColorScanWithAlpha:1.0f];
            break;
    }
    return result;
}

- (UIImage*) knob:(KnobControl*)knob decalImageAtIndex:(unsigned int)index
{
    UIColor* color = [self colorAtIndex:index withAlpha:1.0f];
    UIImage* result = [[ImageManager getInstance] getImage:@"icon_yun.png" fallbackNamed:@"icon_yun.png" withColor:color];
    return result;
}

- (void) didPressKnobAtIndex:(unsigned int)index
{
    switch(index)
    {
        case kKnobSliceFlyer:
            [[SoundManager getInstance] playClip:@"Pog_SFX_PopUP_Level1"];
            [self.flyerWheel showWheelAnimated:YES withDelay:0.0f];
            break;
                  
        case kKnobSliceBeacon:
            [[SoundManager getInstance] playClip:@"Pog_SFX_PopUP_Level1"];
            [self.beaconWheel showWheelAnimated:YES withDelay:0.0f];
            break;
            
        case kKnobSlicePost:
            [[SoundManager getInstance] playClip:@"Pog_SFX_PopUP_Level1"];
            
            // DISABLE_POSTWHEEL
            // TODO: Disable wheel for posts. Just zoom straight to the single post owned by the player
            // instead. Leave this in place for possible future enhancement.
            //[self.postWheel showWheelAnimated:YES withDelay:0.0f];
            
            [[self mapControl] defaultZoomCenterOn:[[[TradePostMgr getInstance] getFirstMyTradePost] coord] animated:YES];
            break;
            
        default:
        case kKnobSliceScan:
            // play sound
            [[SoundManager getInstance] playClip:@"Pog_SFX_Scanner"];
            
            MBProgressHUD *progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            progress.labelText = @"Scanning for Trade Posts";

            [[ObjectivesMgr getInstance] playerDidPerformScan];
            [[ScanManager getInstance] locateAndScanInMap:[self mapControl]
                                               completion:^(BOOL finished, NSArray* tradePosts, CLLocation* loc){
                                                   if(finished)
                                                   {
                                                       [self handleScanResultTradePosts:tradePosts atLoc:loc];
                                                   }
                                                   [MBProgressHUD hideHUDForView:self.view animated:YES];
                                               }];
            break;
    }
    
    // dismiss any callout
    [self.mapControl deselectAllAnnotations];
    [self dismissInfo];
    
    // reset map scroll in case one of the pan/pinch gesture recognizers left it in
    // a disabled state
    [self.mapControl.view setScrollEnabled:YES];
}

- (void) knob:(KnobControl *)knob didSettleAt:(unsigned int)index
{
    
}

- (void) knobDidPressLeft
{
    [[ObjectivesMgr getInstance] playerDidPerformKnobLeft];
}

- (void) knobDidPressRight
{
    [[ObjectivesMgr getInstance] playerDidPerformKnobRight];
}

#pragma mark - AdMob banner
- (void) displayBannerAd
{
    // Create a view of the standard size at the top of the screen.
    // Available AdSize constants are explained in GADAdSize.h.
    _bannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
    
    // Set up this instance as a delegate
    [_bannerView setDelegate:self];
    
    // Specify the ad's "unit identifier." This is your AdMob Publisher ID.
    _bannerView.adUnitID = @"a150639ac683921";
    
    // Let the runtime know which UIViewController to restore after taking
    // the user wherever the ad goes and add it to the view hierarchy.
    _bannerView.rootViewController = self;
    [self.view addSubview:_bannerView];
    
    // Initiate a generic request to load it with an ad.
    GADRequest *current_req = [GADRequest request];
    [_bannerView loadRequest:current_req];
}

- (void)adViewDidReceiveAd:(GADBannerView *)bannerView
{
    NSLog(@"Received ad");
    CGFloat heightChange = kGADAdSizeBanner.size.height;
    [self shiftUIElements:heightChange];
}

- (void)adView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(GADRequestError *)error
{
    NSLog(@"adView:didFailToReceiveAdWithError:%@", [error localizedDescription]);
    [self shiftUIElements:0];
}

#pragma mark - Functions for shifting positions of the UI elements
- (void) storeOriginalYPositions
{
}

- (void) shiftUIElements:(CGFloat)delta
{
    [[self hud] shiftHudPosition:delta];
    
    // must dismiss info immediately prior to making any changes to its frame
    [self dismissInfoNotAnimated];
    CGRect shiftedInfoRect = CGRectMake(_infoRect.origin.x, _infoRect.origin.y + delta,
                                        _infoRect.size.width, _infoRect.size.height);
    [self.infoCircle setFrame:shiftedInfoRect];
    [self.info setCenterFrame:shiftedInfoRect];
}

@end
