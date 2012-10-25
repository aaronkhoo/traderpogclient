//
//  PlayerSalesScreen.h
//  traderpog
//
//  Created by Aaron Khoo on 10/5/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CircleButton;
@interface PlayerSalesScreen : UIViewController
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UILabel* mainText;
@property (weak, nonatomic) IBOutlet UILabel* fbName1;
@property (weak, nonatomic) IBOutlet UILabel* fbName2;
@property (weak, nonatomic) IBOutlet UILabel* fbName3;
@property (weak, nonatomic) IBOutlet UILabel* fbName4;
@property (weak, nonatomic) IBOutlet UIImageView* fbImage1;
@property (weak, nonatomic) IBOutlet UIImageView* fbImage2;
@property (weak, nonatomic) IBOutlet UIImageView* fbImage3;
@property (weak, nonatomic) IBOutlet UIImageView* fbImage4;
@property (weak, nonatomic) IBOutlet UILabel *earningsLabel;
@property (weak, nonatomic) IBOutlet UIImageView *coinImageView;
@property (weak, nonatomic) IBOutlet CircleButton *okCircle;

@end
