//
//  Player.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "GameManager.h"
#import "Player.h"
#import "AFClientManager.h"
#import "AFHTTPRequestOperation.h"
#import "AppDelegate.h"
#import "LoadingScreen.h"
#import "UINavigationController+Pog.h"

// encoding keys
static NSString* const kKeyVersion = @"version";
static NSString* const kKeyUserId = @"id";
static NSString* const kKeySecretkey = @"secretkey";
static NSString* const kKeyFacebookId = @"fbid";
static NSString* const kKeyFacebookFriends = @"fb_friends";
static NSString* const kKeyEmail = @"email";
static NSString* const kKeyBucks = @"bucks";
static NSString* const kKeyMember = @"member";
static NSString* const kKeyFbAccessToken = @"fbaccesstoken";
static NSString* const kKeyFbExpiration = @"fbexpiration";
static NSString* const kKeyFbFriendsRefresh = @"fbfriendsrefresh";
static NSString* const kKeyFbPostUpdate = @"fbpostupdate";
static NSString* const kPlayerFilename = @"player.sav";

static double const refreshTime = -(60 * 15);  // 15 min
static double const refreshTimeFriends = -(60 * 60 * 24 * 2);  // 2 days
static double const refreshTimePost = -(60 * 60 * 24);  // 1 day

@implementation Player
@synthesize delegate = _delegate;
@synthesize id = _id;
@synthesize dataRefreshed = _dataRefreshed;
@synthesize facebook = _facebook;

- (id) init
{
    self = [super init];
    if(self)
    {
        // TODO: this needs fixing; it doesn't get re-registered when server ip gets reset
        /*
        [[[AFClientManager sharedInstance] pogProfile] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status){
            [self handleNetworkReachabilityChanged:status];
        }]; 
         */
        
        // not yet logged in
        _id = 0;
        _facebookid = @"";
        _email = @"";
        _member = FALSE;
        _bucks = 0;
        _fbAccessToken = nil;
        _fbExpiration = nil;
        _fbFriends = nil;
        
        _lastUpdate = nil;
        _fbFriendsUpdate = nil;
        _fbPostUpdate = nil;
        
        // Initialize delegate
        _delegate = nil;
        
        [self initializeFacebook];
    }
    return self;
}

- (BOOL) needsRefresh
{
    return (!_lastUpdate) || ([_lastUpdate timeIntervalSinceNow] < refreshTime);
}

- (BOOL) needsFriendsRefresh
{
    // Check that facebook is initialized first. Then check to see if
    // the friends list needs to be updated. 
    return (_facebook && ((!_fbFriendsUpdate) || ([_fbFriendsUpdate timeIntervalSinceNow] < refreshTimeFriends)));
}

- (BOOL) canUpdateFacebookFeed
{
    return (_facebook && ((!_fbPostUpdate) || ([_fbPostUpdate timeIntervalSinceNow] < refreshTimePost)));
}

#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_createdVersion forKey:kKeyVersion];
    [aCoder encodeInteger:_id forKey:kKeyUserId];
    [aCoder encodeObject:_secretkey forKey:kKeySecretkey];
    [aCoder encodeObject:_fbAccessToken forKey:kKeyFbAccessToken];
    [aCoder encodeObject:_fbExpiration forKey:kKeyFbExpiration];
    [aCoder encodeObject:_fbFriendsUpdate forKey:kKeyFbFriendsRefresh];
    [aCoder encodeObject:_fbPostUpdate forKey:kKeyFbPostUpdate];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _createdVersion = [aDecoder decodeObjectForKey:kKeyVersion];
    _id = [aDecoder decodeIntegerForKey:kKeyUserId];
    _secretkey = [aDecoder decodeObjectForKey:kKeySecretkey];
    _fbAccessToken = [aDecoder decodeObjectForKey:kKeyFbAccessToken];
    _fbExpiration = [aDecoder decodeObjectForKey:kKeyFbExpiration];
    _fbFriendsUpdate = [aDecoder decodeObjectForKey:kKeyFbFriendsRefresh];
    _fbPostUpdate = [aDecoder decodeObjectForKey:kKeyFbPostUpdate];
    return self;
}

