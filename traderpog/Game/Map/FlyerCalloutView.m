//
//  FlyerCalloutView.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerCalloutView.h"
#import "FlyerCallout.h"
#import "Flyer.h"
#import "GameManager.h"

NSString* const kFlyerCalloutViewReuseId = @"FlyerCalloutView";

@interface FlyerCalloutView ()
@end

@implementation FlyerCalloutView
@synthesize buttonGoHome;
@synthesize buttonLoadNow;
@synthesize buttonUnloadNow;
@synthesize buttonCompleteNow;
- (id) initWithAnnotation:(id<MKAnnotation>)annotation
{
    self = [super initWithAnnotation:annotation reuseIdentifier:kFlyerCalloutViewReuseId];
    if(self)
    {
        [[NSBundle mainBundle] loadNibNamed:@"FlyerCalloutView" owner:self options:nil];
    }
    return self;
}

- (IBAction)didPressHome:(id)sender
{
    FlyerCallout* annot = (FlyerCallout*) [self annotation];
    [[GameManager getInstance] showHomeSelectForFlyer:[annot flyer]];

    // halt all other callouts for a second so that we don't get touch-through callouts popping up when
    // player presses Go
    [[GameManager getInstance] haltMapAnnotationCalloutsForDuration:0.5];
}

- (IBAction)didPressLoadNow:(id)sender
{
    FlyerCallout* annot = (FlyerCallout*)[self annotation];
    Flyer* flyer = [annot flyer];
    
    [flyer gotoState:kFlyerStateLoading];
    [self refreshLayoutWithFlyer:flyer];
    [self setNeedsDisplay];
}

- (IBAction)didPressUnloadNow:(id)sender
{
    FlyerCallout* annot = (FlyerCallout*)[self annotation];
    Flyer* flyer = [annot flyer];
    
    [flyer gotoState:kFlyerStateUnloading];
    [self refreshLayoutWithFlyer:flyer];
    [self setNeedsDisplay];
}

- (IBAction)didPressCompleteNow:(id)sender
{
    FlyerCallout* annot = (FlyerCallout*)[self annotation];
    Flyer* flyer = [annot flyer];
    
    if(kFlyerStateLoading == [flyer state])
    {
        [flyer gotoState:kFlyerStateLoaded];
    }
    else
    {
        [flyer gotoState:kFlyerStateIdle];
    }
    [self refreshLayoutWithFlyer:flyer];
    [self setNeedsDisplay];
}

#pragma mark - internal methods
- (void) refreshLayoutWithFlyer:(Flyer *)flyer
{
    [buttonGoHome setHidden:YES];
    [buttonLoadNow setHidden:YES];
    [buttonUnloadNow setHidden:YES];
    [buttonCompleteNow setHidden:YES];
    
    if(kFlyerStateLoaded == [flyer state])
    {
        [buttonGoHome setHidden:NO];
    }
    else if(kFlyerStateWaitingToLoad == [flyer state])
    {
        [buttonLoadNow setHidden:NO];
    }
    else if(kFlyerStateWaitingToUnload == [flyer state])
    {
        [buttonUnloadNow setHidden:NO];
    }
    else if((kFlyerStateLoading == [flyer state]) ||
            (kFlyerStateUnloading == [flyer state]))
    {
        [buttonCompleteNow setHidden:NO];
    }
    else
    {
        NSLog(@"Warning: flyer callout should not be shown when Flyer is in Idle state");
    }
}
@end
