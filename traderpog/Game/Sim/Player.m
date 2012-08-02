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
static NSString* const kKeyEmail = @"email";
static NSString* const kKeyBucks = @"bucks";
static NSString* const kKeyMember = @"member";
static NSString* const kKeyFbAccessToken = @"fbaccesstoken";
static NSString* const kKeyFbExpiration = @"fbexpiration";
static NSString* const kPlayerFilename = @"player.sav";

static double const refreshTime = -(60 * 15);

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

#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_createdVersion forKey:kKeyVersion];
    [aCoder encodeInteger:_id forKey:kKeyUserId];
    [aCoder encodeObject:_secretkey forKey:kKeySecretkey];
    [aCoder encodeObject:_fbAccessToken forKey:kKeyFbAccessToken];
    [aCoder encodeObject:_fbExpiration forKey:kKeyFbExpiration];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _createdVersion = [aDecoder decodeObjectForKey:kKeyVersion];
    _id = [aDecoder decodeIntegerForKey:kKeyUserId];
    _secretkey = [aDecoder decodeObjectForKey:kKeySecretkey];
    _fbAccessToken = [aDecoder decodeObjectForKey:kKeyFbAccessToken];
    _fbExpiration = [aDecoder decodeObjectForKey:kKeyFbExpiration];
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

- (void)authorizeFacebook
{
    if (_facebook && ![_facebook isSessionValid]) {
        [_facebook authorize:nil];
    }
}

- (void)fbDidLogin {
    _fbAccessToken = [_facebook accessToken];
    _fbExpiration = [_facebook expirationDate];
    [self savePlayerData];
    
    // get information about the currently logged in user
    [_facebook requestWithGraphPath:@"me" andDelegate:self];
}

- (void)fbDidNotLogin:(BOOL)cancelled
{
    // TODO: Still needs to be implemented
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
        [self parseFacebookFriends:[result valueForKeyPath:@"data"]];
        
        if ([Player getInstance].id == 0)
        {
            // Player has not yet been created or retrieved.
            // First try retrieving based on facebookid
            // TODO: Implement this. Cheat first and go straight to user account creation
            [self getPlayerDataFromServerUsingFacebookId];
            
        }
        else
        {
            // Player has already been created. Associate facebookid
            // with this user
            // TODO: implement this
        }
    }
        //handling a user info request
    else if ([[request url] rangeOfString:@"/me"].location != NSNotFound)
    {
        // show loading screen
        LoadingScreen* loading = [[LoadingScreen alloc] initWithNibName:@"LoadingScreen" bundle:nil];
        loading.progressLabel.text = @"Storing Facebook info";
        AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        UINavigationController* nav = appDelegate.navController;
        [nav pushFadeInViewController:loading animated:YES];
        
        // Grab the facebook ID for the current user
        _facebookid = [result valueForKeyPath:@"id"];
        
        // get the logged-in user's friends
        [_facebook requestWithGraphPath:@"me/friends" andDelegate:self];
        
    }
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