#pragma mark - private functions 

+ (NSString*) playerFilepath
{
    NSString* docsDir = [GameManager documentsDirectory];
    NSString* filepath = [docsDir stringByAppendingPathComponent:kPlayerFilename];
    return filepath;
}

#pragma mark - saved game data loading and unloading
+ (Player*) loadPlayerData
{
    Player* current_player = nil;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* filepath = [Player playerFilepath];
    if ([fileManager fileExistsAtPath:filepath]) 
    {
        NSData* readData = [NSData dataWithContentsOfFile:filepath];
        if(readData)
        {
            current_player = [NSKeyedUnarchiver unarchiveObjectWithData:readData];
            [current_player initializeFacebook];
        }
    }
    return current_player;
}

- (void) savePlayerData
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    NSError* error = nil;
    BOOL writeSuccess = [data writeToFile:[Player playerFilepath]
                                  options:NSDataWritingAtomic
                                    error:&error];
    if(writeSuccess)
    {
        NSLog(@"player file saved successfully");
    }
    else 
    {
        NSLog(@"player file save failed: %@", error);
    }
}

- (void) removePlayerData
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* filepath = [Player playerFilepath];
    NSError *error = nil;
    if ([fileManager fileExistsAtPath:filepath]) 
    {
        [fileManager removeItemAtPath:filepath error:&error];
    }
}

#pragma mark - Public

- (void) appDidEnterBackground
{
    [self savePlayerData];
}

- (void) getPlayerDataFromServerUsingFacebookId
{
    // make a get request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    NSString* path = [NSString stringWithFormat:@"users/facebook"];
    [httpClient setDefaultHeader:@"Facebook-Id" value:_facebookid];
    [httpClient getPath:path
             parameters:nil
                success:^(AFHTTPRequestOperation *operation, id responseObject){
                    _id = [[responseObject valueForKeyPath:kKeyUserId] integerValue];
                    _secretkey = [responseObject valueForKeyPath:kKeySecretkey];
                    _bucks = [[responseObject valueForKeyPath:kKeyBucks] integerValue];
                    _email = [responseObject valueForKeyPath:kKeyEmail];
                    _member = [[responseObject valueForKeyPath:kKeyMember] boolValue];
                    _lastUpdate = [NSDate date];
                    [self savePlayerData];
                    [self.delegate didCompleteHttpCallback:kPlayer_GetPlayerDataWithFacebook, TRUE];
                }
                failure:^(AFHTTPRequestOperation* operation, NSError* error){
                    if ([[operation response] statusCode] == 404)
                    {
                        // Unable to retrieve data based on facebookid. So, create a
                        // new account with this facebook id.
                        [self createNewPlayerOnServer];
                    }
                    else
                    {
                        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                          message:@"Unable to retrieve player data. Please try again later."
                                                                         delegate:nil
                                                                cancelButtonTitle:@"OK"
                                                                otherButtonTitles:nil];
                        
                        [message show];
                        [self.delegate didCompleteHttpCallback:kPlayer_GetPlayerDataWithFacebook, FALSE];
                    }
                }
     ];
    [httpClient setDefaultHeader:@"Facebook-Id" value:nil];
}

