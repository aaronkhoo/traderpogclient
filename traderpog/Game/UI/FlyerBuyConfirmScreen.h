//
//  FlyerBuyConfirmScreen.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/18/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CircleButton.h"

@class FlyerType;
@interface FlyerBuyConfirmScreen : UIViewController
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIView *titleView;
@property (weak, nonatomic) IBOutlet CircleButton *closeCircle;
@property (weak, nonatomic) IBOutlet CircleButton *buyCircle;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *flyerNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *flyerDescLabel;
@property (weak, nonatomic) IBOutlet UILabel *buyButtonLabel;
@property (weak, nonatomic) IBOutlet UIImageView *membershipLabel;

- (id) initWithFlyerType:(FlyerType*)flyerType;
@end
