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
static NSString* const kPlayer_GetPlayerData = @"GetPlayerData";

@interface Player : NSObject<NSCoding, FBSessionDelegate>
{
    // internal
    NSString* _createdVersion;
    
    // User data
    NSInteger _id;
    BOOL _member;
    NSInteger _bucks;
    NSString* _secretkey;
    NSString* _facebookid;
    NSString* _email;
    NSString* _fbAccessToken;
    NSDate* _fbExpiration;
    
    NSDate* _lastUpdate;
    
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<HttpCallbackDelegate>* _delegate;
    
    Facebook* _facebook;
}
@property (nonatomic) NSInteger id;
@property (nonatomic) BOOL dataRefreshed;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegate;
@property (nonatomic, retain) Facebook *facebook;

- (void)initializeFacebook;
- (BOOL) needsRefresh;
- (void) createNewPlayerOnServer:(NSString*)facebookid;
- (void) getPlayerDataFromServer;

// system
- (void) appDidEnterBackground;

// singleton
+(Player*) getInstance;
+(void) destroyInstance;

@end
