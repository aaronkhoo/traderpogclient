//
//  CircleButton.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/3/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CircleButton : UIView
{
    BOOL _enabled;
}
@property (nonatomic,strong) UIButton* button;
@property (nonatomic,readonly) BOOL isEnabled;

+ (UIColor*) defaultBgColor;
+ (UIColor*) defaultBorderColor;
+ (float) defaultBorderWidth;
- (void) setBorderWidth:(float)borderWidth;
- (void) setBorderColor:(UIColor*)borderColor;
- (void) setButtonTarget:(id)target action:(SEL)actionSelector;
- (void) removeButtonTarget;

- (void) disableCircle;
- (void) enableCircle;
@end
