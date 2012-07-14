//
//  SetupNewPlayer.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "SetupNewPlayer.h"
#import "GameManager.h"
#import "Player.h"
#import "LoadingScreen.h"
#import "PogProfileAPI.h"
#import "HiAccuracyLocator.h"

@interface SetupNewPlayer ()
{
    LoadingScreen* _loadingScreen;
    HiAccuracyLocator* _playerLocator;
    CLLocation* _playerLocation;
}
@property (nonatomic,readonly) LoadingScreen* loadingScreen;
@property (nonatomic,readonly) HiAccuracyLocator* playerLocator;
@property (nonatomic,readonly) CLLocation* playerLocation;

// steps
- (void) registerNewAccountWithEmail:(NSString*)email;
- (void) locatePlayer;

// location notifications
- (void) handlePlayerLocated:(NSNotification*)note;
- (void) handlePlayerLocationDenied:(NSNotification*)note;

// loading screen
- (void) setLoadingProgressText:(NSString*)text;
@end

@implementation SetupNewPlayer
@synthesize loadingScreen = _loadingScreen;
@synthesize playerLocator = _playerLocator;
@synthesize playerLocation = _playerLocation;

- (id) initWithEmail:(NSString *)email loadingScreen:(LoadingScreen *)loadingScreen
{
    self = [super init];
    if(self)
    {
        _loadingScreen = loadingScreen;
        if([self loadingScreen])
        {
            [self.loadingScreen.bigLabel setText:@"Entering PogVerse"];
        }
        [self registerNewAccountWithEmail:email];
    }
    return self;
}

#pragma mark - setup steps

// step 1: register new account
- (void) registerNewAccountWithEmail:(NSString *)email
{
    [self setLoadingProgressText:@"Determining your location"];
    [[PogProfileAPI getInstance] setDelegate:self];
    [[PogProfileAPI getInstance] newUserWithEmail:email];    
}

// step 2: locate player
- (void) locatePlayer
{
    [self setLoadingProgressText:@"Determining your location"];
    
    _playerLocator = [[HiAccuracyLocator alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlePlayerLocated:)
                                                 name:kUserLocated
                                               object:[self playerLocator]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlePlayerLocationDenied:)
                                                 name:kUserLocationDenied
                                               object:[self playerLocator]];
    [self.playerLocator startUpdatingLocation];
}

// step 2b: finish locate player
- (void) finishLocatePlayer
{
    _playerLocation = [self.playerLocator bestLocation];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// step 3: setup Homebase
- (void) setupHomebase
{
    [self setLoadingProgressText:@"Setting up Homebase"];
    [[GameManager getInstance] setupHomebaseAtLocation:_playerLocation];
    [[GameManager getInstance] completeSetupNewPlayer];
}

#pragma mark - loading screen
- (void) setLoadingProgressText:(NSString *)text
{
    if([self loadingScreen])
    {
        [self.loadingScreen.progressLabel setText:text];
    }
}

#pragma mark - location notifications
- (void) handlePlayerLocated:(NSNotification *)note
{
    [self finishLocatePlayer];
    
    // next step
    [self setupHomebase];
}

- (void) handlePlayerLocationDenied:(NSNotification *)note
{
    [[GameManager getInstance] abortSetupNewPlayer];
}


#pragma mark - PogProfileDelegate
- (void) didCompleteAccountRegistrationForUserId:(NSString *)userId
{    
    // next step
    [self locatePlayer];
}

@end
