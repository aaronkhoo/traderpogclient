//
//  GuildMembershipUI.h
//  traderpog
//
//  Created by Aaron Khoo on 10/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GuildMembershipUI : UIViewController
@property (weak, nonatomic) IBOutlet UILabel* testText;
@property (weak, nonatomic) IBOutlet UIButton* buyButton;

- (IBAction)didPressClose:(id)sender;

@end
