//
//  FlyerCustomize.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CircleButton.h"

@class Flyer;
@interface FlyerCustomize : UIViewController
{
    Flyer* _flyer;
}
@property (weak, nonatomic) IBOutlet CircleButton *closeCircle;
@property (weak, nonatomic) IBOutlet CircleButton *buyCircle;
@property (weak, nonatomic) IBOutlet UILabel *buyLabel;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIView *contentSubView;
@property (weak, nonatomic) IBOutlet UIView *titleView;
@property (weak, nonatomic) IBOutlet UIImageView *coinImageView;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UIView *optionOriginal;
@property (weak, nonatomic) IBOutlet UIView *origBar;
@property (weak, nonatomic) IBOutlet UIView *option1;
@property (weak, nonatomic) IBOutlet UIView *bar1;
@property (weak, nonatomic) IBOutlet UIView *option2;
@property (weak, nonatomic) IBOutlet UIView *bar2;
@property (weak, nonatomic) IBOutlet UIView *option3;
@property (weak, nonatomic) IBOutlet UIView *bar3;
@property (weak, nonatomic) IBOutlet UIImageView *origImage;
@property (weak, nonatomic) IBOutlet UIImageView *image1;
@property (weak, nonatomic) IBOutlet UIImageView *image2;
@property (weak, nonatomic) IBOutlet UIImageView *image3;
@property (weak, nonatomic) IBOutlet UIImageView *membershipImage2;
@property (weak, nonatomic) IBOutlet UIImageView *membershipImage3;

- (id) initWithFlyer:(Flyer*)flyer;
- (IBAction)didPressOptionOriginal:(id)sender;
- (IBAction)didPressOption1:(id)sender;
- (IBAction)didPressOption2:(id)sender;
- (IBAction)didPressOption3:(id)sender;

@end
