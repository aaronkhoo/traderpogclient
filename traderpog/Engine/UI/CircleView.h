//
//  CircleView.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/4/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CircleView : UIView
@property (nonatomic,strong) UIView* coloredView;
@property (nonatomic,strong) UIView* borderCircle;
@property (nonatomic,strong) UIView* centerBg;

- (id)initWithFrame:(CGRect)frame
         borderFrac:(float)borderFrac
        borderWidth:(CGFloat)borderWidth
        borderColor:(UIColor*)borderColor;

- (void) showBigBorder;
- (void) showSmallBorder;

@end
