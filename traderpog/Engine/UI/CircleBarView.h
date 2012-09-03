//
//  CircleBarView.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/3/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CircleBarView : UIView
{
    UIView* _leftCircle;
    UIView* _rightBar;
    UILabel* _label;
    UIColor* _barColor;
    UIColor* _textColor;
}
@property (nonatomic,strong) UIView* leftCircle;
@property (nonatomic,strong) UIView* rightBar;
@property (nonatomic,strong) UILabel* label;
@property (nonatomic,strong) UIColor* barColor;
@property (nonatomic,strong) UIColor* textColor;

- (id)initWithFrame:(CGRect)frame color:(UIColor*)color textColor:(UIColor*)colorForText;
@end
