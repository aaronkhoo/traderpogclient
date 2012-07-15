//
//  Player.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HttpCallbackDelegate.h"

@interface Player : NSObject<NSCoding>
{
    // internal
    NSString* _createdVersion;
    
    // id
    NSString* _userId;
    
    // User data
    NSInteger _id;
    BOOL _member;
    NSInteger _bucks;
    NSString* _secretkey;
    NSString* _facebookid;
    NSString* _email;
    
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<HttpCallbackDelegate>* _delegate;
}
@property (nonatomic) NSInteger id;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegate;

- (void) createNewPlayerOnServer:(NSString*)facebookid;

// system
- (void) appDidEnterBackground;

// singleton
+(Player*) getInstance;
+(void) destroyInstance;

@end
