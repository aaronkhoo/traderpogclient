//
//  CircleButton.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/3/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CircleButton : UIView
@property (nonatomic,strong) UIImageView* imageView;

+ (UIColor*) defaultBgColor;
+ (UIColor*) defaultBorderColor;
+ (float) defaultBorderWidth;
- (void) setBorderWidth:(float)borderWidth;
- (void) setBorderColor:(UIColor*)borderColor;
@end
