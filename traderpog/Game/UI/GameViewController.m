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

@interface GameViewController ()
{
    CLLocationCoordinate2D _initCoord;
    KnobControl* _knob;
    UIButton* _buttonShowKnob;
}
@property (nonatomic,strong) KnobControl* knob;
@property (nonatomic,strong) UIButton* buttonShowKnob;
- (void) initKnob;
- (void) shutdownKnob;
- (void) didPressShowKnob:(id)sender;
@end

@implementation GameViewController
@synthesize mapView;
@synthesize mapControl = _mapControl;
@synthesize knob = _knob;
@synthesize buttonShowKnob = _buttonShowKnob;

- (id)initAtCoordinate:(CLLocationCoordinate2D)coord
{
    self = [super initWithNibName:@"GameViewController" bundle:nil];
    if (self) 
    {
        _initCoord = coord;
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
}

- (void)viewDidUnload
{
    self.mapControl = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
                         completion:nil];
    }
    else 
    {
        [self.knob setTransform:showTransform];
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


@end
