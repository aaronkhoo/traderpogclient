//
//  AppDelegate.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/5/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AppDelegate.h"
#import "StartScreen.h"
#import "ImageManager.h"

@interface AppDelegate()
{
    NSDate* _lastEnteredBackgroundDate;
}
@property (nonatomic,retain) NSDate* lastEnteredBackgroundDate;
- (void) appInit;
- (void) appShutdown;
- (void) setupNavigationController;
- (void) teardownNavigationController;
@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize rootController = _rootController;
@synthesize navController = _navController;
@synthesize lastEnteredBackgroundDate = _lastEnteredBackgroundDate;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    // setup navigation controller
    [self setupNavigationController];
    
    _lastEnteredBackgroundDate = nil;
    [self appInit];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self appShutdown];
    [self teardownNavigationController];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application 
{
    // memory warning
    
    // unload frontmenu backgroud if we're not in the frontend
    UIViewController* topController = [self.navController topViewController];
    if(![topController isMemberOfClass:[StartScreen class]])
    {
        [[ImageManager getInstance] unloadFrontMenuBackground];
    }
}

#pragma mark - private methods
- (void) appInit
{
    [ImageManager getInstance];

    // load up frontmenu background
    [[ImageManager getInstance] loadFrontMenuBackground];
}

- (void) appShutdown
{
    [ImageManager destroyInstance];
}

- (void) setupNavigationController
{
    // create the root view controller first
    self.rootController = [[StartScreen alloc] initWithNibName:@"StartScreen" bundle:nil];
    
    // add it to our navigation controller
    self.navController = [[UINavigationController alloc] initWithRootViewController:[self rootController]];
    [self.navController setNavigationBarHidden:YES];
    [self.window addSubview:[[self navController]view]];
}

- (void) teardownNavigationController
{
    [self.navController.view removeFromSuperview];
    self.rootController = nil;
    self.navController = nil;
}

@end
