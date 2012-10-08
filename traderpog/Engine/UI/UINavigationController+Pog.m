//
//  UINavigationController+Pog.m
//  pogmatch
//
//  Created by Shu Chiun Cheah on 1/26/12.
//  Copyright (c) 2012 GeoloPigs, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "UINavigationController+Pog.h"

@implementation UINavigationController (Pog)

- (void) pushFadeInViewController:(UIViewController *)controller animated:(BOOL)isAnimated
{
    if(isAnimated)
    {
        [CATransaction begin];
        
        CATransition *transition;
        transition = [CATransition animation];
        transition.type = kCATransitionFade;
        transition.subtype = nil;
        transition.duration = 0.6;
        
        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        [self pushViewController:controller animated:YES];
        [[[[self.view subviews] objectAtIndex:0] layer] addAnimation:transition forKey:nil];
        
        [CATransaction commit];
    }
    else
    {
        [self pushViewController:controller animated:NO];
    }
}

- (void) popFadeOutViewControllerAnimated:(BOOL)isAnimated
{
    if(isAnimated)
    {
        [CATransaction begin];
        
        CATransition *transition;
        transition = [CATransition animation];
        transition.type = kCATransitionFade;
        transition.subtype = nil;
        transition.duration = 0.2;
        
        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        
        [[[[self.view subviews] objectAtIndex:0] layer] addAnimation:transition forKey:nil];
        
        [CATransaction setCompletionBlock:^(void) {
            [self popViewControllerAnimated:NO];
        }];
        [CATransaction commit];   
    }
    else
    {
        [self popViewControllerAnimated:NO];
    }
}

- (void) popFadeOutToRootViewControllerAnimated:(BOOL)isAnimated
{
    if(isAnimated)
    {
        [CATransaction begin];
        
        CATransition *transition;
        transition = [CATransition animation];
        transition.type = kCATransitionFade;
        transition.subtype = nil;
        transition.duration = 0.4;
        
        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        
        [[[[self.view subviews] objectAtIndex:0] layer] addAnimation:transition forKey:nil];
        
        [self  popToRootViewControllerAnimated:YES];
        [CATransaction commit];   
    }
    else
    {
        [self popToRootViewControllerAnimated:NO];
    }
}

- (void) pushFromLeftViewController:(UIViewController*)controller animated:(BOOL)isAnimated
{
    if(isAnimated)
    {
        [CATransaction begin];
        
        CATransition *transition;
        transition = [CATransition animation];
        transition.type = kCATransitionMoveIn;          // Use any animation type and subtype you like
        transition.subtype = kCATransitionFromLeft;
        transition.duration = 0.2;
        
        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        
        [self pushViewController:controller animated:YES];
        [[[[self.view subviews] objectAtIndex:0] layer] addAnimation:transition forKey:nil];
        
        [CATransaction commit];    
    }
    else
    {
        [self pushViewController:controller animated:NO];
    }
}


- (void) pushFromRightViewController:(UIViewController*)controller animated:(BOOL)isAnimated
{
    if(isAnimated)
    {
        [CATransaction begin];
        
        CATransition *transition;
        transition = [CATransition animation];
        transition.type = kCATransitionMoveIn;          // Use any animation type and subtype you like
        transition.subtype = kCATransitionFromRight;
        transition.duration = 0.2;
        
        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        
        [self pushViewController:controller animated:YES];
        [[[[self.view subviews] objectAtIndex:0] layer] addAnimation:transition forKey:nil];
        
        [CATransaction commit];    
    }
    else
    {
        [self pushViewController:controller animated:NO];
    }
}

- (void) popToLeftViewControllerAnimated:(BOOL)isAnimated
{
    if(isAnimated)
    {
        [CATransaction begin];
        
        CATransition *transition;
        transition = [CATransition animation];
        transition.type = kCATransitionReveal;          // Use any animation type and subtype you like
        transition.subtype = kCATransitionFromRight;
        transition.duration = 0.2;
        
        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        
        [[[[self.view subviews] objectAtIndex:0] layer] addAnimation:transition forKey:nil];
        
        [self  popViewControllerAnimated:YES];
        [CATransaction commit];   
    }
    else
    {
        [self popViewControllerAnimated:NO];
    }
}

- (void) popToLeftToRootViewControllerAnimated:(BOOL)isAnimated
{
    if(isAnimated)
    {
        [CATransaction begin];
        
        CATransition *transition;
        transition = [CATransition animation];
        transition.type = kCATransitionReveal;          // Use any animation type and subtype you like
        transition.subtype = kCATransitionFromRight;
        transition.duration = 0.2;
        
        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        
        [[[[self.view subviews] objectAtIndex:0] layer] addAnimation:transition forKey:nil];
        
        [self  popToRootViewControllerAnimated:YES];
        [CATransaction commit];   
    }
    else
    {
        [self popToRootViewControllerAnimated:NO];
    }
}

- (void) popToRightViewControllerAnimated:(BOOL)isAnimated
{
    if(isAnimated)
    {
        [CATransaction begin];
        
        CATransition *transition;
        transition = [CATransition animation];
        transition.type = kCATransitionReveal;          // Use any animation type and subtype you like
        transition.subtype = kCATransitionFromLeft;
        transition.duration = 0.2;
        
        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        
        [[[[self.view subviews] objectAtIndex:0] layer] addAnimation:transition forKey:nil];
        
        [self  popViewControllerAnimated:YES];
        [CATransaction commit];   
    }
    else
    {
        [self popViewControllerAnimated:NO];
    }
}

@end
