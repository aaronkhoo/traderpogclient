//
//  Player.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FBConnect.h"
#import <UIKit/UIKit.h>
#import "HttpCallbackDelegate.h"

static NSString* const kPlayer_CreateNewUser = @"CreateNewUser";
static NSString* const kPlayer_SavePlayerData = @"SavePlayerData";
static NSString* const kPlayer_GetPlayerData = @"GetPlayerData";
static NSString* const kPlayer_GetPlayerDataWithFacebook = @"GetPlayerDataWithFacebook";

@interface Player : NSObject<NSCoding, FBSessionDelegate, FBRequestDelegate>
{
    // internal
    NSString* _createdVersion;
    
    // User data
    NSInteger _playerId;
    BOOL _member;
    NSUInteger _bucks;
    NSString* _secretkey;
    NSString* _facebookid;
    NSString* _email;
    NSString* _fbAccessToken;
    NSDate* _fbExpiration;
    NSString* _fbFriends;
    
    NSDate* _lastUpdate;
    NSDate* _fbFriendsUpdate;
    NSDate* _fbPostUpdate;
    
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<HttpCallbackDelegate>* _delegate;
    
    Facebook* _facebook;
}
@property (nonatomic) NSInteger playerId;
@property (nonatomic) BOOL dataRefreshed;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegate;
@property (nonatomic, retain) Facebook *facebook;

- (void)initializeFacebook;
- (void)authorizeFacebook;
- (BOOL)needsRefresh;
- (BOOL)needsFriendsRefresh;
- (void)createNewPlayerOnServer;
- (void)getPlayerDataFromServer;
- (BOOL)facebookSessionValid;
- (void)getFacebookFriendsList;
- (void)updateFacebookFeed:(NSString*)message;

// trade
- (void) addBucks:(NSUInteger)newBucks;
- (void) deductBucks:(NSUInteger)bucksToSub;
- (NSUInteger) bucks;

// system
- (void) appDidEnterBackground;

// singleton
+(Player*) getInstance;
+(void) destroyInstance;

@end
