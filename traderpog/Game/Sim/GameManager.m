//
//  GameManager.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AFClientManager.h"
#import "AppDelegate.h"
#import "AsyncHttpCallMgr.h"
#import "BeaconMgr.h"
#import "GameManager.h"
#import "Player.h"
#import "PogUIUtility.h"
#import "Reachability.h"
#import "TradePostMgr.h"
#import "TradePost.h"
#import "TradeItemTypes.h"
#import "TradeManager.h"
#import "LoadingScreen.h"
#import "LoadingTransition.h"
#import "UINavigationController+Pog.h"
#import "HiAccuracyLocator.h"
#import "CLLocation+Pog.h"
#import "MapControl.h"
#import "FlyerMgr.h"
#import "Flyer.h"
#import "FlyerTypes.h"
#import "FlightPathOverlay.h"
#import "ResourceManager.h"
#import "GameNotes.h"
#import "PlayerSales.h"
#import "PlayerSalesScreen.h"
#import "SoundManager.h"
#import "ScanManager.h"
#import "ObjectivesMgr.h"
#import "MBProgressHUD.h"
#import <CoreLocation/CoreLocation.h>

// List of Game UI screens that GameManager can kick off
#import "SignupScreen.h"

// how often to reinitialize game since last server operations
static double const timeTillReinitialize = -(60 * 30);

// How often to check if the gameinfo has been updated (2 hours)
static double const gameinfoRefreshTime = -(60 * 60 * 2);
static NSString* const kKeyLastUpdated = @"lastupdated";


typedef enum {
    serverCallType_none = 0,
    
    // Global game info, should come before player specific info
    serverCallType_resourceManager,
    serverCallType_flyerTypes,
    serverCallType_tradeItemTypes,
    
    // Player specific info
    serverCallType_player,
    serverCallType_tradePostMgr,
    serverCallType_beaconMgr,
    serverCallType_flyerMgr,
    serverCallType_playerSales,
    
    // Any new server calls should go above this
    serverCallType_end
} serverCallType;

@interface GameManager ()
{
    // Game state variables
    serverCallType _currentServerCall;
    BOOL _gameStateRefreshedFromServer;
    BOOL _gameInfoRefreshSucceeded;
    BOOL _danglingPostsResolved;
    
    // Last time we went through game state initialization
    NSDate* _lastGameStateInitializeTime;
    
    // Variables to track any outstanding async http calls that need to be completed
    BOOL _asyncHttpCallsCompleted;
    
    // server reachability
    Reachability* _traderpogServerReachability;
    
    // Variables to track general game information
    NSDate* _gameInfoModifiedDateLastChecked;
    NSDate* _gameInfoModifiedDate;
    
    GameViewController* _gameViewController;
    HiAccuracyLocator* _playerLocator;
    
    // in-game UI context
    Flyer* _contextFlyer;
    TradePost* _contextPost;
    NSTimeInterval  _calloutHaltDuration;
    NSDate*         _calloutHaltBegin;
    BrowseEnforcedType _browseEnforced;
    pthread_rwlock_t _browseEnforcedLock;

}
@property (nonatomic,strong) HiAccuracyLocator* playerLocator;

- (void) getGameInfoModifiedDate;
- (void) startGame;

- (void) locateNewPlayer;
- (void) registerAllNotificationHandlers;
- (void) popLoadingScreenToRootIfNecessary:(UINavigationController*)nav;
- (void) handleTradePogReachabilityChanged:(NSNotification*)note;
@end

@implementation GameManager
@synthesize gameState = _gameState;
@synthesize loadingScreen = _loadingScreen;
@synthesize gameViewController = _gameViewController;
@synthesize playerLocator = _playerLocator;

