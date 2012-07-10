//
//  PogProfileAPI.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 4/15/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "PogProfileAPI.h"
#import "AFClientManager.h"
#import "DebugOptions.h"

// notifications
NSString* const kPogProfileNotificationDidNewUserLogin = @"PogProfileDidNewUserLogin";

// store value keys
static NSString* const kUUIDKey = @"UUID";

// server json keys
static NSString* const kServerUserIdKey = @"id";
static NSString* const kServerUuidKey = @"account[uuid]";
static NSString* const kServerEmailKey = @"account[email]";

// default user-id (will be removed after server connection is implemented)
static NSString* const kDefaultUserId = @"1435";
static NSString* const kDefaultUserEmail = @"peterpog@geolopigs.com";

@interface PogProfileAPI ()
{
    BOOL _hostReachable;
}
@property (nonatomic,assign) BOOL hostReachable;
- (void) handleNetworkReachabilityChanged:(AFNetworkReachabilityStatus) status;
@end

@implementation PogProfileAPI
@synthesize uuid = _uuid;
@synthesize userId = _userId;
@synthesize delegate = _delegate;
@synthesize hostReachable = _hostReachable;

- (id) init
{
    self = [super init];
    if(self)
    {
        // TODO: this needs fixing; it doesn't get re-registered when server ip gets reset
        [[[AFClientManager sharedInstance] pogProfile] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status){
            [self handleNetworkReachabilityChanged:status];
        }]; 
        // TODO
        
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        NSString* uuidString = [userDefaults objectForKey:kUUIDKey];
        if(uuidString)
        {
            // retrieve uuid from user defaults
            _uuid = [NSString stringWithString:uuidString];
        }
        else 
        {
            CFUUIDRef newUUID = CFUUIDCreate(NULL);
            CFStringRef newUUIDString = CFUUIDCreateString(NULL, newUUID);
            _uuid = [NSString stringWithFormat:@"%@", newUUIDString];
            CFRelease(newUUIDString);
            CFRelease(newUUID);
            
            // save new uuid into user defaults
            [userDefaults setObject:_uuid forKey:kUUIDKey];
        } 
        
        // not yet logged in
        _userId = nil;
        _delegate = nil;
    }
    return self;
}


- (void) newUserWithEmail:(NSString *)email
{
    if([[DebugOptions getInstance] useServer])
    {
        // post parameters
        NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                    _uuid, kServerUuidKey, 
                                    email, kServerEmailKey,
                                    nil];
        
        // make a post request
        AFHTTPClient* httpClient = [[AFClientManager sharedInstance] pogProfile];
        [httpClient postPath:@"accounts.json" 
                                            parameters:parameters
                                               success:^(AFHTTPRequestOperation *operation, id responseObject){
                                                   NSNumber* userIdNumeric = [responseObject valueForKeyPath:kServerUserIdKey];
                                                   _userId = [NSString stringWithFormat:@"%@", userIdNumeric];
                                                   NSLog(@"user id is %@", _userId);
                                                   
                                                   [self.delegate didCompleteAccountRegistrationForUserId:self.userId];
                                               }
                                               failure:^(AFHTTPRequestOperation* operation, NSError* error){
                                                   // HACK
                                                   // assign myself a default userid
                                                   _userId = kDefaultUserId;
                                                   NSLog(@"server connection failed %@, default user id is %@", error, _userId);
                                                   
                                                   // artificially wait 1 second before returning for dev purposes
                                                   dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.0f * NSEC_PER_SEC);
                                                   dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                                       [self.delegate didCompleteAccountRegistrationForUserId:self.userId];
                                                   });
                                                   // HACK
                                               }
         ];
    }
    else
    {
        // assign myself a default userid
        _userId = kDefaultUserId;
        
        // artificially wait 1 second before returning for dev purposes
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.0f * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self.delegate didCompleteAccountRegistrationForUserId:self.userId];
        });
    }
}

#pragma mark - internal methods
- (void) handleNetworkReachabilityChanged:(AFNetworkReachabilityStatus)status
{
    if((AFNetworkReachabilityStatusUnknown == status) || (AFNetworkReachabilityStatusNotReachable == status))
    {
        _hostReachable = NO;
        NSLog(@"host is not reachable");
    }
    else
    {
        NSLog(@"PogProfile server is alive!");
    }
}

#pragma mark - Singleton
static PogProfileAPI* singleton = nil;
+ (PogProfileAPI*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
            singleton = [[PogProfileAPI alloc] init];
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
