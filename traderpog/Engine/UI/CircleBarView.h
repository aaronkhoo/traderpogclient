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
    UIView*     _leftCircle;
    UIView*     _rightBar;
    UILabel*    _label;
    UIColor*    _barColor;
    UIColor*    _textColor;
    UIColor*    _borderColor;
    float       _borderWidth;
    float       _textSize;
    float       _barHeightFrac;
    BOOL        _hasRoundCorner;
}
@property (nonatomic,strong) UIView* leftCircle;
@property (nonatomic,strong) UIView* rightBar;
@property (nonatomic,strong) UILabel* label;
@property (nonatomic,strong) UIColor* barColor;
@property (nonatomic,strong) UIColor* textColor;
@property (nonatomic,strong) UIColor* borderColor;
@property (nonatomic) float borderWidth;
@property (nonatomic) float textSize;
@property (nonatomic) float barHeightFrac;
@property (nonatomic) BOOL hasRoundCorner;

- (id)initWithFrame:(CGRect)frame
              color:(UIColor*)color
          textColor:(UIColor*)colorForText
        borderColor:(UIColor*)colorForBorder
        borderWidth:(float)widthForBorder
           textSize:(float)sizeForText
      barHeightFrac:(float)heightFracForBar
     hasRoundCorner:(BOOL)roundCorner;
@end
