//
//  AppDelegate.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/5/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AppDelegate.h"
#import "AsyncHttpCallMgr.h"
#import "StartScreen.h"
#import "ImageManager.h"
#import "GameManager.h"
#import "TradePostMgr.h"
#import "TradeItemTypes.h"
#import "Player.h"
#import "ScanManager.h"
#import "Flyer.h"
#import "FlyerMgr.h"
#import "FlyerTypes.h"
#import "BeaconMgr.h"
#import "ResourceManager.h"
#import "AnimMgr.h"
#import "LocalyticsSession.h"
#import "LeaderboardMgr.h"
#import "GameEventMgr.h"
#import "PlayerSales.h"
#import "UrlImageManager.h"
#import "SoundManager.h"
#import "ProductManager.h"
#import <RevMobAds/RevMobAds.h>

static const float kAppScreenWidth = 320.0f;
static const float kAppScreenHeight = 480.0f;
static const CGFloat SOUNDLOOP_INTERVAL_SECS = 1.0f / 30.0f;

@interface AppDelegate()
{
    NSDate* _lastEnteredBackgroundDate;
}
@property (nonatomic,retain) NSDate* lastEnteredBackgroundDate;
- (void) appInit;
- (void) appShutdown;
- (void) setupNavigationController;
- (void) teardownNavigationController;
- (void) soundLoop;
@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize rootController = _rootController;
@synthesize navController = _navController;
@synthesize lastEnteredBackgroundDate = _lastEnteredBackgroundDate;

- (void) soundLoop
{
    // pump sound manager
    [[SoundManager getInstance] update];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [[[Player getInstance] facebook] handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [[[Player getInstance] facebook] handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //[RevMobAds startSessionWithAppID:@"5063b48ba0aeaf0800000034"];
    [RevMobAds startSessionWithAppID:@"5063b48ba0aeaf0800000034" testingMode:RevMobAdsTestingModeWithAds];

    [[LocalyticsSession sharedLocalyticsSession] startSession:@"bf2f53386fe1651bfdea3f1-5feaa8ac-044b-11e2-5623-00ef75f32667"];
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    float originX = 0.5f * (screenBounds.size.width - kAppScreenWidth);
    float originY = 0.5f * (screenBounds.size.height - kAppScreenHeight);
    self.window = [[UIWindow alloc] initWithFrame:CGRectMake(originX, originY, kAppScreenWidth, kAppScreenHeight)];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    self.window.clipsToBounds = YES;

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
    
    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];
    
    // resign sound
    [[SoundManager getInstance] resignActive];
    if(soundLoopTimer)
    {
        [soundLoopTimer invalidate];
        soundLoopTimer = nil;
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];
    
    [[AsyncHttpCallMgr getInstance] applicationDidEnterBackground];
    [[FlyerMgr getInstance] saveFlyerMgrData];
    [[Player getInstance] appDidEnterBackground];
    [[GameManager getInstance] applicationDidEnterBackground];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    [[LocalyticsSession sharedLocalyticsSession] resume];
    [[LocalyticsSession sharedLocalyticsSession] upload];
    
    [[GameManager getInstance] applicationWillEnterForeground];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    [[LocalyticsSession sharedLocalyticsSession] resume];
    [[LocalyticsSession sharedLocalyticsSession] upload];
    
    // unresign sound
    if(!soundLoopTimer)
    {
        soundLoopTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval) SOUNDLOOP_INTERVAL_SECS
                                                          target:self
                                                        selector:@selector(soundLoop)
                                                        userInfo:nil
                                                         repeats:YES];
        [[SoundManager getInstance] restoreActive];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];
    
    [[AsyncHttpCallMgr getInstance] applicationWillTerminate];
    [[FlyerMgr getInstance] saveFlyerMgrData];
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
    [Player getInstance];
    [TradeItemTypes getInstance];
    [TradePostMgr getInstance];
    [FlyerTypes getInstance];
    [FlyerMgr getInstance];
    [BeaconMgr getInstance];
    [GameManager getInstance];
    [ScanManager getInstance];
    [ResourceManager getInstance];
    [AsyncHttpCallMgr getInstance];
    [AnimMgr getInstance];
    [LeaderboardMgr getInstance];
    [GameEventMgr getInstance];
    [PlayerSales getInstance];
    [UrlImageManager getInstance];
    [ProductManager getInstance];
    
    [SoundManager getInstance];
    soundLoopTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval) SOUNDLOOP_INTERVAL_SECS
                                                      target:self
                                                    selector:@selector(soundLoop)
                                                    userInfo:nil
                                                     repeats:YES];
    
    // Setting up the HTTP callback delegates
    [[Player getInstance] setDelegate:[GameManager getInstance]];
    [[TradeItemTypes getInstance] setDelegate:[GameManager getInstance]];
    [[TradePostMgr getInstance] setDelegate:[GameManager getInstance]];
    [[FlyerTypes getInstance] setDelegate:[GameManager getInstance]];
    [[FlyerMgr getInstance] setDelegate:[GameManager getInstance]];
    [[ResourceManager getInstance] setDelegate:[GameManager getInstance]];
    [[BeaconMgr getInstance] setDelegate:[GameManager getInstance]];
    [[PlayerSales getInstance] setDelegate:[GameManager getInstance]];
    
    // Setting up callback for scanning
    [[TradePostMgr getInstance] setDelegateScan:[ScanManager getInstance]];
    
    // Setting up callback for single post retrieval
    [[TradePostMgr getInstance] setDelegateDanglingPosts:[GameManager getInstance]];
    
    // Setting up async http callback delegates
    [[AsyncHttpCallMgr getInstance] addDelegateInstance:[AsyncHttpCallMgr getInstance]];
    [[AsyncHttpCallMgr getInstance] addDelegateInstance:[GameManager getInstance]];

    // load up frontmenu background
    [[ImageManager getInstance] loadFrontMenuBackgroundNamed:@"Default.png"];
}

- (void) appShutdown
{
    [GameEventMgr destroyInstance];
    [AnimMgr destroyInstance];
    [ScanManager destroyInstance];
    [GameManager destroyInstance];
    [BeaconMgr destroyInstance];
    [FlyerMgr destroyInstance];
    [TradePostMgr destroyInstance];
    [TradeItemTypes destroyInstance];
    [Player destroyInstance];
    [ImageManager destroyInstance];
    [ResourceManager destroyInstance];
    [AsyncHttpCallMgr destroyInstance];
    [LeaderboardMgr destroyInstance];
    [PlayerSales destroyInstance];
    [UrlImageManager destroyInstance];
    [SoundManager destroyInstance];
}

- (void) setupNavigationController
{
    // create the root view controller first
    self.rootController = [[StartScreen alloc] initWithNibName:@"StartScreen" bundle:nil];
    
    // add it to our navigation controller
    self.navController = [[UINavigationController alloc] initWithRootViewController:[self rootController]];
    [self.navController setNavigationBarHidden:YES];
//    [self.window addSubview:[[self navController]view]];
    self.window.rootViewController = self.navController;
}

- (void) teardownNavigationController
{
    [self.navController.view removeFromSuperview];
    self.rootController = nil;
    self.navController = nil;
}

@end
