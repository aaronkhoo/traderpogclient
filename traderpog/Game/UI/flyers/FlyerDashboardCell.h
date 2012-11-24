//
//  FlyerDashboardCell.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 11/18/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FlyerDashboardCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView* flyerImageView;
@property (weak, nonatomic) IBOutlet UIImageView* itemImageView;
@property (weak, nonatomic) IBOutlet UILabel* capLabel;
@property (weak, nonatomic) IBOutlet UILabel* statusLabel;
@property (weak, nonatomic) IBOutlet UILabel* timeLabel;
@property (weak, nonatomic) IBOutlet UIView* goSubview;
@property (weak, nonatomic) IBOutlet UIView* addFlyerSubview;

@end
