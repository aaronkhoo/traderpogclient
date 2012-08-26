//
//  GameManager.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AppDelegate.h"
#import "BeaconMgr.h"
#import "GameManager.h"
#import "Player.h"
#import "TradePostMgr.h"
#import "TradePost.h"
#import "TradeItemTypes.h"
#import "TradeManager.h"
#import "LoadingScreen.h"
#import "UINavigationController+Pog.h"
#import "NewHomeSelectItem.h"
#import "ModalNavControl.h"
#import "HiAccuracyLocator.h"
#import "CLLocation+Pog.h"
#import "MapControl.h"
#import "FlyerMgr.h"
#import "Flyer.h"
#import "FlyerTypes.h"
#import "FlightPathOverlay.h"
#import "ResourceManager.h"
#import "GameNotes.h"
#import "WorldState.h"
#import <CoreLocation/CoreLocation.h>

// List of Game UI screens that GameManager can kick off
#import "SignupScreen.h"

@interface GameManager ()
{
    // Variables to track general game information
    BOOL _gameInfoRefreshed;
    BOOL _gameInfoRefreshSucceeded;
    NSInteger _gameInfoRefreshCount;
    
    // Variables to track player specific information
    BOOL _playerInfoRefreshed;
    BOOL _playerInfoRefreshSucceeded;
    NSInteger _playerInfoRefreshCount;
    
    GameViewController* _gameViewController;
    HiAccuracyLocator* _playerLocator;
    
    // local world state
    WorldState* _localWorldState;
    
    // in-game UI context
    Flyer* _contextFlyer;
    NSTimeInterval  _calloutHaltDuration;
    NSDate*         _calloutHaltBegin;
}
@property (nonatomic,strong) ModalNavControl* modalNav;
@property (nonatomic,strong) HiAccuracyLocator* playerLocator;
@property (nonatomic,strong) WorldState* localWorldState;

- (void) loadGameInfo;
- (void) loadPlayerInfo;
- (void) loadLocalWorldState;
- (void) saveLocalWorldState;

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
@synthesize localWorldState = _localWorldState;

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
        
        _playerInfoRefreshed = FALSE;
        _playerInfoRefreshSucceeded = TRUE;
        // This counter is used to track how many player info refresh
        // requests are still in flight. See loadPlayerInfo function for
        // more details.
        _playerInfoRefreshCount = 0;
        
        // in-game UI context
        _contextFlyer = nil;
        _calloutHaltBegin = nil;
        _calloutHaltDuration = 0.0;
        
        [self registerAllNotificationHandlers];
        
        // load up local world state
        [self loadLocalWorldState];
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
    
    [[ResourceManager getInstance] downloadResourceFileIfNecessary];
    _gameInfoRefreshCount++;
    
    // Load item information
    if ([[TradeItemTypes getInstance] needsRefresh])
    {
        [[TradeItemTypes getInstance] retrieveItemsFromServer];   
        _gameInfoRefreshCount++;
    }
    
    // Load flyers information
    if ([[FlyerTypes getInstance] needsRefresh])
    {
        [[FlyerTypes getInstance] retrieveFlyersFromServer];   
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


- (void) loadPlayerInfo
{
    // loadPlayerInfo should be responsible for reloading any data from the server it requires
    // that is specific to the player before the main game sequence starts.
    
    // Load player information
    if ([[Player getInstance] needsRefresh])
    {
        [[Player getInstance] getPlayerDataFromServer];
        _playerInfoRefreshCount++;
    }
    
    // Load posts information
    if ([[TradePostMgr getInstance] needsRefresh])
    {
        [[TradePostMgr getInstance] retrievePostsFromServer];
        _playerInfoRefreshCount++;
    }
    
    // Load flyers associated with the current user
    if ([[FlyerMgr getInstance] needsRefresh])
    {
        [[FlyerMgr getInstance] retrieveUserFlyersFromServer];
        _playerInfoRefreshCount++;
    }
    
    // Load beacons
    if ([[BeaconMgr getInstance] needsRefresh])
    {
        [[BeaconMgr getInstance] retrieveBeaconsFromServer];
        _playerInfoRefreshCount++;
    }
    
    // Refresh friends data from Facebook if necessary
    if ([[Player getInstance] facebookSessionValid] && [[Player getInstance] needsFriendsRefresh])
    {
        [[Player getInstance] getFacebookFriendsList];
        _playerInfoRefreshCount++;
    }
    
    // We got to this point and there was nothing to refresh,
    // so just call selectNextGameUI to move on
    if (_playerInfoRefreshCount == 0)
    {
        // First indicate that gameInfo has been refreshed
        _playerInfoRefreshed = TRUE;
        [self selectNextGameUI];
    }
}

- (void) loadLocalWorldState
{
    self.localWorldState = nil;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* filepath = [WorldState filepath];
    if ([fileManager fileExistsAtPath:filepath])
    {
        NSData* readData = [NSData dataWithContentsOfFile:filepath];
        if(readData)
        {
            self.localWorldState = [NSKeyedUnarchiver unarchiveObjectWithData:readData];
        }
    }
}

- (void) saveLocalWorldState
{
    if(![self localWorldState])
    {
        // create new local cache if non exists
        self.localWorldState = [[WorldState alloc] init];
    }
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[self localWorldState]];
    NSError* error = nil;
    BOOL writeSuccess = [data writeToFile:[WorldState filepath]
                                  options:NSDataWritingAtomic
                                    error:&error];
    if(writeSuccess)
    {
        NSLog(@"localWorldState file saved successfully");
    }
    else
    {
        NSLog(@"localWorldState file save failed: %@", error);
    }
}