- (void) getPlayerDataFromServer
{    
    // make a get request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    NSString* path = [NSString stringWithFormat:@"users/%d.json", _id];
    [httpClient getPath:path
              parameters:nil
                 success:^(AFHTTPRequestOperation *operation, id responseObject){                     
                     _bucks = [[responseObject valueForKeyPath:kKeyBucks] integerValue];
                     _email = [responseObject valueForKeyPath:kKeyEmail];
                     _facebookid = [responseObject valueForKeyPath:kKeyFacebookId];
                     _member = [[responseObject valueForKeyPath:kKeyMember] boolValue];
                     _lastUpdate = [NSDate date];
                     [self.delegate didCompleteHttpCallback:kPlayer_GetPlayerData, TRUE];
                 }
                 failure:^(AFHTTPRequestOperation* operation, NSError* error){
                     UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                       message:@"Unable to retrieve player data. Please try again later."
                                                                      delegate:nil
                                                             cancelButtonTitle:@"OK"
                                                             otherButtonTitles:nil];
                     
                     [message show];
                     [self.delegate didCompleteHttpCallback:kPlayer_GetPlayerData, FALSE];
                 }
     ];
}

- (void) createNewPlayerOnServer
{
    // post parameters
    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                _facebookid, kKeyFacebookId,
                                _fbFriends, kKeyFacebookFriends,
                                _email, kKeyEmail, 
                                nil];
    
    // make a post request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    [httpClient postPath:@"users.json" 
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject){                     
                     _id = [[responseObject valueForKeyPath:kKeyUserId] integerValue];
                     _secretkey = [responseObject valueForKeyPath:kKeySecretkey];
                     _bucks = [[responseObject valueForKeyPath:kKeyBucks] integerValue];
                     _lastUpdate = [NSDate date];
                     NSLog(@"user id is %i", _id);
                     [self savePlayerData];
                     [self.delegate didCompleteHttpCallback:kPlayer_CreateNewUser, TRUE];
                 }
                 failure:^(AFHTTPRequestOperation* operation, NSError* error){
                     UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                       message:@"Unable to create account. Please try again later."
                                                                      delegate:nil
                                                             cancelButtonTitle:@"OK"
                                                             otherButtonTitles:nil];
                     
                     [message show];
                     [self.delegate didCompleteHttpCallback:kPlayer_CreateNewUser, FALSE];
                 }
     ];
}

- (void) updatePlayerOnServer
{
    // post parameters
    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                _facebookid, kKeyFacebookId,
                                _fbFriends, kKeyFacebookFriends,
                                _email, kKeyEmail,
                                nil];
    
    // make a post request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    NSString* path = [NSString stringWithFormat:@"users/%d.json", _id];
    [httpClient putPath:path
             parameters:parameters
                success:^(AFHTTPRequestOperation *operation, id responseObject){
                    NSLog(@"Player data updated");
                    _fbFriendsUpdate = [NSDate date];
                    [self.delegate didCompleteHttpCallback:kPlayer_SavePlayerData, TRUE];
                }
                failure:^(AFHTTPRequestOperation* operation, NSError* error){
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                      message:@"Unable to save player data. Please try again later."
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    
                    [message show];
                    [self.delegate didCompleteHttpCallback:kPlayer_SavePlayerData, FALSE];
                }
     ];
}

#pragma mark - Facebook functions

- (void)initializeFacebook
{
    if (!_facebook)
    {
        _facebook = [[Facebook alloc] initWithAppId:@"462130833811786" andDelegate:self];
        
        if (_fbAccessToken && _fbExpiration) {
            _facebook.accessToken = _fbAccessToken;
            _facebook.expirationDate = _fbExpiration;
            
            if ([_facebook.expirationDate timeIntervalSinceNow] < 0)
            {
                [_facebook extendAccessTokenIfNeeded];
            }
        }
    }
}

- (BOOL) facebookSessionValid
{
    return _facebook && [_facebook isSessionValid];
}

- (void)authorizeFacebook
{
    // if necessary, pop facebook UI to obtain user authorization. 
    if (_facebook && ![_facebook isSessionValid]) {
        NSArray *permissions = [[NSArray alloc] initWithObjects:
                                @"publish_actions",
                                nil];
        [_facebook authorize:permissions];
    }
}

