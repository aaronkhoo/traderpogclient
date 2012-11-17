//
//  FlyerGoCell.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 11/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FlyerGoCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView* flyerImageView;
@property (weak, nonatomic) IBOutlet UIImageView* itemImageView;
@property (weak, nonatomic) IBOutlet UILabel *distLabel;
@property (weak, nonatomic) IBOutlet UILabel *capLabel;
@property (weak, nonatomic) IBOutlet UIView* goSubview;
@property (weak, nonatomic) IBOutlet UIView* addFlyerSubview;

@end
