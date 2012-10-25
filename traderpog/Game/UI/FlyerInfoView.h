//
//  FlyerInfoView.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/23/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewReuseDelegate.h"

extern NSString* const kFlyerInfoViewReuseIdentifier;

@class CircleButton;
@class Flyer;
@interface FlyerInfoView : UIView<ViewReuseDelegate>
@property (strong, nonatomic) IBOutlet UIView *nibView;
@property (weak, nonatomic) IBOutlet UIView *nibContentView;
@property (weak, nonatomic) IBOutlet UIView *contentScrim;
@property (weak, nonatomic) IBOutlet UIView *nibTitleView;
@property (weak, nonatomic) IBOutlet CircleButton *closeCircle;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *itemImageView;
@property (weak, nonatomic) IBOutlet UILabel *itemNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *itemNumLabel;
@property (weak, nonatomic) IBOutlet UILabel *capacityLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeTillDestTitle;
@property (weak, nonatomic) IBOutlet UILabel *timeTillDestLabel;
@property (weak, nonatomic) IBOutlet UILabel *flyerStateLabel;
@property (weak, nonatomic) IBOutlet CircleButton *goCircle;
@property (weak, nonatomic) IBOutlet UILabel *goLabel;
@property (weak, nonatomic) IBOutlet UILabel *homeLabel;

- (void) refreshViewForFlyer:(Flyer*)flyer;
@end
