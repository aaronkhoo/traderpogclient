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

- (void) startDisplayLink;
- (void) stopDisplayLink;
- (void) displayUpdate;
- (void) updateSim:(NSTimeInterval)elapsed;
- (void) updateRender:(NSTimeInterval)elapsed;

- (void) initKnob;
- (void) shutdownKnob;
- (void) didPressShowKnob:(id)sender;
- (void) handleScanResultTradePosts:(NSArray*)tradePosts;
- (void) initWheels;
- (void) shutdownWheels;
- (void) initHud;
- (void) shutdownHud;

- (void) hudSetCoins:(unsigned int)newCoins;
- (void) handleCoinsChanged:(NSNotification*)note;
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

- (id)init
{
    return [super initWithNibName:@"GameViewController" bundle:nil];
}

- (id)initAtCoordinate:(CLLocationCoordinate2D)coord
{
    self = [super initWithNibName:@"GameViewController" bundle:nil];
    if (self) 
    {
        _initCoord = coord;
        _mapControl = nil;
        _trackedFlyer = nil;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // create main mapview
    self.mapControl = [[MapControl alloc] initWithMapView:[self mapView] andCenter:_initCoord];
    self.trackedFlyer = nil;
    
    // add pre-existing objects in the world as annotations
    // the ORDER of init is IMPORTANT;
    // FlyerMgr creates dummy npc posts for all flight-paths; so,
    // must call it first prior to calling TradePostMgr's annotatePostsOnMap
    [[FlyerMgr getInstance] initFlyersOnMap];
    [[TradePostMgr getInstance] annotatePostsOnMap];
    [[BeaconMgr getInstance] addBeaconAnnotationsToMap:[self mapControl]];
    
    //---
    // HUD
    // create knob
    [self initKnob];
    [self initWheels];
    [self initHud];
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
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
    
    // sim
    [self updateSim:displayElapsed];
    NSDate* currentTime = [NSDate date];
    [[FlyerMgr getInstance] updateFlyersAtDate:currentTime];

    // render
    [self updateRender:displayElapsed];
}

- (void) updateSim:(NSTimeInterval)elapsed
{
    [[AnimMgr getInstance] update:elapsed];
}

- (void) updateRender:(NSTimeInterval)elapsed
{
}


#pragma mark - trade posts
- (void) handleScanResultTradePosts:(NSArray *)tradePosts
{
    // add annotations
    for(TradePost* cur in tradePosts)
    {
        [self.mapControl addAnnotationForTradePost:cur];
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
static const float kWheelPreviewXViewFrac = 0.0f;
static const float kWheelPreviewYHeightFrac = 1.65f;
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

- (void) initHud
{
    self.hud = [[GameHud alloc] initWithFrame:[self.view bounds]];
    [self.view addSubview:[self hud]];
}

- (void) shutdownHud
{
    [self.hud removeFromSuperview];
    self.hud = nil;
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
    UIImage* result = [UIImage imageNamed:@"Yun.png" withColor:color];
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
                                               completion:^(BOOL finished, NSArray* tradePosts){
                                                   if(finished)
                                                   {
                                                       [self handleScanResultTradePosts:tradePosts];
                                                   }
                                                   [_scanActivity stopAnimating];
                                                   [_scanActivity setHidden:YES];
                                               }];
            break;
    }
    
    // reset map scroll in case one of the pan/pinch gesture recognizers left it in
    // a disabled state
    [self.mapControl.view setScrollEnabled:YES];
}

- (void) knob:(KnobControl *)knob didSettleAt:(unsigned int)index
{
    
}

@end
