//
//  Player.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FBConnect.h"
#import "HttpCallbackDelegate.h"
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

static NSString* const kPlayer_CreateNewUser = @"CreateNewUser";
static NSString* const kPlayer_SavePlayerData = @"SavePlayerData";
static NSString* const kPlayer_UpdateMember = @"UpdateMember";
static NSString* const kPlayer_GetPlayerData = @"GetPlayerData";
static NSString* const kPlayer_GetPlayerDataWithFacebook = @"GetPlayerDataWithFacebook";

@interface Player : NSObject<NSCoding, FBSessionDelegate, FBRequestDelegate, UIAlertViewDelegate>
{
    // internal
    NSString* _createdVersion;
    
    // User data
    NSInteger _playerId;
    NSDate* _memberTime;
    NSUInteger _bucks;
    NSString* _secretkey;
    NSString* _facebookid;
    NSString* _email;
    NSString* _fbAccessToken;
    NSDate* _fbExpiration;
    NSMutableDictionary* _fbFriends;
    NSString* _fbname;
    
    NSDate* _lastUpdate;
    NSDate* _fbPostUpdate;
    
    // Start of week date for reseting money count
    NSDate* _currentWeekOf;
    
    BOOL _lastKnownLocationValid;
    CLLocationCoordinate2D _lastKnownLocation;
    
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<HttpCallbackDelegate>* _delegate;
    
    // Delegate for callbacks to inform interested parties of member upgrade completion
    __weak NSObject<HttpCallbackDelegate>* _memberDelegate;
    
    Facebook* _facebook;
}
@property (nonatomic) NSInteger playerId;
@property (nonatomic) BOOL dataRefreshed;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegate;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* memberDelegate;
@property (nonatomic, retain) Facebook *facebook;
@property (nonatomic) BOOL lastKnownLocationValid;
@property (nonatomic) CLLocationCoordinate2D lastKnownLocation;
@property (nonatomic,strong) NSString* fbname;
@property (nonatomic, strong) NSString* fbid;

- (void)initializeFacebook;
- (void)authorizeFacebook;
- (void)savePlayerData;
- (BOOL)needsRefresh;
- (void)createNewPlayerOnServer;
- (void)getPlayerDataFromServer;
- (void)updateMembershipInfo:(NSString*)receipt;
- (BOOL)facebookSessionValid;
- (void)getFacebookFriendsList;
- (void)updateFacebookFeed:(NSString*)message;
- (BOOL)isFacebookConnected;
- (NSString*)getFacebookNameByFbid:(NSString*)fbid;
- (BOOL)isMember;

// trade
- (void) addBucks:(NSUInteger)newBucks;
- (void) deductBucks:(NSUInteger)bucksToSub;
- (void) setBucks:(NSUInteger)newBucks;
- (NSUInteger) bucks;
- (void) resetBucksIfNecessary;

// system
- (void) appDidEnterBackground;
- (void) removePlayerData;

// singleton
+(Player*) getInstance;
+(void) destroyInstance;

@end