#pragma mark - initialization
- (id) init
{
    self = [super init];
    if(self)
    {
        // Refreshing data from server
        _currentServerCall = serverCallType_none;
        _gameStateRefreshedFromServer = FALSE;
        _lastGameStateInitializeTime = nil;
        _gameInfoRefreshSucceeded = TRUE;
        
        // Resolving any dangling posts (as a result of previous flights to foreign posts)
        _danglingPostsResolved = FALSE;
        
        _gameState = kGameStateNew;
        _loadingScreen = nil;
        _gameViewController = nil;
        _playerLocator = nil;
        _asyncHttpCallsCompleted = FALSE;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTradePogReachabilityChanged:) name:kReachabilityChangedNotification object:nil];
        _traderpogServerReachability = [Reachability reachabilityWithHostname: [[AFClientManager sharedInstance] getTraderPogURL]];
        [_traderpogServerReachability startNotifier];
        
        _gameInfoModifiedDateLastChecked = nil;
        _gameInfoModifiedDate = nil;
        
        // in-game UI context
        _contextFlyer = nil;
        _contextPost = nil;
        _calloutHaltBegin = nil;
        _calloutHaltDuration = 0.0;
        _browseEnforced = kBrowseEnforcedNone;
        pthread_rwlock_init(&_browseEnforcedLock, NULL);
        
        [self registerAllNotificationHandlers];
    }
    return self;
}

- (void) dealloc
{
    pthread_rwlock_destroy(&_browseEnforcedLock);
}

- (void) resetData
{
    _currentServerCall = serverCallType_none;
    _gameStateRefreshedFromServer = FALSE;
    _asyncHttpCallsCompleted = TRUE;
    _danglingPostsResolved = FALSE;
}

- (void) quitGame
{
    if([self gameViewController])
    {
        _gameState = kGameStateNew;
        
        // clear game systems
        [[ScanManager getInstance] clearForQuitGame];
        [[FlyerMgr getInstance] clearForQuitGame];
        [[TradePostMgr getInstance] clearForQuitGame];
        [[BeaconMgr getInstance] clearForQuitGame];
        [[ObjectivesMgr getInstance] clearForQuitGame];
        
        // teardown GameViewController
        [self.gameViewController teardown];
        UINavigationController* nav = [[self gameViewController] navigationController];
        self.gameViewController = nil;
        [nav popToRootViewControllerAnimated:NO];
    }
    else
    {
        AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        UINavigationController* nav = appDelegate.navController;
        [nav popFadeOutToRootViewControllerAnimated:NO];
    }
}

#pragma mark - internal methods

- (void) startGame
{
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    UINavigationController* nav = appDelegate.navController;
    
    if (![self gameViewController])
    {
        _gameViewController = [[GameViewController alloc] initAtCoordinate:[[Player getInstance] lastKnownLocation]];
        
        // push the gameViewController onto the stack
        [nav pushFadeInViewController:self.gameViewController animated:YES];
    }
    
    _lastGameStateInitializeTime = [[NSDate alloc] init];
    
    // handle in-game states
    switch(_gameState)
    {
        case kGameStateNew:
            // Set game state to loop and set initialize time to now
            _gameState = kGameStateGameLoop;
            
            // Save the player state
            [[Player getInstance] savePlayerData];
            
            // reset all recurring objectives (things like the occassional set beacon tip)
            [[ObjectivesMgr getInstance] resetRecurringObjectives];
            
            NSLog(@"start gameloop");
            [self.gameViewController showKnobAnimated:YES delay:0.5f];
            
            [[Player getInstance] resetBucksIfNecessary];
            break;
            
        default:
            // do nothing
            break;
    }
}

- (void) getGameInfoModifiedDate
{
    // make a get request
    NSLog(@"Calling getGameInfoModifiedDate");
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    NSString* path = @"gameinfo.json";
    [httpClient getPath:path
             parameters:nil
                success:^(AFHTTPRequestOperation *operation, id responseObject){
                    NSLog(@"getGameInfoModifiedDate call succeeded");
                    BOOL successfullyRetrievedModifiedDate = FALSE;
                    
                    // Convert the utc date from string to NSDate instance
                    id obj = [responseObject valueForKeyPath:kKeyLastUpdated];
                    if ((NSNull *)obj != [NSNull null])
                    {
                        NSString* utcdate = [NSString stringWithFormat:@"%@", obj];
                        if (![utcdate isEqualToString:@"<null>"])
                        {
                            _gameInfoModifiedDate = [PogUIUtility convertUtcToNSDate:utcdate];
                            successfullyRetrievedModifiedDate = TRUE;
                        }
                    }
                    if (!successfullyRetrievedModifiedDate)
                    {
                        // Something failed during the retrieval of the last modified date.
                        // Set the date to be in the distant future to force retrieval
                        // of the gameinfo.
                        NSLog(@"Error parsing gameinfo last modified date");
                        _gameInfoModifiedDate = [NSDate distantFuture];
                    }
                    _gameInfoRefreshSucceeded = TRUE;
                    
                    // Set the time we checked whether the gameinfo has been modified to the
                    // current datetime
                    _gameInfoModifiedDateLastChecked = [[NSDate alloc] init];
                    
                    [self selectNextGameUI];
                }
                failure:^(AFHTTPRequestOperation* operation, NSError* error){
                    NSLog(@"Error requesting gameinfo last modified date");
                    _gameInfoModifiedDate = [NSDate distantFuture];
                    _gameInfoModifiedDateLastChecked = [[NSDate alloc] init];
                    [self selectNextGameUI];
                }
     ];
}

