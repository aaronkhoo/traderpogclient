//
//  DebugMenu.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/8/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DebugMenu : UIViewController
@property (weak, nonatomic) IBOutlet UISwitch *localDevSwitch;

- (IBAction)didPressClose:(id)sender;
- (IBAction)didPressResetGame:(id)sender;
- (IBAction)didPressAdd200Coins:(id)sender;
@end
