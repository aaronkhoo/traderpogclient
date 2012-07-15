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
#import "TradePostMgr.h"
#import "TradePost.h"
#import "LoadingScreen.h"
#import "PogProfileAPI.h"
#import "SetupNewPlayer.h"
#import "UINavigationController+Pog.h"
#import "GameViewController.h"
#import "NewHomeSelectItem.h"
#import "ModalNavControl.h"
#import "HiAccuracyLocator.h"
#import <CoreLocation/CoreLocation.h>

// List of Game UI screens that GameManager can kick off
#import "SignupScreen.h"

static NSString* const kGameManagerWorldFilename = @"world.sav";

@interface GameManager ()
{
    SetupNewPlayer* _newPlayerSequence;
    GameViewController* _gameViewController;
    HiAccuracyLocator* _playerLocator;
    CLLocation* _newPlayerLocation;
    
    // HACK (should remove after Homebase implementation is added)
    CLLocationCoordinate2D _initCoord;
    // HACK
}
@property (nonatomic,strong) ModalNavControl* modalNav;
@property (nonatomic,strong) GameViewController* gameViewController;
@property (nonatomic,strong) HiAccuracyLocator* playerLocator;

- (void) startModalNavControlInView:(UIView*)parentView withController:(UIViewController *)viewController;
- (void) finishModalNavControl;
- (void) locateNewPlayer;
- (void) finishLocateNewPlayer;
- (void) registerAllNotificationHandlers;
@end

@implementation GameManager
@synthesize gameState = _gameState;
@synthesize loadingScreen = _loadingScreen;
@synthesize modalNav;
@synthesize gameViewController = _gameViewController;
@synthesize playerLocator = _playerLocator;

- (id) init
{
    self = [super init];
    if(self)
    {
        _gameState = kGameStateNew;
        _loadingScreen = nil;
        _newPlayerLocation = nil;
        _gameViewController = nil;
        [self registerAllNotificationHandlers];
    }
    return self;
}

#pragma mark - internal methods
- (void) startModalNavControlInView:(UIView*)parentView withController:(UIViewController *)viewController
{
    ModalNavControl* modal = [[ModalNavControl alloc] init];
    [parentView addSubview:modal.view];
    [modal.navController pushFadeInViewController:viewController animated:YES]; 
    modal.delegate = self;
    self.modalNav = modal;
}

- (void) finishModalNavControl
{
    if([self modalNav])
    {
        [self.modalNav.view removeFromSuperview];
        self.modalNav = nil;
    }
}


- (void) loadGame
{
    // loadGame should be responsible for reloading any data from the server it requires 
    // before the main game sequence starts. For example, any player profile stuff like
    // bucks + membership status.
}

- (void) locateNewPlayer
{
    _playerLocator = [[HiAccuracyLocator alloc] init];
    [self.playerLocator startUpdatingLocation];
}

- (void) finishLocateNewPlayer
{
    _newPlayerLocation = [self.playerLocator bestLocation];
}

- (void) registerAllNotificationHandlers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNewPlayerLocated:)
                                                 name:kUserLocated
                                               object:[self playerLocator]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNewPlayerLocationDenied:)
                                                 name:kUserLocationDenied
                                               object:[self playerLocator]];    
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
//    _gameState = kGameStateSetupNewPlayer;
//    _loadingScreen = loadingScreen;
//    _newPlayerSequence = [[SetupNewPlayer alloc] initWithEmail:email loadingScreen:loadingScreen];
}

- (void) completeSetupNewPlayer
{
//    _newPlayerSequence = nil;
//    UINavigationController* nav = self.loadingScreen.navigationController;
//    [nav popToRootViewControllerAnimated:NO];
    
//    NSLog(@"start game");
//    _gameState = kGameStateGameView;
//    _gameViewController = [[GameViewController alloc] initAtCoordinate:_initCoord];
//    [nav pushFadeInViewController:_gameViewController animated:YES];
    
//    NewHomeSelectItem* itemScreen = [[NewHomeSelectItem alloc] initWithNibName:@"NewHomeSelectItem" bundle:nil];
//    [self startModalNavControlInView:_gameViewController.view withController:itemScreen];
}

- (void) abortSetupNewPlayer
{
//    _newPlayerSequence = nil;
//    [self.loadingScreen.navigationController popToRootViewControllerAnimated:YES];    
}

- (void) setupHomebaseAtLocation:(CLLocation *)location
{
    // TODO: create homebase
    NSLog(@"setup homebase at location (%f, %f)", location.coordinate.longitude, location.coordinate.latitude);
    _initCoord = location.coordinate;
}

#pragma mark - ModalNavDelegate
- (void) dismissModal
{
    if([self modalNav])
    {
        [self.modalNav.view removeFromSuperview];
        self.modalNav = nil;
    }
}

#pragma mark - location notifications
- (void) handleNewPlayerLocated:(NSNotification *)note
{
    [self finishLocateNewPlayer];

    [self selectNextGameUI];
}

- (void) handleNewPlayerLocationDenied:(NSNotification *)note
{
    // abort all the way back to the start screen
    _gameState = kGameStateNew;
    [self.loadingScreen.navigationController popToRootViewControllerAnimated:YES];    
}

- (void) selectNextGameUI
{
    // Get the navigation controller
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    UINavigationController* nav = appDelegate.navController;
    
    // No player has been created
    if ([Player getInstance].id == 0) {
        
        // proceed to SignupScreen
        UIViewController* controller = [[SignupScreen alloc] initWithNibName:@"SignupScreen" bundle:nil];
        [nav pushFadeInViewController:controller animated:YES];
    }
    else if(!_newPlayerLocation)
    {
        [self locateNewPlayer];
    }
    /* TODO: Account for callname and success 
    else if (??Evaluate that first post is not ready yet) {
    }
    */
    else if(![[TradePostMgr getInstance] getHomebase])
    {
        // proceed to setup of first post
        NSLog(@"Create Homebase");
        self.gameViewController = [[GameViewController alloc] initAtCoordinate:_newPlayerLocation.coordinate];
        AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        UINavigationController* nav = appDelegate.navController;
        [nav pushFadeInViewController:self.gameViewController animated:YES];
        
        NewHomeSelectItem* itemScreen = [[NewHomeSelectItem alloc] initWithCoordinate:_newPlayerLocation.coordinate];
        [self startModalNavControlInView:self.gameViewController.view withController:itemScreen];
    }
    else if(![self gameViewController])
    {
        NSLog(@"start game");
        // TODO: Use real Player position
        CLLocationCoordinate2D location = {.latitude =  38.481057, .longitude =  -86.032563};
        self.gameViewController = [[GameViewController alloc] initAtCoordinate:location];
        [nav pushFadeInViewController:self.gameViewController animated:YES];
    }
    else
    {
        // handle in-game states
        switch(_gameState)
        {
            case kGameStateNew:
                _gameState = kGameStateGameLoop;
                NSLog(@"start gameloop");
                break;
                
            default:
                // do nothing
                break;
        }
    }
}

#pragma mark - HttpCallbackDelegate
- (void) didCompleteHttpCallback:(NSString*)callName, BOOL success
{
    [self selectNextGameUI];
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