- (BOOL) makeServerCall
{
    // Get the navigation controller
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    UINavigationController* nav = appDelegate.navController;
    
    BOOL noCall = TRUE;
    switch (_currentServerCall) {
        case serverCallType_resourceManager:
            [self pushLoadingScreenIfNecessary:nav message:@"Hiring Pogs..."];
            [[ResourceManager getInstance] downloadResourceFileIfNecessary];
            noCall = FALSE;
            break;
            
        case serverCallType_tradeItemTypes:
            // Load trade item information
            [self pushLoadingScreenIfNecessary:nav message:@"Manufacturing items for trade..."];
            if ([[TradeItemTypes getInstance] needsRefresh:_gameInfoModifiedDate])
            {
                [[TradeItemTypes getInstance] retrieveItemsFromServer];
                noCall = FALSE;
            }
            break;
            
        case serverCallType_flyerTypes:
            // Load flyers information
            [self pushLoadingScreenIfNecessary:nav message:@"Building flyers..."];
            if ([[FlyerTypes getInstance] needsRefresh:_gameInfoModifiedDate])
            {
                [[FlyerTypes getInstance] retrieveFlyersFromServer];
                noCall = FALSE;
            }
            break;
            
        case serverCallType_player:
                        // Load player information
            [self pushLoadingScreenIfNecessary:nav message:@"Raising capital...."];
            if ([[Player getInstance] needsRefresh])
            {
                [[Player getInstance] getPlayerDataFromServer];
                noCall = FALSE;
            }
            break;
            
        case serverCallType_tradePostMgr:
            // Load posts information
            [self pushLoadingScreenIfNecessary:nav message:@"Searching for trade routes..."];
            if ([[TradePostMgr getInstance] needsRefresh])
            {
                [[TradePostMgr getInstance] retrievePostsFromServer];
                noCall = FALSE;
            }
            break;
            
        case serverCallType_beaconMgr:
                        // Load beacons
            [self pushLoadingScreenIfNecessary:nav message:@"Contacting trading partners..."];
            if ([[BeaconMgr getInstance] needsRefresh])
            {
                [[BeaconMgr getInstance] retrieveBeaconsFromServer];
                noCall = FALSE;
            }
            break;
            
        case serverCallType_flyerMgr:
            // Load flyers associated with the current user
            [self pushLoadingScreenIfNecessary:nav message:@"Signing contracts..."];
            if ([[FlyerMgr getInstance] needsRefresh])
            {
                [[FlyerMgr getInstance] retrieveUserFlyersFromServer];
                noCall = FALSE;
            }
            break;
            
        case serverCallType_playerSales:
            // Grab any player sales information
            [self pushLoadingScreenIfNecessary:nav message:@"Cornering markets..."];
            if ([[PlayerSales getInstance] needsRefresh])
            {
                [[PlayerSales getInstance] retrieveSalesFromServer];
                noCall = FALSE;
            }
            break;
            
        default:
            break;
    }
    // reverse the noCall value, i.e. return TRUE if a call was made, and FALSE otherwise
    return !noCall;
}

- (void) refreshServerData
{
    // Try to refresh data from server
    while (_currentServerCall != serverCallType_end && ![self makeServerCall]) {
        _currentServerCall++;
    }
    if (_currentServerCall == serverCallType_end)
    {
        NSLog(@"Done with game state refresh from the server.");
        _gameStateRefreshedFromServer = TRUE;
        [self selectNextGameUI];
    }
}

