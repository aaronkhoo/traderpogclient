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
#import <QuartzCore/QuartzCore.h>

static const NSInteger kDisplayLinkFrameInterval = 1;
static const CFTimeInterval kDisplayLinkMaxFrametime = 1.0 / 20.0;

enum kKnobSlices
{
    kKnobSliceScan = 0,
    kKnobSliceFlyer,
    kKnobSliceBeacon,
    kKnobSlicePost,
    
    kKnobSliceNum
};

@interface GameViewController ()
{
    // display link (for sim-render-loop)
    CADisplayLink* _displayLink;
    BOOL _displayLinkActive;
    CFTimeInterval _prevTime;
    
    CLLocationCoordinate2D _initCoord;
    KnobControl* _knob;
    WheelControl* _flyerWheel;
    WheelControl* _postWheel;
    WheelControl* _beaconWheel;
    Flyer* _trackedFlyer;
    
    GameHud* _hud;
    GameEventView *_gameEventNote;
    NSDate* _gameEventDisplayBegin;
    
    // Initial y positions
    CGFloat _debugmenu_y_origin;
    CGFloat _versionlabel_y_origin;
    
    // HACK
    UILabel* _labelScan;
    UIActivityIndicatorView* _scanActivity;
    // HACK
}
@property (nonatomic,strong) KnobControl* knob;
@property (nonatomic,strong) WheelControl* flyerWheel;
@property (nonatomic,strong) WheelControl* postWheel;
@property (nonatomic,strong) WheelControl* beaconWheel;
@property (nonatomic,strong) Flyer* trackedFlyer;
@property (nonatomic,strong) GameHud* hud;
@property (nonatomic,strong) GameEventView* gameEventNote;

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

@end

@implementation GameViewController
@synthesize mapView;
@synthesize mapControl = _mapControl;
@synthesize knob = _knob;
@synthesize flyerWheel = _flyerWheel;
@synthesize postWheel = _postWheel;
@synthesize beaconWheel = _beaconWheel;
@synthesize coord = _initCoord;
@synthesize trackedFlyer = _trackedFlyer;
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
    }
    return self;
}

- (void) dealloc
{
    _modalNav = nil;

    // unload game resources
    [FlyerLabFactory destroyInstance];
    [GameAnim destroyInstance];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // version string
    [self.versionLabel setText:[PogUIUtility versionStringForCurConfig]];
    
    // load game resources
    [GameAnim getInstance];
    [FlyerLabFactory getInstance];
    
    // create main mapview
    self.mapControl = [[MapControl alloc] initWithMapView:[self mapView] andCenter:_initCoord];
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
    _modalScrim = nil;
    _modalFlags = kGameViewModalFlag_None;
    
    _modalNav = [[ModalNavControl alloc] init];
    [self.view addSubview:_modalNav.view];
    [_modalNav.view setHidden:YES];

    // game hud
    if ([[Player getInstance] member])
    {
        [self initHud:0];
    }
    else
    {
        CGFloat heightChange = kGADAdSizeBanner.size.height;
        [self initHud:heightChange];
        
        // Show banner ad
        [self displayBannerAd];
    }
    [self hudSetCoins:[[Player getInstance] bucks]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleCoinsChanged:)
                                                 name:kGameNoteCoinsChanged
                                               object:[Player getInstance]];

    [self startDisplayLink];
}

- (void)viewDidUnload
{
    [self stopDisplayLink];
    
    [self shutdownHud];
    [self shutdownWheels];
    [self shutdownKnob];
    [self.mapControl stopTrackingAnnotation];
    self.mapControl = nil;
    
    // unload game resources
    [self dismissModal];
    [FlyerLabFactory destroyInstance];
    [GameAnim destroyInstance];
    _modalScrim = nil;
    _modalView = nil;
    [_reusableModals clearQueue];
    
    [self setVersionLabel:nil];
    [super viewDidUnload];
}

