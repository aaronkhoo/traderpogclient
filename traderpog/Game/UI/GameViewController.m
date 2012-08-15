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
    [[TradePostMgr getInstance] annotatePostsOnMap];
    [[FlyerMgr getInstance] annotateFlyersOnMap];
    [[BeaconMgr getInstance] addBeaconAnnotationsToMap:[self mapControl]];
    
    // create knob
    [self initKnob];
    [self initWheels];
    
    [self startDisplayLink];
}

- (void)viewDidUnload
{
    [self stopDisplayLink];
    
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
static const float kKnobRadiusFrac = 0.5f;  // frac of view-width
static const float kKnobFrameYOffsetFrac = (kKnobRadiusFrac * 0.05f);
static const float kKnobHiddenYOffsetFrac = (kKnobRadiusFrac * 0.4f); // frac of view-width
static const float kKnobShowButtonHeightFrac = 0.05f;   // frac of view-height
static const float kWheelRadiusFrac = 0.75f;
static const float kWheelPreviewXViewFrac = 0.0f;
static const float kWheelPreviewYHeightFrac = 1.75f;
static const float kWheelPreviewSizeFrac = 0.35f * 2.0f; // in terms of wheel radius
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
            result = [UIColor colorWithRed:0.0f/255.0f green:112.0f/255.0f blue:185.0f/255.0f alpha:alpha];
            break;
            
        case kKnobSliceBeacon:
            result = [UIColor colorWithRed:2.0f/255.0f green:64.0f/255.0f blue:116.0f/255.0f alpha:alpha];
            break;
            
        case kKnobSlicePost:
            result = [UIColor colorWithRed:229.0f/255.0f green:54.0f/255.0f blue:9.0f/255.0f alpha:alpha];
            break;
            
        default:
        case kKnobSliceScan:
            result = [UIColor colorWithRed:8.0f/255.0f green:67.0f/255.0f blue:67.0f/255.0f alpha:alpha];
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
            result = [UIColor colorWithRed:93.0f/255.0f green:155.0f/255.0f blue:207.0f/255.0f alpha:1.0f];
            break;
            
        case kKnobSliceBeacon:
            result = [UIColor colorWithRed:27.0f/255.0f green:89.0f/255.0f blue:141.0f/255.0f alpha:1.0f];
            break;
            
        case kKnobSlicePost:
            result = [UIColor colorWithRed:177.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:1.0f];
            break;
            
        default:
        case kKnobSliceScan:
            result = [UIColor colorWithRed:48.0f/255.0f green:80.0f/255.0f blue:107.0f/255.0f alpha:1.0f];
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
}

- (void) knob:(KnobControl *)knob didSettleAt:(unsigned int)index
{
    
}

@end
