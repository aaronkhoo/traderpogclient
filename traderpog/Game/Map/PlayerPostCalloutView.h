//
//  PlayerPostCalloutView.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/17/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CalloutAnnotationView.h"

extern NSString* const kPlayerPostCalloutViewReuseId;
@interface PlayerPostCalloutView : CalloutAnnotationView
@property (weak, nonatomic) IBOutlet UIButton *beaconButton;
- (IBAction)didPressSetBeacon:(id)sender;
- (IBAction)didPressRestock:(id)sender;
- (IBAction)didPressDestroy:(id)sender;

@end
