//
//  GameManager.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AppDelegate.h"
#import "GameManager.h"
#import "Player.h"
#import "LoadingScreen.h"
#import "PogProfileAPI.h"
#import "SetupNewPlayer.h"
#import "UINavigationController+Pog.h"
#import "GameViewController.h"
#import <CoreLocation/CoreLocation.h>

static NSString* const kGameManagerWorldFilename = @"world.sav";

@interface GameManager ()
{
    SetupNewPlayer* _newPlayerSequence;
    GameViewController* _gameViewController;
    
    // HACK (should remove after Homebase implementation is added)
    CLLocationCoordinate2D _initCoord;
    // HACK
}
@end

@implementation GameManager
@synthesize gameState = _gameState;
@synthesize loadingScreen = _loadingScreen;

- (id) init
{
    self = [super init];
    if(self)
    {
        _gameState = kGameStateFrontUI;
        _loadingScreen = nil;
    }
    return self;
}

- (void) loadGame
{
    // loadGame should be responsible for reloading any data from the server it requires 
    // before the main game sequence starts. For example, any player profile stuff like
    // bucks + membership status.
}

+ (NSString*) documentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

#pragma mark - public methods
- (void) setupNewPlayerWithEmail:(NSString *)email loadingScreen:(LoadingScreen *)loadingScreen
{
    _gameState = kGameStateSetupNewPlayer;
    _loadingScreen = loadingScreen;
    _newPlayerSequence = [[SetupNewPlayer alloc] initWithEmail:email loadingScreen:loadingScreen];
}

- (void) completeSetupNewPlayer
{
    _newPlayerSequence = nil;
    UINavigationController* nav = self.loadingScreen.navigationController;
    [nav popToRootViewControllerAnimated:NO];
    
    NSLog(@"start game");
    _gameState = kGameStateGameView;
    _gameViewController = [[GameViewController alloc] initAtCoordinate:_initCoord];
    [nav pushFadeInViewController:_gameViewController animated:YES];
}

- (void) abortSetupNewPlayer
{
    _newPlayerSequence = nil;
    [self.loadingScreen.navigationController popToRootViewControllerAnimated:YES];
    
    _gameState = kGameStateFrontUI;
}

- (void) setupHomebaseAtLocation:(CLLocation *)location
{
    // TODO: create homebase
    NSLog(@"setup homebase at location (%f, %f)", location.coordinate.longitude, location.coordinate.latitude);
    _initCoord = location.coordinate;
}

#pragma mark - HttpCallbackDelegate
- (void) didCompleteHttpCallback:(NSString*)callName, BOOL success
{
    // TODO: Account for callname and success 
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    UINavigationController* nav = appDelegate.navController;
    [nav popToRootViewControllerAnimated:NO];

    NSLog(@"start game");
    _gameState = kGameStateGameView;
    CLLocationCoordinate2D location = {.latitude =  38.481057, .longitude =  -86.032563};
    _gameViewController = [[GameViewController alloc] initAtCoordinate:location];
    [nav pushFadeInViewController:_gameViewController animated:YES];
}

#pragma mark - Singleton
static GameManager* singleton = nil;
+ (GameManager*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
			singleton = [[GameManager alloc] init];
		}
	}
	return singleton;
}

+ (void) destroyInstance
{
	@synchronized(self)
	{
		singleton = nil;
	}
}


@end
