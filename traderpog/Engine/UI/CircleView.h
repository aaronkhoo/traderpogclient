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

- (id)initWithFrame:(CGRect)frame
        borderWidth:(CGFloat)borderWidth
        borderColor:(UIColor*)borderColor;

@end
