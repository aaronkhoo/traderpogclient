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

// encoding keys
static NSString* const kKeyVersion = @"version";
static NSString* const kKeyUserId = @"id";
static NSString* const kKeySecretkey = @"secretkey";
static NSString* const kKeyFacebookId = @"fbid";
static NSString* const kKeyEmail = @"email";
static NSString* const kPlayerFilename = @"player.sav";

@implementation Player
@synthesize delegate = _delegate;
@synthesize id = _id;

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
        
        // Initialize delegate
        _delegate = nil;
    }
    return self;
}

#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_createdVersion forKey:kKeyVersion];
    [aCoder encodeInteger:_id forKey:kKeyUserId];
    [aCoder encodeObject:_secretkey forKey:kKeySecretkey];}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _createdVersion = [aDecoder decodeObjectForKey:kKeyVersion];
    _id = [aDecoder decodeIntegerForKey:kKeyUserId];
    _secretkey = [aDecoder decodeObjectForKey:kKeySecretkey];    
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

- (void) createNewPlayerOnServer:(NSString*)facebookid
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
                     NSLog(@"user id is %i", _id);
                     [self savePlayerData];
                     [self.delegate didCompleteHttpCallback:@"CreateNewUser", TRUE];
                 }
                 failure:^(AFHTTPRequestOperation* operation, NSError* error){
                     UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                       message:@"Unable to create account. Please try again later."
                                                                      delegate:nil
                                                             cancelButtonTitle:@"OK"
                                                             otherButtonTitles:nil];
                     
                     [message show];
                     [self.delegate didCompleteHttpCallback:@"CreateNewUser", FALSE];
                 }
     ];
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
