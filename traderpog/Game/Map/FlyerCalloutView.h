//
//  FlyerCalloutView.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CalloutAnnotationView.h"

extern NSString* const kFlyerCalloutViewReuseId;
@class Flyer;
@interface FlyerCalloutView : CalloutAnnotationView

@property (weak, nonatomic) IBOutlet UIButton *buttonGoHome;
@property (weak, nonatomic) IBOutlet UIButton *buttonLoadNow;
@property (weak, nonatomic) IBOutlet UIButton *buttonUnloadNow;
@property (weak, nonatomic) IBOutlet UIButton *buttonCompleteNow;

- (void) refreshLayoutWithFlyer:(Flyer*)flyer;

- (IBAction)didPressHome:(id)sender;
- (IBAction)didPressLoadNow:(id)sender;
- (IBAction)didPressUnloadNow:(id)sender;
- (IBAction)didPressCompleteNow:(id)sender;
@end
