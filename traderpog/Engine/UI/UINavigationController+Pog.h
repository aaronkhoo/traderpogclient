//
//  UINavigationController+Pog.h
//  pogmatch
//
//  Created by Shu Chiun Cheah on 1/26/12.
//  Copyright (c) 2012 GeoloPigs, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UINavigationController (Pog)
- (void) pushFadeInViewController:(UIViewController*)controller animated:(BOOL)isAnimated;
- (void) popFadeOutViewControllerAnimated:(BOOL)isAnimated;
- (void) popFadeOutToRootViewControllerAnimated:(BOOL)isAnimated;
- (void) pushFromLeftViewController:(UIViewController*)controller animated:(BOOL)isAnimated;
- (void) pushFromRightViewController:(UIViewController*)controller animated:(BOOL)isAnimated;
- (void) popToLeftViewControllerAnimated:(BOOL)isAnimated;
- (void) popToLeftToRootViewControllerAnimated:(BOOL)isAnimated;
- (void) popToRightViewControllerAnimated:(BOOL)isAnimated;
@end
