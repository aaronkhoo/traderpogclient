//
//  ItemBubble.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/2/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ItemBubble : UIView
@property (nonatomic,strong) UIImageView* imageView;
@property (nonatomic,strong) UILabel* itemLabel;
@property (nonatomic,strong) UIView* backgroundView;

- (id) initWithFrame:(CGRect)frame borderWidth:(float)borderWidth color:(UIColor*)color borderColor:(UIColor*)borderColor;
@end