- (void) locateNewPlayer
{
    if(!_playerLocator)
    {
        _playerLocator = [[HiAccuracyLocator alloc] init];
        _playerLocator.delegate = self;
    }
    [_playerLocator startUpdatingLocation];
}

- (void) registerAllNotificationHandlers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNewPlayerLocated:)
                                                 name:kUserLocated
                                               object:[self playerLocator]];
}

+ (NSString*) documentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

#pragma mark - location notifications
- (void) handleNewPlayerLocated:(NSNotification *)note
{
    // Store up the last known player location
    Player* current = [Player getInstance];
    current.lastKnownLocation = [self playerLocator].bestLocation.coordinate;
    current.lastKnownLocationValid = TRUE;
}

#pragma mark - public functions

- (void) pushLoadingScreenIfNecessary:(UINavigationController*)nav message:(NSString*)message
{
    // first check the view on the stack, if the top view is not LoadingScreen,
    // then push that onto the stack
    UIViewController* current = [nav visibleViewController];
    if([current isMemberOfClass:[GameViewController class]])
    {
        [MBProgressHUD hideHUDForView:current.view animated:NO];
        MBProgressHUD* progHud = [MBProgressHUD showHUDAddedTo:current.view animated:YES];
        progHud.labelText = message;
    }
    else if(![current isMemberOfClass:[LoadingScreen class]])
    {
        LoadingTransition* transition = [[LoadingTransition alloc] initWithNibName:@"LoadingTransition" bundle:nil];
        [nav pushFadeInViewController:transition animated:YES];
        current = [[LoadingScreen alloc] initWithNibName:@"LoadingScreen" bundle:nil];
        [nav pushFadeInViewController:current animated:YES];
    }
    else if([current isMemberOfClass:[LoadingScreen class]])
    {
        LoadingScreen* loading = (LoadingScreen*)current;
        loading.progressLabel.text = message;
    }
}

- (void) popLoadingScreenToRootIfNecessary:(UINavigationController*)nav
{
    UIViewController* current = [nav visibleViewController];
    if([current isMemberOfClass:[GameViewController class]])
    {
        [MBProgressHUD hideHUDForView:current.view animated:NO];
    }
    else if([current isMemberOfClass:[LoadingScreen class]])
    {
        LoadingScreen* loadingScreen = (LoadingScreen*)current;
        [loadingScreen dismissWithCompletion:^(void){
            [nav popFadeOutToRootViewControllerAnimated:YES];
        }];
    } 
}

- (void) applicationWillEnterForeground
{
    [_traderpogServerReachability startNotifier];
    if (_gameState != kGameStateNew && ([_lastGameStateInitializeTime timeIntervalSinceNow] < timeTillReinitialize))
    {
        // if we are resuming the app after timeTillReinitialize has expired, just pop back to the
        // start screen for the player to press start again
        [self quitGame];
    }
}

- (void) applicationDidEnterBackground
{
    [_traderpogServerReachability stopNotifier];
    if([self gameViewController])
    {
        [self.gameViewController.mapControl deselectAllAnnotations];
        [self.gameViewController dismissInfoNotAnimated];
        [self.gameViewController dismissMyPostMenuAnimated:NO];
        if((kGameStateHomeSelect != [self gameState]) && (kGameStateFlyerSelect != [self gameState]))
        {
            [self.gameViewController dismissActiveWheelAnimated:NO];
        }
    }
}

- (void) clearCache
{
    [[AsyncHttpCallMgr getInstance] removeAsyncHttpCallMgrData];
    [[Player getInstance] removePlayerData];
    [[FlyerMgr getInstance] removeFlyerMgrData];
}

- (void) handleTradePogReachabilityChanged:(NSNotification*)note
{
    NSLog(@"Reachability changed to %d", [_traderpogServerReachability currentReachabilityStatus]);
}

