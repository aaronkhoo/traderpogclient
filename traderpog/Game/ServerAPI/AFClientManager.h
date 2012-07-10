//
//  AFClientManager.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 5/30/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "AFHTTPClient.h"

@class AFHTTPClient;
@interface AFClientManager : NSObject
{
    AFHTTPClient* _pogProfile;
    AFHTTPClient* _traderPog;
}
@property (nonatomic,readonly) AFHTTPClient* pogProfile;
@property (nonatomic,readonly) AFHTTPClient* traderPog;

- (void) resetPogProfileWithIp:(NSString*)serverIp;
- (void) resetTraderPogWithIp:(NSString*)serverIp;

// singelton
+ (AFClientManager*) sharedInstance;
+ (void) destroyInstance;

@end
