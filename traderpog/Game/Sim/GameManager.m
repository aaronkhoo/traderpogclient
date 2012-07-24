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
#import "FlyerMgr.h"
#import "Flyer.h"
#import "FlightPathOverlay.h"
#import <CoreLocation/CoreLocation.h>

// List of Game UI screens that GameManager can kick off
#import "SignupScreen.h"

static NSString* const kGameManagerWorldFilename = @"world.sav";

@interface GameManager ()
{
    BOOL _gameInfoRefreshed;
    BOOL _gameInfoRefreshSucceeded;
    NSInteger _gameInfoRefreshCount;
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
- (void) popLoadingScreenIfNecessary:(UINavigationController*)nav;
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
        _gameInfoRefreshed = FALSE;
        _gameInfoRefreshSucceeded = TRUE;
        
        // This counter is used to track how many game info refresh
        // requests are still in flight. See loadGameInfo function for
        // more details.
        _gameInfoRefreshCount = 0;
        
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

- (void) loadGameInfo
{
    // loadGame should be responsible for reloading any data from the server it requires 
    // before the main game sequence starts. 
    
    // Load player information
    if ([[Player getInstance] needsRefresh])
    {
        [[Player getInstance] getPlayerDataFromServer];
        _gameInfoRefreshCount++;
    }
    
    // Load item information
    if ([[TradeItemTypes getInstance] needsRefresh])
    {
        [[TradeItemTypes getInstance] retrieveItemsFromServer];   
        _gameInfoRefreshCount++;
    }
    
    // We got to this point and there was nothing to refresh, 
    // so just call selectNextGameUI to move on
    if (_gameInfoRefreshCount == 0)
    {
        // First indicate that gameInfo has been refreshed
        _gameInfoRefreshed = TRUE;
        [self selectNextGameUI];
    }
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

- (void) popLoadingScreenIfNecessary:(UINavigationController*)nav
{
    NSString* currentViewName = [[nav visibleViewController] nibName];
    if ([currentViewName compare:@"LoadingScreen"] == NSOrderedSame)
    {
        [nav popFadeOutViewControllerAnimated:YES];  
    }
}

- (void) applicationWillEnterForeground
{
    // Reset
    _gameInfoRefreshed = false;
    _gameInfoRefreshCount = 0;
    [self selectNextGameUI];
}

- (void) selectNextStartupStep
{
    // Get the navigation controller
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    UINavigationController* nav = appDelegate.navController;
    
    // Make sure the top viewController is the LoadingScreen, if so then
    // update the progress text
    UIViewController* current = [nav visibleViewController];
    LoadingScreen* loading = NULL;
    if ([[current nibName] compare:@"LoadingScreen"] == NSOrderedSame)
    {
        loading = (LoadingScreen*)current;
    } 
    
    // Player has no posts 
    if(![[TradePostMgr getInstance] getHomebase])
    {        
        if (loading != NULL)
        {
            loading.progressLabel.text = @"Generating initial trade post";
        } 
        
        NSArray* itemsArray = [[TradeItemTypes getInstance] getItemTypesForTier:1];
        NSInteger index = arc4random() % (itemsArray.count);
        if (![[TradePostMgr getInstance] newTradePostAtCoord:[self.playerLocator bestLocation].coordinate
                                            sellingItem:[itemsArray objectAtIndex:index]
                                             isHomebase:TRUE])
        {
            // Something failed in the trade post creation, probably because another post
            // creation was already in flight. We should never get into this state. Log and 
            // move on so we can fix this during debug.
            NSLog(@"First trade post creation failed!");
        }
    }
    // Player account exists + player has a post + player location has been located, but no flyer
    else if(![[[FlyerMgr getInstance] playerFlyers] count])
    {
        if (loading != NULL)
        {
            loading.progressLabel.text = @"Generating first flyer";
        } 
        
        // create player's first flyer
        [[FlyerMgr getInstance] newPlayerFlyerAtTradePost:[[TradePostMgr getInstance] getHomebase]];
        
        [self selectNextGameUI];
    }
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
    else if (!_gameInfoRefreshed)
    {
        // show loading screen and load game info from server
        _gameInfoRefreshSucceeded = TRUE;
        
        // first check the view on the stack, if the top view is not LoadingScreen,
        // then push that onto the stack
        UIViewController* current = [nav visibleViewController];
        if ([[current nibName] compare:@"LoadingScreen"] != NSOrderedSame)
        {
            current = [[LoadingScreen alloc] initWithNibName:@"LoadingScreen" bundle:nil];
            [nav pushFadeInViewController:current animated:YES];
        }
        LoadingScreen* loading = (LoadingScreen*)current;
        loading.progressLabel.text = @"Loading game info";
        [self loadGameInfo];
    }
    else if(![self.playerLocator bestLocation])
    {
        // first check the view on the stack, if the top view is not LoadingScreen,
        // then push that onto the stack
        UIViewController* current = [nav visibleViewController];
        if ([[current nibName] compare:@"LoadingScreen"] != NSOrderedSame)
        {
            current = [[LoadingScreen alloc] initWithNibName:@"LoadingScreen" bundle:nil];
            [nav pushFadeInViewController:current animated:YES];
        }
        LoadingScreen* loading = (LoadingScreen*)current;
        loading.progressLabel.text = @"Determining player location";     
        [self locateNewPlayer];
    }
    // Still within startup sequence (either missing first trade post or first flyer)
    else if(![[TradePostMgr getInstance] getHomebase] ||
            ![[[FlyerMgr getInstance] playerFlyers] count])
    {        
        // first check the view on the stack, if the top view is not LoadingScreen,
        // then push that onto the stack
        UIViewController* current = [nav visibleViewController];
        if ([[current nibName] compare:@"LoadingScreen"] != NSOrderedSame)
        {
            current = [[LoadingScreen alloc] initWithNibName:@"LoadingScreen" bundle:nil];
            [nav pushFadeInViewController:current animated:YES];
        }
        
        [self selectNextStartupStep];
    }
    else if(![self gameViewController])
    {
        [self popLoadingScreenIfNecessary:nav];
        
        NSLog(@"start game");
    
        self.gameViewController = [[GameViewController alloc] initAtCoordinate:[self.playerLocator bestLocation].coordinate];
        [nav pushFadeInViewController:self.gameViewController animated:YES];
        
        [self selectNextGameUI];
    }
    else
    {
        // TODO: Validate this is correct behavior
        // Right now, pop any loading screens if they are on the stack when 
        // we come in here. 
        [self popLoadingScreenIfNecessary:nav];
        
        // handle in-game states
        switch(_gameState)
        {
            case kGameStateNew:
                _gameState = kGameStateGameLoop;
                NSLog(@"start gameloop");
                
                // display the posts in the area
                [self.gameViewController.mapControl refreshMap:[self.playerLocator bestLocation].coordinate];
                [self.gameViewController showKnobAnimated:YES delay:0.5f];
                
                break;
                
            default:
                // do nothing
                break;
        }
    }
}

- (void) flyer:(Flyer *)flyer departForTradePost:(TradePost *)tradePost
{
    if([flyer curPostId] != [tradePost postId])
    {
        // remove old rendering
        [self.gameViewController.mapControl dismissFlightPathForFlyer:flyer];
        [self.gameViewController.mapControl dismissAnnotationForFlyer:flyer];
        
        [flyer departForPostId:[tradePost postId]];
        
        // add rendering
        [self.gameViewController.mapControl showFlightPathForFlyer:flyer];
        [self.gameViewController.mapControl addAnnotationForFlyer:flyer];
    }
}

#pragma mark - HttpCallbackDelegate
- (void) didCompleteHttpCallback:(NSString*)callName, BOOL success
{
    // Game is presently in gameinfo refresh mode. Only call selectNextGameUI 
    // if the refresh is complete. 
    if (_gameInfoRefreshCount > 0)
    {
        if ([callName compare:kTradeItemTypes_ReceiveItems] == NSOrderedSame ||
            [callName compare:kPlayer_GetPlayerData] == NSOrderedSame)
        {
            _gameInfoRefreshCount--;
            _gameInfoRefreshSucceeded = _gameInfoRefreshSucceeded && success;
            if (_gameInfoRefreshCount == 0)
            {
                // If one of the refreshes failed, then treat the entire refresh process as failed.
                _gameInfoRefreshed = _gameInfoRefreshSucceeded;
                // Recall selectNextGameUI
                [self selectNextGameUI];
            }
        }
    }
    else 
    {
        [self selectNextGameUI];
    }
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
