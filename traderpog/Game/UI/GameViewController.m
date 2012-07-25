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
#import "ScanManager.h"
#import "FlyerMgr.h"
#import <QuartzCore/QuartzCore.h>

static const NSInteger kDisplayLinkFrameInterval = 1;
static const CFTimeInterval kDisplayLinkMaxFrametime = 1.0 / 20.0;

@interface GameViewController ()
{
    // display link (for sim-render-loop)
    CADisplayLink* _displayLink;
    BOOL _displayLinkActive;
    CFTimeInterval _prevTime;
    
    CLLocationCoordinate2D _initCoord;
    KnobControl* _knob;
    UIButton* _buttonShowKnob;
    
    // HACK
    UILabel* _labelScan;
    UIActivityIndicatorView* _scanActivity;
    // HACK
}
@property (nonatomic,strong) KnobControl* knob;
@property (nonatomic,strong) UIButton* buttonShowKnob;

- (void) startDisplayLink;
- (void) stopDisplayLink;
- (void) displayUpdate;
- (void) updateSim:(NSTimeInterval)elapsed;
- (void) updateRender:(NSTimeInterval)elapsed;

- (void) initKnob;
- (void) shutdownKnob;
- (void) didPressShowKnob:(id)sender;
- (void) handleScanResultTradePosts:(NSArray*)tradePosts;
@end

@implementation GameViewController
@synthesize mapView;
@synthesize mapControl = _mapControl;
@synthesize knob = _knob;
@synthesize buttonShowKnob = _buttonShowKnob;
@synthesize coord = _initCoord;

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
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // create main mapview
    self.mapControl = [[MapControl alloc] initWithMapView:[self mapView] andCenter:_initCoord];
    
    // create knob
    [self initKnob];
    
    [self startDisplayLink];
}

- (void)viewDidUnload
{
    [self stopDisplayLink];
    
    [self shutdownKnob];
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
static const float kKnobRadiusFrac = 0.4f;  // frac of view-width
static const float kKnobHiddenYOffsetFrac = (kKnobRadiusFrac * 0.4f); // frac of view-width
static const float kKnobShowButtonHeightFrac = 0.05f;   // frac of view-height

- (void) initKnob
{
    CGRect viewFrame = self.view.frame;
    float knobRadius = kKnobRadiusFrac * viewFrame.size.width;
    CGRect knobFrame = CGRectMake((viewFrame.size.width - knobRadius)/2.0f, 
                                  viewFrame.size.height - (knobRadius / 2.0f),
                                  knobRadius, knobRadius);
    self.knob = [[KnobControl alloc] initWithFrame:knobFrame numSlices:4];
    [self.knob setBackgroundImage:[UIImage imageNamed:@"startButton.png"]];
    [self.view addSubview:[self knob]];
    [self.knob setDelegate:self];
    
    // HACK
    // TODO: the label needs to be on the KnobSlices
    CGRect labelRect = knobFrame;
    labelRect.origin.y += 5.0f;
    labelRect.size.height = knobFrame.size.height / 2.0f;
    UILabel* labelScan = [[UILabel alloc] initWithFrame:labelRect];
    [labelScan setFont:[UIFont fontWithName:@"Marker Felt" size:20]];
    [labelScan setTextColor:[UIColor whiteColor]];
    [labelScan setText:@"SCAN"];
    [labelScan setTextAlignment:UITextAlignmentCenter];
    [labelScan setBackgroundColor:[UIColor clearColor]];
    [labelScan setEnabled:YES];
    [labelScan setHidden:YES];
    _labelScan = labelScan;
    [self.view addSubview:labelScan];
    
    _scanActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [_scanActivity setFrame:labelRect];
    [_scanActivity setHidden:YES];
    [self.view addSubview:_scanActivity];
    // HACK
    
    float buttonHeight = kKnobShowButtonHeightFrac * viewFrame.size.height;
    CGRect buttonRect = CGRectMake(knobFrame.origin.x, (viewFrame.size.height - buttonHeight), 
                                   knobFrame.size.width, buttonHeight);
    self.buttonShowKnob = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.buttonShowKnob setFrame:buttonRect];
    [self.buttonShowKnob setTitle:@"^" forState:UIControlStateNormal];
    [self.buttonShowKnob addTarget:self action:@selector(didPressShowKnob:) forControlEvents:UIControlEventTouchUpInside];
    //[self.view addSubview:[self buttonShowKnob]];
     
    [self dismissKnobAnimated:NO];
}

- (void) shutdownKnob
{
    [self.buttonShowKnob removeFromSuperview];
    self.buttonShowKnob = nil;
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
    [self.buttonShowKnob setHidden:YES];
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
                             [self.buttonShowKnob setEnabled:YES];
                         }];
    }
    else
    {
        [self.knob setTransform:hiddenTransform];
        [self.knob setEnabled:NO];
        [self.buttonShowKnob setEnabled:YES];
    }
}

- (void) didPressShowKnob:(id)sender
{
    [self showKnobAnimated:YES delay:0.0f];
}

#pragma mark - KnobProtocol
- (void) didPressKnobCenter
{
    //HACK
    [_scanActivity setHidden:NO];
    [_scanActivity startAnimating];
    //HACK
    [[ScanManager getInstance] locateAndScanInMap:[self mapView] 
                                       completion:^(BOOL finished, NSArray* tradePosts){
                                           if(finished)
                                           {
                                               [self handleScanResultTradePosts:tradePosts];
                                           }
                                           //HACK
                                           [_scanActivity stopAnimating];
                                           [_scanActivity setHidden:YES];
                                           //HACK
                                       }];
}

@end
