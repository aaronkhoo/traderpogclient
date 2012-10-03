//
//  ItemBuyView.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/2/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CircleButton;
@interface ItemBuyView : UIView
@property (nonatomic,strong) IBOutlet UIView* nibView;
@property (weak, nonatomic) IBOutlet UIView *nibContentView;
@property (weak, nonatomic) IBOutlet UIImageView *nibImageView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *buyButton;

@property (nonatomic,strong) UIView* closeView;
@property (nonatomic,strong) UIView* okView;
@property (nonatomic,strong) UIView* contentView;
@property (nonatomic,strong) UIImageView* itemImageView;

@end
