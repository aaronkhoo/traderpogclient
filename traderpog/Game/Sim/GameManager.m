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
#import "TradeItemTypes.h"
#import "LoadingScreen.h"
#import "UINavigationController+Pog.h"
#import "GameViewController.h"
#import "NewHomeSelectItem.h"
#import "ModalNavControl.h"
#import "HiAccuracyLocator.h"
#import "CLLocation+Pog.h"
#import "MapControl.h"
#import <CoreLocation/CoreLocation.h>

// List of Game UI screens that GameManager can kick off
#import "SignupScreen.h"

static NSString* const kGameManagerWorldFilename = @"world.sav";

@interface GameManager ()
{
    GameViewController* _gameViewController;
    HiAccuracyLocator* _playerLocator;
}
@property (nonatomic,strong) ModalNavControl* modalNav;
@property (nonatomic,strong) GameViewController* gameViewController;
@property (nonatomic,strong) HiAccuracyLocator* playerLocator;

- (void) startModalNavControlInView:(UIView*)parentView 
                     withController:(UIViewController *)viewController
                    completionBlock:(ModalNavCompletionBlock)completionBlock;
- (void) locateNewPlayer;
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
        _gameViewController = nil;
        [self registerAllNotificationHandlers];
    }
    return self;
}

#pragma mark - internal methods
- (void) startModalNavControlInView:(UIView*)parentView 
                     withController:(UIViewController *)viewController
                    completionBlock:(ModalNavCompletionBlock)completionBlock
{
    ModalNavControl* modal = [[ModalNavControl alloc] init];
    [parentView addSubview:modal.view];
    [modal.navController pushFadeInViewController:viewController animated:YES]; 
    modal.delegate = self;
    modal.completionBlock = completionBlock;
    self.modalNav = modal;
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
    [self selectNextGameUI];
}

- (void) handleNewPlayerLocationDenied:(NSNotification *)note
{
    // abort all the way back to the start screen
    _gameState = kGameStateNew;
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    UINavigationController* nav = appDelegate.navController;
    [nav popFadeOutToRootViewControllerAnimated:YES];    
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
    // Current player location has not been determined yet
    else if(![self.playerLocator bestLocation])
    {
        [self locateNewPlayer];
    }
    // Get item list from server if we don't have it already
    else if([[TradeItemTypes getInstance] needsRefresh])
    {
        [[TradeItemTypes getInstance] retrieveItemsFromServer];
    }
    // Player has no posts 
    else if(![[TradePostMgr getInstance] getHomebase])
    {
        // proceed to setup of first post
        NSLog(@"Create Homebase");
        self.gameViewController = [[GameViewController alloc] initAtCoordinate:[self.playerLocator bestLocation].coordinate];
        [nav pushFadeInViewController:self.gameViewController animated:YES];
        
        NewHomeSelectItem* itemScreen = [[NewHomeSelectItem alloc] initWithCoordinate:[self.playerLocator bestLocation].coordinate];
        [self startModalNavControlInView:self.gameViewController.view 
                          withController:itemScreen
                         completionBlock:^(BOOL finished){
                             // when the new post sequence is completed, drop an annotation for the new Homebase
                             [self.gameViewController.mapControl addAnnotationForTradePost:[[TradePostMgr getInstance] getHomebase]];
                         }];
    }
    // Player account exists + player has a post + player location has been located
    else if(![self gameViewController])
    {
        NSLog(@"start game");
    
        self.gameViewController = [[GameViewController alloc] initAtCoordinate:[self.playerLocator bestLocation].coordinate];
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
