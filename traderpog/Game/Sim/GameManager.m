//
//  GameManager.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "GameManager.h"
#import "Player.h"
#import "LoadingScreen.h"
#import "PogProfileAPI.h"

@implementation GameManager
@synthesize player = _player;
@synthesize loadingScreen = _loadingScreen;

- (id) init
{
    self = [super init];
    if(self)
    {
        _player = nil;
        _loadingScreen = nil;
    }
    return self;
}

#pragma mark - public methods
- (void) newGameWithEmail:(NSString*)email;
{
    // register new account
    if([self loadingScreen])
    {
        [self.loadingScreen.bigLabel setText:@"Entering PogVerse"];
        [self.loadingScreen.progressLabel setText:@"Registering new account"];
    }
    [[PogProfileAPI getInstance] setDelegate:self];
    [[PogProfileAPI getInstance] newUserWithEmail:email];
}

- (void) loadGame
{
    // TODO: load from saved game file if any
}

#pragma mark - PogProfileDelegate
- (void) didCompleteAccountRegistrationForUserId:(NSString *)userId
{
    self.player = [[Player alloc] initWithUserId:userId];
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
