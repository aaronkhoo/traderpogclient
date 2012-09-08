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
#import "UINavigationController+Pog.h"
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
#import <CoreLocation/CoreLocation.h>

// List of Game UI screens that GameManager can kick off
#import "SignupScreen.h"

// How often to check if the gameinfo has been updated (2 hours)
static double const timeTillReinitialize = -(60 * 30);
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
    serverCallType_facebook,
    
    // Any new server calls should go above this
    serverCallType_end
} serverCallType;

@interface GameManager ()
{
    // Game state variables
    serverCallType _currentServerCall;
    BOOL _gameStateRefreshedFromServer;
    BOOL _gameInfoRefreshSucceeded;
    
    // Last time we went through game state initialization
    NSDate* _lastGameStateInitializeTime;
    
    // Variables to track any outstanding async http calls that need to be completed
    BOOL _asyncHttpCallsCompleted;
    
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
@property (nonatomic,strong) ModalNavControl* modalNav;
@property (nonatomic,strong) HiAccuracyLocator* playerLocator;

- (void) getGameInfoModifiedDate;

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

#pragma mark - initialization
- (id) init
{
    self = [super init];
    if(self)
    {
        _currentServerCall = serverCallType_none;
        _gameStateRefreshedFromServer = FALSE;
        _lastGameStateInitializeTime = nil;
        _gameInfoRefreshSucceeded = TRUE;
        
        _gameState = kGameStateNew;
        _loadingScreen = nil;
        _gameViewController = nil;
        
        _asyncHttpCallsCompleted = FALSE;
        
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

- (void) resetGame
{
    // abort all the way back to the start screen
    _gameState = kGameStateNew;
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    UINavigationController* nav = appDelegate.navController;
    [nav popFadeOutToRootViewControllerAnimated:YES];
    _gameViewController = nil;
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
            
        case serverCallType_facebook:
            // Refresh friends data from Facebook if necessary
            [self pushLoadingScreenIfNecessary:nav message:@"Cornering markets..."];
            if ([[Player getInstance] facebookSessionValid] && [[Player getInstance] needsFriendsRefresh])
            {
                [[Player getInstance] getFacebookFriendsList];
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
    [self resetGame];
}

- (void) pushLoadingScreenIfNecessary:(UINavigationController*)nav message:(NSString*)message
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
    loading.progressLabel.text = message;
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
    if (_gameState != kGameStateNew && ([_lastGameStateInitializeTime timeIntervalSinceNow] < timeTillReinitialize))
    {
        [self resetGame];
        _currentServerCall = serverCallType_none;
        _gameStateRefreshedFromServer = FALSE;
        _asyncHttpCallsCompleted = TRUE;
        [self validateConnectivity];
    }
}

- (void) clearCache
{
    [[AsyncHttpCallMgr getInstance] removeAsyncHttpCallMgrData];
    [[Player getInstance] removePlayerData];
    [[FlyerMgr getInstance] removeFlyerMgrData];
}

- (void) validateConnectivity
{
    // Get the navigation controller
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    UINavigationController* nav = appDelegate.navController;
    [self pushLoadingScreenIfNecessary:nav message:@"Checking connectivity"];
    
    // Check if the TraderPog is reachable
    Reachability* hostReach = [Reachability reachabilityWithHostname: [[AFClientManager sharedInstance] getTraderPogURL]];
    // It looks like there are occasional transient errors, try a couple times before giving up.
    BOOL noConnectivity = FALSE;
    unsigned int retries = 0;
    while ([hostReach currentReachabilityStatus] == NotReachable)
    {
        if (retries < 3)
        {
            retries++;
            sleep(3);
        }
        else
        {
            noConnectivity = TRUE;
            break;
        }
    }
    if (noConnectivity)
    {
        // No connectivity. Pop an error and return to root page.
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"No Connection"
                                                          message:@"TraderPog requires online connectivity. Please try again later."
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        
        [message show];
        [self popLoadingScreenIfNecessary:nav];
    }
    else
    {
        // We have connectivity; move onto the next steps
        [self selectNextGameUI];
    }
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
        if (![[FlyerMgr getInstance] newPlayerFlyerAtTradePost:[[TradePostMgr getInstance] getFirstMyTradePost]                                    firstFlyer:index])
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
        
        _lastGameStateInitializeTime = [[NSDate alloc] init];
        
        // handle in-game states
        switch(_gameState)
        {
            case kGameStateNew:
                // Set game state to loop and set initialize time to now
                _gameState = kGameStateGameLoop;
                
                // Save the player state
                [[Player getInstance] savePlayerData];
                
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
    if([[flyer path] curPostId] != [tradePost postId])
    {
        if ([flyer departForPostId:[tradePost postId]])
        {
            TradePost* curPost = [[TradePostMgr getInstance] getTradePostWithId:[[flyer path] curPostId]];
            curPost.hasFlyer = NO;
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

- (void) showFlyerSelectForBuyAtPost:(TradePost *)post
{
    if(kGameStateGameLoop == _gameState)
    {
        _gameState = kGameStateFlyerSelect;
        _contextPost = post;
        [self.gameViewController showFlyerWheelAnimated:YES];
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
        // Flyer Select
        // send committed flyer to the given post that triggered the FlyerSelect state
        NSAssert(_contextPost, @"FlyerSelect needs a current post");
        [[TradeManager getInstance] flyer:flyer buyFromPost:_contextPost numItems:[_contextPost supplyLevel]];
        [self flyer:flyer departForTradePost:_contextPost];
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

#pragma mark - global UI controls
- (void) haltMapAnnotationCalloutsForDuration:(NSTimeInterval)seconds
{
    if(0.0 < seconds)
    {
        @synchronized(self)
        {
            _calloutHaltBegin = [NSDate date];
            _calloutHaltDuration = seconds;
        }
    }
}

- (BOOL) canShowMapAnnotationCallout
{
    BOOL result = YES;
    @synchronized(self)
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

#pragma mark - HttpCallbackDelegate
- (void) didCompleteHttpCallback:(NSString*)callName, BOOL success
{
    if ([callName compare:kTradeItemTypes_ReceiveItems] == NSOrderedSame ||
        [callName compare:kFlyerTypes_ReceiveFlyers] == NSOrderedSame ||
        [callName compare:kResourceManager_PackageReady] == NSOrderedSame ||
        [callName compare:kPlayer_GetPlayerData] == NSOrderedSame ||
        [callName compare:kTradePostMgr_ReceivePosts] == NSOrderedSame ||
        [callName compare:kFlyerMgr_ReceiveFlyers] == NSOrderedSame ||
        [callName compare:kPlayer_SavePlayerData] == NSOrderedSame ||
        [callName compare:kBeaconMgr_ReceiveBeacons] == NSOrderedSame)
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
            [self popLoadingScreenIfNecessary:nav];
        }
    }
    else
    {
        NSLog(@"Http callback received from unknown call: %@", callName);
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
