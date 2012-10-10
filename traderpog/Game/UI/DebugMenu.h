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
@property (weak, nonatomic) IBOutlet UISwitch *speed100xSwitch;
@property (weak, nonatomic) IBOutlet UIButton *leaderboardsButton;

- (IBAction)didPressClearCache:(id)sender;
- (IBAction)didPressClose:(id)sender;
- (IBAction)didPressAdd200Coins:(id)sender;
- (IBAction)didPressLoading:(id)sender;
- (IBAction)didPressLeaderboards:(id)sender;
- (IBAction)didPressFlyerUpgrade:(id)sender;
- (IBAction)didPressProducts:(id)sender;
@end
