//
//  FlyerLabViewController.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/7/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CircleButton.h"

@class Flyer;
@interface FlyerLabViewController : UIViewController
{
    Flyer *_flyer;
}
@property (nonatomic,strong) Flyer* flyer;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet CircleButton *closeCircle;
@property (weak, nonatomic) IBOutlet UIButton *upgradeButton;

- (IBAction)didPressCustomize:(id)sender;
- (IBAction)didPressUpgrade:(id)sender;
@end