- (void) validateConnectivity
{
    // Get the navigation controller
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    UINavigationController* nav = appDelegate.navController;
    
    // Check if the TraderPog is reachable
    if (![self isTraderPogServerReachable])
    {
        // No connectivity. Pop an error and return to root page.
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"No Connection"
                                                          message:@"TraderPog requires online connectivity. Please try again later."
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        
        [message show];
        [self popLoadingScreenToRootIfNecessary:nav];
    }
    else
    {
        [self pushLoadingScreenIfNecessary:nav message:@"Checking connectivity"];

        // We have connectivity; move onto the next steps
        [self selectNextGameUI];
    }
}

- (BOOL) isTraderPogServerReachable
{
    BOOL result = YES;
    if([_traderpogServerReachability currentReachabilityStatus] == NotReachable)
    {
        result = NO;
    }
    return result;
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
    else if (!_gameInfoModifiedDate || ([_gameInfoModifiedDateLastChecked timeIntervalSinceNow] < gameinfoRefreshTime))
    {
        [self pushLoadingScreenIfNecessary:nav message:@"Checking for server updates"];
        
        // If the gameinfo modified date has not been checked recently, go ahead and check it
        [self getGameInfoModifiedDate];
    }
    else if (!_asyncHttpCallsCompleted)
    {
        [self pushLoadingScreenIfNecessary:nav message:@"Completing outstanding http calls"];
        
        if (![[AsyncHttpCallMgr getInstance] startCalls])
        {
            // A return of FALSE from startCalls indicates no calls to make
            _asyncHttpCallsCompleted = TRUE;
            
            // Nothing to do; recursively call self to move on
            [self selectNextGameUI];
        }
    }
    else if (!_gameStateRefreshedFromServer)
    {
        // show loading screen and load game info from server
        _gameInfoRefreshSucceeded = TRUE;
        
        _currentServerCall = serverCallType_none;
        
        [self refreshServerData];
    }
    else if (!_danglingPostsResolved)
    {
        // If true is returned, then all posts are resolved and we can continue.
        if ([[TradePostMgr getInstance] resolveDanglingPosts])
        {
            _danglingPostsResolved = TRUE;
            [self selectNextGameUI];
        }
    }
    else if(![[Player getInstance] lastKnownLocationValid])
    {
        [self pushLoadingScreenIfNecessary:nav message:@"Determining player location"];
        
        [self locateNewPlayer];
    }
    // Player has no posts
    else if([[TradePostMgr getInstance] postsCount] == 0)
    {
        [self pushLoadingScreenIfNecessary:nav message:@"Generating initial trade post"];
        
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
        [self pushLoadingScreenIfNecessary:nav message:@"Generating first flyer"];
        
        // create player's first flyer
        NSArray* flyersArray = [[FlyerTypes getInstance] getFlyersForTier:1];
        NSInteger index = arc4random() % (flyersArray.count);
        FlyerType* newFlyerType = [flyersArray objectAtIndex:index];
        NSUInteger newFlyerTypeIndex = [[FlyerTypes getInstance] getFlyerIndexById:[newFlyerType flyerId]];
        if (![[FlyerMgr getInstance] newPlayerFlyerAtTradePost:[[TradePostMgr getInstance] getFirstMyTradePost] firstFlyer:newFlyerTypeIndex])
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
        UIViewController* current = [nav visibleViewController];
        if([current isMemberOfClass:[LoadingScreen class]])
        {
            LoadingScreen* loadingScreen = (LoadingScreen*)current;
            [loadingScreen dismissWithCompletion:^(void){
                [nav popFadeOutViewControllerAnimated:NO];
                [self startGame];
            }];
        }
        else if([current isMemberOfClass:[GameViewController class]])
        {
            [MBProgressHUD hideHUDForView:current.view animated:YES];
            [self startGame];
        }
        else
        {
            [self startGame];
        }
    }
}

- (void) flyer:(Flyer *)flyer departForTradePost:(TradePost *)tradePost
{
    if([[flyer path] curPostId] != [tradePost postId])
    {
        BOOL departed = [flyer departForPostId:[tradePost postId]];
        if(departed)
        {
            [self.gameViewController.mapControl centerOnFlyer:flyer animated:YES];
        }
    }
}

// returns TRUE if flyer successfully departed
// returns FALSE if it can't go home
- (BOOL) sendFlyerHome:(Flyer *)flyer
{
    BOOL goingHome = NO;
    if(![[FlyerMgr getInstance] homeOrHomeboundFlyer])
    {
        [self flyer:flyer departForTradePost:[[TradePostMgr getInstance] getFirstMyTradePost]];
        goingHome = YES;
    }
    _gameState = kGameStateGameLoop;
    
    return goingHome;
}

