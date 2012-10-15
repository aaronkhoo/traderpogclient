//
//  AppDelegate.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/5/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class StartScreen;
@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    UINavigationController *_navController;
    
    NSTimer*	soundLoopTimer;
}
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navController;
@property (strong, nonatomic) StartScreen *rootController;

@end
