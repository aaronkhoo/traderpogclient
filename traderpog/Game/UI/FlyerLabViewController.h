//
//  FlyerLabViewController.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/7/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CircleButton.h"

@interface FlyerLabViewController : UIViewController
@property (weak, nonatomic) IBOutlet CircleButton *closeCircle;

- (IBAction)didPressCustomize:(id)sender;
- (IBAction)didPressUpgrade:(id)sender;
@end
