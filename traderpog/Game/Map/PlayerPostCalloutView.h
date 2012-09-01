//
//  PlayerPostCalloutView.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/17/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CalloutView.h"

extern NSString* const kPlayerPostCalloutViewReuseId;
@interface PlayerPostCalloutView : CalloutView
@property (weak, nonatomic) IBOutlet UIButton *beaconButton;
@property (weak, nonatomic) IBOutlet UIView *restockBubble;
@property (weak, nonatomic) IBOutlet UIView *beaconBubble;
@property (weak, nonatomic) IBOutlet UIView *destroyBubble;
@property (weak, nonatomic) IBOutlet UIView *beaconLabelContainer;
@property (weak, nonatomic) IBOutlet UIView *restockLabelContainer;
@property (weak, nonatomic) IBOutlet UIView *destroyLabelContainer;
- (IBAction)didPressSetBeacon:(id)sender;
- (IBAction)didPressRestock:(id)sender;
- (IBAction)didPressDestroy:(id)sender;

@end