- (void)updateFacebookFeed:(NSString*)message
{
    if ([self canUpdateFacebookFeed])
    {
        NSMutableDictionary* params1 = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        //appId, @"api_key",
                                        message, @"message",
                                        //@"https://www.mybantu.com", @"link",
                                        //@"https:/www.mybantu.com/myphoto.png", @"picture",
                                        @"TraderPog", @"name",
                                        @"Pogs Can Fly", @"description",
                                        //    @"100001309042820", @"target_id",
                                        nil];
        [_facebook requestWithGraphPath:@"me/feed" andParams:params1 andHttpMethod:@"POST" andDelegate:self];
        _fbPostUpdate = [NSDate date];
    }
}

- (void)fbDidLogin {
    // show loading screen
    LoadingScreen* loading = [[LoadingScreen alloc] initWithNibName:@"LoadingScreen" bundle:nil];
    loading.progressLabel.text = @"Storing Facebook info";
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    UINavigationController* nav = appDelegate.navController;
    [nav pushFadeInViewController:loading animated:YES];
    
    _fbAccessToken = [_facebook accessToken];
    _fbExpiration = [_facebook expirationDate];
    [self savePlayerData];
    
    // get information about the currently logged in user
    [_facebook requestWithGraphPath:@"me" andDelegate:self];
}

- (void)fbDidNotLogin:(BOOL)cancelled
{
    // Do nothing. This should pop the user back to the previous UI, which will
    // allow them to continue as before. 
}

- (void)fbDidExtendToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt
{
    _fbAccessToken = [_facebook accessToken];
    _fbExpiration = [_facebook expirationDate];
    [self savePlayerData];
}

- (void)fbDidLogout
{
    // TODO: Still needs to be implemented
}

- (void)fbSessionInvalidated
{
    // TODO: Still needs to be implemented
}

- (void)parseFacebookFriends:(NSArray*)friendsArray
{
    _fbFriends = @"";
    for (id object in friendsArray) {
        NSDictionary* dict = (NSDictionary*)object;
        if ([_fbFriends length] > 0)
        {
            _fbFriends = [_fbFriends stringByAppendingString:@"|"];
        }
        _fbFriends = [_fbFriends stringByAppendingString:[dict valueForKeyPath:@"id"]];
    }
    NSLog(@"Friends: %@", _fbFriends);
}

- (void)request:(FBRequest *)request didLoad:(id)result
{
    NSLog(@"Facebook request %@ loaded", [request url]);
    
    //handling a user friends info request
    if ([[request url] rangeOfString:@"me/friends"].location != NSNotFound)
    {
        NSLog(@"Facebook /me/friends call completed");
        
        [self parseFacebookFriends:[result valueForKeyPath:@"data"]];
        
        if ([Player getInstance].id == 0)
        {
            // Player has not yet been created or retrieved.
            [self getPlayerDataFromServerUsingFacebookId];
        }
        else
        {
            // Player has already been created. Associate facebookid
            // with this user
            [self updatePlayerOnServer];
            // TODO: Force a refresh of beacons
        }
    }
    else if ([[request url] rangeOfString:@"me/feed"].location != NSNotFound)
    {
        NSLog(@"Facebook /me/feed call completed");
    }
    //handling a user info request
    else if ([[request url] rangeOfString:@"/me"].location != NSNotFound)
    {
        NSLog(@"Facebook /me call completed");
        
        // Grab the facebook ID for the current user
        _facebookid = [result valueForKeyPath:@"id"];
        
        [self getFacebookFriendsList];
    }
    else
    {
        NSLog(@"Unknown FBRequest didLoad completion.");
    }
}
         
- (void) getFacebookFriendsList
{
    // get the logged-in user's friends
    [_facebook requestWithGraphPath:@"me/friends" andDelegate:self];
}

#pragma mark - Singleton
static Player* singleton = nil;
+ (Player*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
            // First, try to load the player data from disk
            singleton = [Player loadPlayerData];
            if (!singleton)
            {
                // OK, no saved data available. Go ahead and create a new Player. 
                singleton = [[Player alloc] init];
            }
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
