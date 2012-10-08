//
//  PlayerSalesScreen.h
//  traderpog
//
//  Created by Aaron Khoo on 10/5/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlayerSalesScreen : UIViewController
@property (weak, nonatomic) IBOutlet UILabel* mainText;
@property (weak, nonatomic) IBOutlet UILabel* fbName1;
@property (weak, nonatomic) IBOutlet UILabel* fbName2;
@property (weak, nonatomic) IBOutlet UILabel* fbName3;
@property (weak, nonatomic) IBOutlet UILabel* fbName4;
@property (weak, nonatomic) IBOutlet UILabel* fbName5;
@property (weak, nonatomic) IBOutlet UIImageView* fbImage1;
@property (weak, nonatomic) IBOutlet UIImageView* fbImage2;
@property (weak, nonatomic) IBOutlet UIImageView* fbImage3;
@property (weak, nonatomic) IBOutlet UIImageView* fbImage4;
@property (weak, nonatomic) IBOutlet UIImageView* fbImage5;
@property (weak, nonatomic) IBOutlet UIButton* okButton;

@end
