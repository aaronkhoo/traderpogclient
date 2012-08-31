//
//  PlayerPostCalloutView.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/17/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "PlayerPostCalloutView.h"
#import "PlayerPostCallout.h"
#import "BeaconMgr.h"
#import "TradePost.h"
#import "PogUIUtility.h"

NSString* const kPlayerPostCalloutViewReuseId = @"PlayerPostCalloutView";

@interface PlayerPostCalloutView ()
- (void) initRender;
@end

@implementation PlayerPostCalloutView
@synthesize beaconButton;
@synthesize restockBubble;
@synthesize beaconBubble;
@synthesize destroyBubble;

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
    [PogUIUtility setCircleForView:[self restockBubble]];
    [PogUIUtility setCircleForView:[self beaconBubble]];
    [PogUIUtility setCircleForView:[self destroyBubble]];
}

#pragma mark - button actions

- (IBAction)didPressSetBeacon:(id)sender
{
    TradePost* thisPost = (TradePost*)[self.parentAnnotationView annotation];
    if(thisPost)
    {
        NSLog(@"Set Beacon for PostId %@", [thisPost postId]);
        [thisPost setBeacon];
        beaconButton.enabled = NO;
    }
}

- (IBAction)didPressRestock:(id)sender
{
    NSLog(@"Restock");
}

- (IBAction)didPressDestroy:(id)sender
{
    NSLog(@"Destroy");
}
@end
