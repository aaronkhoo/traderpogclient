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
}
@property (nonatomic,strong) KnobControl* knob;
- (void) initKnob;
- (void) shutdownKnob;
- (void) showKnobAnimated:(BOOL)isAnimated;
- (void) dismissKnobAnimated:(BOOL)isAnimated;
@end

@implementation GameViewController
@synthesize mapView;
@synthesize mapControl = _mapControl;
@synthesize knob = _knob;

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
static const float kKnobRadiusFrac = 0.4f;
static const float kKnobHiddenYOffsetFrac = (kKnobRadiusFrac * 0.4f);

- (void) initKnob
{
    CGRect viewFrame = self.view.frame;
    float knobRadius = kKnobRadiusFrac * viewFrame.size.width;
    CGRect knobFrame = CGRectMake((viewFrame.size.width - knobRadius)/2.0f, 
                                  viewFrame.size.height - (knobRadius / 2.0f),
                                  knobRadius, knobRadius);
    self.knob = [[KnobControl alloc] initWithFrame:knobFrame numSlices:4];
    [self.view addSubview:[self knob]];
    
    [self dismissKnobAnimated:NO];
}

- (void) shutdownKnob
{
    [self.knob removeFromSuperview];
    self.knob = nil;    
}

- (void) showKnobAnimated:(BOOL)isAnimated
{
    CGAffineTransform showTransform = CGAffineTransformIdentity;
    [self.knob setEnabled:YES];
    if(isAnimated)
    {
        [UIView animateWithDuration:kKnobAnimOutDuration 
                         animations:^(void){
                             [self.knob setTransform:showTransform];
                         }
                         completion:nil];
    }
    else 
    {
        [self.knob setTransform:showTransform];
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


@end
