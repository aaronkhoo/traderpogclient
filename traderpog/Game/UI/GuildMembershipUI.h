//
//  GuildMembershipUI.h
//  traderpog
//
//  Created by Aaron Khoo on 10/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CircleButton;
@interface GuildMembershipUI : UIViewController
@property (weak, nonatomic) IBOutlet UILabel* testText;
@property (weak, nonatomic) IBOutlet UIButton* buyButton;
@property (weak, nonatomic) IBOutlet CircleButton *closeCircle;
@property (weak, nonatomic) IBOutlet UILabel *productLabel1;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel1;
@property (weak, nonatomic) IBOutlet UIView *productContainer;

- (IBAction)didPressBuy:(id)sender;

@end