- (void) removeLocalWorldStateData
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* filepath = [WorldState filepath];
    NSError *error = nil;
    if ([fileManager fileExistsAtPath:filepath])
    {
        [fileManager removeItemAtPath:filepath error:&error];
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
    // Store up the last known player location
    Player* current = [Player getInstance];
    current.lastKnownLocation = [self playerLocator].bestLocation.coordinate;
    current.lastKnownLocationValid = TRUE;
    
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
    _playerInfoRefreshed = false;
    _playerInfoRefreshCount = 0;
    [self selectNextGameUI];
}

- (void) applicationDidEnterBackground
{
    [self saveLocalWorldState];
}

- (void) clearCache
{
    [self removeLocalWorldStateData];
    [[Player getInstance] removePlayerData];
}

- (void) selectNextGameUI
{
    // Get the navigation controller
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    UINavigationController* nav = appDelegate.navController;
    
    // No player has been created
    if ([Player getInstance].playerId == 0) {
        
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
    else if (!_playerInfoRefreshed)
    {
        // show loading screen and load player info from server
        _playerInfoRefreshSucceeded = TRUE;
        
        // first check the view on the stack, if the top view is not LoadingScreen,
        // then push that onto the stack
        UIViewController* current = [nav visibleViewController];
        if ([[current nibName] compare:@"LoadingScreen"] != NSOrderedSame)
        {
            current = [[LoadingScreen alloc] initWithNibName:@"LoadingScreen" bundle:nil];
            [nav pushFadeInViewController:current animated:YES];
        }
        LoadingScreen* loading = (LoadingScreen*)current;
        loading.progressLabel.text = @"Loading player info";
        [self loadPlayerInfo];
    }
    else if(![[Player getInstance] lastKnownLocationValid])
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
    // Player has no posts 
    else if([[TradePostMgr getInstance] postsCount] == 0)
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
        loading.progressLabel.text = @"Generating initial trade post"; 
        
        NSArray* itemsArray = [[TradeItemTypes getInstance] getItemTypesForTier:1];
        NSInteger index = arc4random() % (itemsArray.count);
        if (![[TradePostMgr getInstance] newTradePostAtCoord:[[Player getInstance] lastKnownLocation]
                                                 sellingItem:[itemsArray objectAtIndex:index]])
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
        // first check the view on the stack, if the top view is not LoadingScreen,
        // then push that onto the stack
        UIViewController* current = [nav visibleViewController];
        if ([[current nibName] compare:@"LoadingScreen"] != NSOrderedSame)
        {
            current = [[LoadingScreen alloc] initWithNibName:@"LoadingScreen" bundle:nil];
            [nav pushFadeInViewController:current animated:YES];
        }
        LoadingScreen* loading = (LoadingScreen*)current;
        loading.progressLabel.text = @"Generating first flyer";
        
        // create player's first flyer
        NSArray* flyersArray = [[FlyerTypes getInstance] getFlyersForTier:1];
        NSInteger index = arc4random() % (flyersArray.count);
        if (![[FlyerMgr getInstance] newPlayerFlyerAtTradePost:[[TradePostMgr getInstance] getFirstTradePost]                                    firstFlyer:index])
        {
            // Something failed in the flyer creation, probably because another flyer
            // creation was already in flight. We should never get into this state. Log and
            // move on so we can fix this during debug.
            NSLog(@"First flyer creation failed!");
        }
    }
    else
    {        
        // Right now, pop any loading screens if they are on the stack when 
        // we come in here. 
        [self popLoadingScreenIfNecessary:nav];
        
        if (![self gameViewController])
        {
            _gameViewController = [[GameViewController alloc] initAtCoordinate:[[Player getInstance] lastKnownLocation]];
            
            // push the gameViewController onto the stack
            [nav pushFadeInViewController:self.gameViewController animated:YES];
        }
        
        // handle in-game states
        switch(_gameState)
        {
            case kGameStateNew:
                _gameState = kGameStateGameLoop;
                
                // Save the player state
                [[Player getInstance] savePlayerData];
                
                // refresh game data from local cache
                if([self localWorldState])
                {
                    [[FlyerMgr getInstance] refreshFromWorldState:[self localWorldState]];
                }
                
                NSLog(@"start gameloop");
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
        if ([flyer departForPostId:[tradePost postId]])
        {
            TradePost* curPost = [[TradePostMgr getInstance] getTradePostWithId:[flyer curPostId]];
            curPost.hasFlyer = NO;
            
            // Flyer path was successfully created. Delete the old path from the view.
            [self.gameViewController.mapControl dismissFlightPathForFlyer:flyer];
        }
    }
}


#pragma mark - in-game UI flow
- (void) showHomeSelectForFlyer:(Flyer *)flyer
{
    if(kGameStateGameLoop == _gameState)
    {
        _gameState = kGameStateHomeSelect;
        _contextFlyer = flyer;
        [self.gameViewController showPostWheelAnimated:YES];
    }
}

- (void) wheel:(WheelControl *)wheel commitOnTradePost:(TradePost *)tradePost
{
    if(kGameStateHomeSelect == _gameState)
    {
        // Home Select
        // send the flyer to committed post
        NSAssert(_contextFlyer, @"HomeSelect needs a current flyer");
        [self flyer:_contextFlyer departForTradePost:tradePost];
        _contextFlyer = nil;
        _gameState = kGameStateGameLoop;
    }
    else
    {
        // otherwise, center map on committed post
        [self.gameViewController.mapControl defaultZoomCenterOn:[tradePost coord] animated:YES];
    }
}

// call this when any in-game modal needs to cancel to pop the game-manager
// state back to idle
- (void) popGameStateToLoop
{
    if((kGameStateInGameFirst <= _gameState) &&
       (kGameStateInGameLast > _gameState))
    {
        _gameState = kGameStateGameLoop;
    }
}

#pragma mark - global UI controls
- (void) haltMapAnnotationCalloutsForDuration:(NSTimeInterval)seconds
{
    if(0.0 < seconds)
    {
        _calloutHaltBegin = [NSDate date];
        _calloutHaltDuration = seconds;
    }
}

- (BOOL) canShowMapAnnotationCallout
{
    BOOL result = YES;
    if(_calloutHaltBegin)
    {
        NSTimeInterval elapsed = -[_calloutHaltBegin timeIntervalSinceNow];
        if(elapsed < _calloutHaltDuration)
        {
            result = NO;
        }
        else
        {
            _calloutHaltBegin = nil;
            _calloutHaltDuration = 0.0;
        }
    }
    return result;
}

#pragma mark - HttpCallbackDelegate
- (void) didCompleteHttpCallback:(NSString*)callName, BOOL success
{
    // Game is presently in gameinfo refresh mode. Only call selectNextGameUI 
    // if the refresh is complete. 
    if (_gameInfoRefreshCount > 0)
    {
        if ([callName compare:kTradeItemTypes_ReceiveItems] == NSOrderedSame ||
            [callName compare:kFlyerTypes_ReceiveFlyers] == NSOrderedSame ||
            [callName compare:kResourceManager_PackageReady] == NSOrderedSame)
        {
            _gameInfoRefreshCount--;
            _gameInfoRefreshSucceeded = _gameInfoRefreshSucceeded && success;
            if (_gameInfoRefreshCount == 0)
            {
                // If one of the refreshes failed, then treat the entire refresh process as failed.
                _gameInfoRefreshed = _gameInfoRefreshSucceeded;
                
                if (_gameInfoRefreshed)
                {
                    // Game info refresh succeeded. Go ahead and continue the process
                    // of starting up.
                    [self selectNextGameUI];
                }
                else
                {
                    // Something failed in the game refresh process. Stop for now.
                    // Pop the loading screen.
                    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
                    UINavigationController* nav = appDelegate.navController;
                    [self popLoadingScreenIfNecessary:nav];
                }
            }
        }
    }
    // Game is presently in player info refresh mode. Only call selectNextGameUI
    // if the refresh is complete.
    else if (_playerInfoRefreshCount > 0)
    {
        if ([callName compare:kPlayer_GetPlayerData] == NSOrderedSame ||
            [callName compare:kTradePostMgr_ReceivePosts] == NSOrderedSame ||
            [callName compare:kFlyerMgr_ReceiveFlyers] == NSOrderedSame ||
            [callName compare:kPlayer_SavePlayerData] == NSOrderedSame ||
            [callName compare:kBeaconMgr_ReceiveBeacons] == NSOrderedSame)
        {
            _playerInfoRefreshCount--;
            _playerInfoRefreshSucceeded = _playerInfoRefreshSucceeded && success;
            if (_playerInfoRefreshCount == 0)
            {
                // If one of the refreshes failed, then treat the entire refresh process as failed.
                _playerInfoRefreshed = _playerInfoRefreshSucceeded;
                
                if (_playerInfoRefreshed)
                {
                    // Player info refresh succeeded. Go ahead and continue the process
                    // of starting up.
                    [self selectNextGameUI];
                }
                else
                {
                    // Something failed in the player refresh process. Stop for now.
                    // Pop the loading screen.
                    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
                    UINavigationController* nav = appDelegate.navController;
                    [self popLoadingScreenIfNecessary:nav];
                }
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
