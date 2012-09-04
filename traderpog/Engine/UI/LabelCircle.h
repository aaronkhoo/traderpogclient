//
//  LabelCircle.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/4/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LabelCircle : UIView
@property (nonatomic,strong) UILabel* label;

- (id) initWithFrame:(CGRect)frame
         borderWidth:(CGFloat)borderWidth
         borderColor:(UIColor*)borderColor
             bgColor:(UIColor*)bgColor;
@end