-(void) viewDidAppear:(BOOL)animated
{
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self displayPlayerSalesIfNecessary];
    });
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)displayPlayerSalesIfNecessary
{
    if ([[PlayerSales getInstance] hasSales])
    {
        PlayerSalesScreen* sales = [[PlayerSalesScreen alloc] initWithNibName:@"PlayerSalesScreen" bundle:nil];
        [self.navigationController pushFromRightViewController:sales animated:YES];
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
    [[FlyerMgr getInstance] updateFlyersAtDate:currentTime];
    
    if([[GameManager getInstance] canProcessGameEventNotifications])
    {
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
        [self.mapControl addAnnotationForTradePost:cur];
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

- (void) dismissKnobAnimated:(BOOL)isAnimated
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
    self.postWheel = [[WheelControl alloc] initWithFrame:self.view.bounds
                                                 delegate:[TradePostMgr getInstance]
                                               dataSource:[TradePostMgr getInstance]
                                                 superMap:self.mapControl
                                               wheelFrame:wheelFrame
                                             previewFrame:previewFrame
                                                numSlices:12];
    [self.view addSubview:[self postWheel]];

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
    self.flyerWheel = nil;
    self.postWheel = nil;
    self.beaconWheel = nil;
}

- (void) showPostWheelAnimated:(BOOL)isAnimated
{
    [self.postWheel showWheelAnimated:YES withDelay:0.0f];
    [self.knob gotoSliceIndex:kKnobSlicePost];
}

- (void) showFlyerWheelAnimated:(BOOL)isAnimated
{
    [self.flyerWheel showWheelAnimated:YES withDelay:0.0f];
    [self.knob gotoSliceIndex:kKnobSliceFlyer];
}

- (void) setBeaconWheelText:(NSString*)new_text
{
    [self.beaconWheel.previewLabel setText:new_text];
}

- (void) dismissActiveWheelAnimated:(BOOL)isAnimated
{
    if(![self.postWheel isWheelStateHidden])
    {
        [self.postWheel hideWheelAnimated:isAnimated withDelay:0.0f];
    }
    else if(![self.flyerWheel isWheelStateHidden])
    {
        [self.flyerWheel hideWheelAnimated:isAnimated withDelay:0.0f];
    }
    else if(![self.beaconWheel isWheelStateHidden])
    {
        [self.beaconWheel hideWheelAnimated:isAnimated withDelay:0.0f];
    }
}

- (IBAction)didPressDebug:(id)sender
{
    DebugMenu* menu = [[DebugMenu alloc] initWithNibName:@"DebugMenu" bundle:nil];
    [self.navigationController pushFromRightViewController:menu animated:YES];
}

- (void) hudSetCoins:(unsigned int)newCoins
{
    NSString* coinsString = [PogUIUtility currencyStringForAmount:newCoins];
    [self.hud.coins.label setText:coinsString];
}

- (void) handleCoinsChanged:(NSNotification *)note
{
    if(![self.hud holdNextCoinsUpdate])
    {
        Player* player = (Player*)[note object];
        if(player)
        {
            [self hudSetCoins:[player bucks]];
        }
    }
}

- (void) initHud:(CGFloat)heightChange
{
    self.hud = [[GameHud alloc] initWithFrame:[self.view bounds]];
    [self.view addSubview:[self hud]];
    
    CGRect noteFrame = CGRectMake(0.0f, heightChange, self.view.bounds.size.width, self.view.bounds.size.height - heightChange);
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
    [self.hud removeFromSuperview];
    self.hud = nil;
}

- (BOOL) isHeldHudCoinsUpdate
{
    return [self.hud holdNextCoinsUpdate];
}

- (void) setHoldHudCoinsUpdate:(BOOL)shouldHold
{
    if([self.hud holdNextCoinsUpdate] && !shouldHold)
    {
        NSString* coinsString = [PogUIUtility currencyStringForAmount:[[Player getInstance] bucks]];
        [self.hud.coins.label setText:coinsString];
    }
    self.hud.holdNextCoinsUpdate = shouldHold;
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
    [self showModalView:view options:kGameViewModalFlag_None animated:isAnimated];
}

- (void) hideModalViewAnimated:(BOOL)isAnimated
{
    [self closeModalViewWithOptions:kGameViewModalFlag_None animated:isAnimated];
}

- (void) showModalView:(UIView *)view options:(unsigned int)options animated:(BOOL)isAnimated
{
    if(kGameViewModalFlag_Strict & options)
    {
        // if strict modal, insert a scrim to block all inputs
        _modalScrim = [[UIView alloc] initWithFrame:self.view.bounds];
        [_modalScrim setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.1f]];
        [self.view addSubview:_modalScrim];
    }
    _modalView = view;
    _modalFlags = options;
    [self.view addSubview:view];
    [self dismissKnobAnimated:YES];    
}

- (void) closeModalViewWithOptions:(unsigned int)options animated:(BOOL)isAnimated
{
    if(_modalView && (options == _modalFlags))
    {
        if(_modalScrim)
        {
            [_modalScrim removeFromSuperview];
            _modalScrim = nil;
        }
        [_modalView removeFromSuperview];
        [self showKnobAnimated:YES delay:0.2f];
        
        UIView<ViewReuseDelegate>* cur = (UIView<ViewReuseDelegate>*)_modalView;
        [cur prepareForQueue];
        [_reusableModals queueView:cur];
        _modalView = nil;        
    }
}

- (void) showModalNavViewController:(UIViewController*)controller
                         completion:(ModalNavCompletionBlock)completion
{
    ModalNavControl* modal = self.modalNav;
    [modal.view setHidden:NO];
    [modal.navController pushFadeInViewController:controller animated:YES];
    modal.delegate = self;
    
    [self dismissKnobAnimated:YES];
}

#pragma mark - ModalNavDelegate
- (void) dismissModal
{
    [self.modalNav.view setHidden:YES];
    [self showKnobAnimated:YES delay:0.0f];
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
                       @"Posts",
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
            [self.flyerWheel showWheelAnimated:YES withDelay:0.0f];
            break;
                  
        case kKnobSliceBeacon:
            [self.beaconWheel showWheelAnimated:YES withDelay:0.0f];
            break;
            
        case kKnobSlicePost:
            [self.postWheel showWheelAnimated:YES withDelay:0.0f];
            break;
            
        default:
        case kKnobSliceScan:
            // TODO: make the visuals nicer?
            [_scanActivity setHidden:NO];
            [_scanActivity startAnimating];
            [[ScanManager getInstance] locateAndScanInMap:[self mapControl] 
                                               completion:^(BOOL finished, NSArray* tradePosts, CLLocation* loc){
                                                   if(finished)
                                                   {
                                                       [self handleScanResultTradePosts:tradePosts atLoc:loc];
                                                   }
                                                   [_scanActivity stopAnimating];
                                                   [_scanActivity setHidden:YES];
                                               }];
            break;
    }
    
    // dismiss any callout
    [self.mapControl deselectAllAnnotations];
    
    // reset map scroll in case one of the pan/pinch gesture recognizers left it in
    // a disabled state
    [self.mapControl.view setScrollEnabled:YES];
}