#pragma mark - in-game UI
// DISABLE_POSTWHEEL
/*
- (void) showHomeSelectForFlyer:(Flyer *)flyer
{
    if(kGameStateGameLoop == _gameState)
    {
        _gameState = kGameStateHomeSelect;
        _contextFlyer = flyer;
        [self.gameViewController showPostWheelAnimated:YES];
        
        [[SoundManager getInstance] playClip:@"Pog_SFX_PopUP_Level2"];
    }
}
*/
- (void) showFlyerSelectForBuyAtPost:(TradePost *)post
{
    if(kGameStateGameLoop == _gameState)
    {
        _gameState = kGameStateFlyerSelect;
        _contextPost = post;
        [self.gameViewController showFlyerWheelAnimated:YES];
        
        [[SoundManager getInstance] playClip:@"Pog_SFX_PopUP_Level2"];
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

- (void) wheel:(WheelControl *)wheel commitOnFlyer:(Flyer *)flyer
{
    if(kGameStateFlyerSelect == _gameState)
    {
        if((kFlyerStateIdle == [flyer state]) || (kFlyerStateLoaded == [flyer state]))
        {
            // Flyer Select
            // send committed flyer to the given post that triggered the FlyerSelect state
            NSAssert(_contextPost, @"FlyerSelect needs a current post");
            if(![_contextPost isMemberOfClass:[MyTradePost class]])
            {
                [[TradeManager getInstance] flyer:flyer buyFromPost:_contextPost numItems:[_contextPost supplyLevel]];
            }
            [self flyer:flyer departForTradePost:_contextPost];
        }
        
        _contextPost = nil;
        _gameState = kGameStateGameLoop;
    }
    else
    {
        // otherwise, center map on committed flyer
        [self.gameViewController.mapControl centerOnFlyer:flyer animated:YES];
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

- (void) haltMapAnnotationCalloutsForDuration:(NSTimeInterval)seconds
{
    if(0.0 < seconds)
    {
        @synchronized(self)
        {
            _calloutHaltBegin = [NSDate date];
            _calloutHaltDuration = seconds;
        }
        
        // dismiss all callouts
        [[[[GameManager getInstance] gameViewController] mapControl] deselectAllAnnotations];
    }
}

- (BOOL) canShowPostAnnotationCallout
{
    BOOL result = YES;
    
    // condition 1: don't show if explicitly halted
    {
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
    }
    
    // condition 2: don't show if map is not in callout zoom-level range
    if(result)
    {
        result = [self mapIsInCalloutZoomLevelRange];
    }
    
    return result;
}

- (BOOL) canShowFlyerAnnotationCallout
{
    BOOL result = YES;
    
    // condition 1: don't show if explicitly halted
    {
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
    }
    
    return result;
}

- (BOOL) mapIsInCalloutZoomLevelRange
{
    BOOL result = YES;
    if([self.gameViewController.mapControl zoomLevel] <= kNoCalloutZoomLevel)
    {
        result = NO;
    }
    return result;
}

- (BOOL) mapIsZoomEnabled
{
    BOOL result = [self.gameViewController.mapControl isZoomEnabled];
    return result;
}

- (BOOL) canProcessGameEventNotifications
{
    BOOL result = NO;
    if(kGameStateGameLoop == [[GameManager getInstance] gameState])
    {
        // only process game-event notifications while in GameLoop state
        // so that we don't confuse the UI flow by popping up during
        // a go-home home-select state or a buy flyer-select state
        result = YES;
    }
    return result;
}

- (BrowseEnforcedType) enforceBrowse:(BrowseEnforcedType)enforcedType
{
    BrowseEnforcedType result;
    
    if((kBrowseEnforcedNone == _browseEnforced) && (kBrowseEnforcedNone != enforcedType))
    {
        pthread_rwlock_wrlock(&_browseEnforcedLock);
        {
            // only set if nothing is being enforced
            _browseEnforced = enforcedType;
            result = _browseEnforced;
        }
        pthread_rwlock_unlock(&_browseEnforcedLock);
    }
    else if(kBrowseEnforcedNone == enforcedType)
    {
        // clear
        pthread_rwlock_wrlock(&_browseEnforcedLock);
        _browseEnforced = enforcedType;
        pthread_rwlock_unlock(&_browseEnforcedLock);
    }
    
    return result;
}

- (BrowseEnforcedType) currentBrowseEnforced
{
    BrowseEnforcedType result;
    
    pthread_rwlock_rdlock(&_browseEnforcedLock);
    result = _browseEnforced;
    pthread_rwlock_unlock(&_browseEnforcedLock);
    
    return result;
}

#pragma mark - HiAccuracyLocatorDelegate
- (void) locator:(HiAccuracyLocator *)locator didLocateUser:(BOOL)didLocateUser
{
    // remove self as delegate and drop the locator, we only need to know once
    locator.delegate = nil;
    
    if(didLocateUser)
    {
        // Store up the last known player location
        Player* current = [Player getInstance];
        current.lastKnownLocation = [self playerLocator].bestLocation.coordinate;
        current.lastKnownLocationValid = TRUE;
        
        [self selectNextGameUI];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot determine current location"
                                                        message:@"TraderPog requires location services to discover trade posts. Please try again later"
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        [alert show];
        [self quitGame];
    }
    _playerLocator = nil;
}

#pragma mark - HttpCallbackDelegate
- (void) didCompleteHttpCallback:(NSString*)callName, BOOL success
{
    if ([callName compare:kPlayer_GetPlayerDataWithFacebook] == NSOrderedSame)
    {
        if (success)
        {
            NSLog(@"Done associating current account with server.");
            [self.gameViewController setBeaconWheelText:@"Invite Friends"];
            [[ObjectivesMgr getInstance] setAllNewUserCompleted];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Linked with Facebook!"
                                                            message:@"The current account has now been linked with Facebook"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            
            [alert show];
        }
        
        [self selectNextGameUI];
    }
    else if ([callName compare:kTradeItemTypes_ReceiveItems] == NSOrderedSame ||
        [callName compare:kFlyerTypes_ReceiveFlyers] == NSOrderedSame ||
        [callName compare:kResourceManager_PackageReady] == NSOrderedSame ||
        [callName compare:kPlayer_GetPlayerData] == NSOrderedSame ||
        [callName compare:kTradePostMgr_ReceivePosts] == NSOrderedSame ||
        [callName compare:kFlyerMgr_ReceiveFlyers] == NSOrderedSame ||
        [callName compare:kBeaconMgr_ReceiveBeacons] == NSOrderedSame ||
        [callName compare:kPlayerSales_ReceiveSales] == NSOrderedSame)
    {
        _gameInfoRefreshSucceeded = _gameInfoRefreshSucceeded && success;
        if (_gameInfoRefreshSucceeded)
        {
            // Try to make the next server call
            NSLog(@"Successful http call received from: %@. Trying next call.", callName);
            _currentServerCall++;
            [self refreshServerData];
        }
        else
        {
            // Something failed in the game refresh process. Stop for now.
            // Pop the loading screen.
            NSLog(@"Http call %@ failed. Stopping cycle.", callName);
            _gameStateRefreshedFromServer = FALSE;
            AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
            UINavigationController* nav = appDelegate.navController;
            [self popLoadingScreenToRootIfNecessary:nav];
        }
    }
    else if ([callName compare:kTradePostMgr_ReceiveSinglePost] == NSOrderedSame)
    {
        // Dangling posts resolved (or should be)
        // If we don't set this to true, and there's an error resolving the dangling posts
        // selectNextGameUI will go into an infinite loop.
        _danglingPostsResolved = TRUE;
        [self selectNextGameUI];
    }
    else
    {
        NSLog(@"Http callback received from call: %@. Calling selectNextGameUI.", callName);
        [self selectNextGameUI];
    }
}

#pragma mark - AsyncHttpDelegate
- (void) didCompleteAsyncHttpCallback:(BOOL)success
{
    // Either failure or no remaining calls means we should pop back to selectNextGameUI
    if (!success || ![[AsyncHttpCallMgr getInstance] callsRemain])
    {
        _asyncHttpCallsCompleted = TRUE;
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
