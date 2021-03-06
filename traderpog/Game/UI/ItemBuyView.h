//
//  ItemBuyView.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/2/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewReuseDelegate.h"

extern NSString* const kItemBuyViewReuseIdentifier;

@class CircleButton;
@interface ItemBuyView : UIView<ViewReuseDelegate>
@property (nonatomic,strong) IBOutlet UIView* nibView;
@property (weak, nonatomic) IBOutlet UIView *nibContentView;
@property (weak, nonatomic) IBOutlet UIView *nibZeroStockView;
@property (weak, nonatomic) IBOutlet UIImageView *nibImageView;
@property (weak, nonatomic) IBOutlet CircleButton *closeCircle;
@property (weak, nonatomic) IBOutlet CircleButton *buyCircle;
@property (weak, nonatomic) IBOutlet UILabel *buyCircleLabel;
@property (weak, nonatomic) IBOutlet UILabel *itemNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *numItemsLabel;
@property (weak, nonatomic) IBOutlet UILabel *costLabel;
@property (weak, nonatomic) IBOutlet UILabel *smallFeeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *coinImageView;

- (void) addButtonTarget:(id)target;

@end