- (void) knob:(KnobControl *)knob didSettleAt:(unsigned int)index
{
    
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
    
    // HACK TODO: Remove this before ship. Setting up test ads!
    GADRequest *current_req = [GADRequest request];
    current_req.testing = YES;
    
    // Initiate a generic request to load it with an ad.
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
    // Store the original position of the debug button
    UIButton* dbgButton = [self debugButton];
    _debugmenu_y_origin = dbgButton.frame.origin.y;
    
    // Store original position of versionlabel
    UILabel* versionLabel = [self versionLabel];
    _versionlabel_y_origin = versionLabel.frame.origin.y;
}

- (void) shiftUIElements:(CGFloat)delta
{
    CGFloat newDbgButtonPosition = _debugmenu_y_origin + delta;
    UIButton* dbgButton = [self debugButton];
    if (dbgButton.frame.origin.y != newDbgButtonPosition)
    {
        dbgButton.frame = CGRectMake(dbgButton.frame.origin.x, newDbgButtonPosition, dbgButton.frame.size.width, dbgButton.frame.size.height);
    }
    
    CGFloat newVersionLabelPosition = _versionlabel_y_origin + delta;
    UILabel* versionLabel = [self versionLabel];
    if (versionLabel.frame.origin.y != newVersionLabelPosition)
    {
        versionLabel.frame = CGRectMake(versionLabel.frame.origin.x, newVersionLabelPosition, versionLabel.frame.size.width, versionLabel.frame.size.height);    
    }
    
    [[self hud] shiftHudPosition:delta];
}

@end
