//
//  AFClientManager.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 5/30/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <SystemConfiguration/SystemConfiguration.h>
#import "AFClientManager.h"
#import "AFJSONRequestOperation.h"

static NSString* const kPogProfileBaseURLString = @"10.0.1.12";
static NSString* const kTraderPogBaseURLString = @"strong-rain-5460.herokuapp.com";
static NSString* const kPogProfilePort = @"3000";
static NSString* const kTraderPogPort = @"80";

@implementation AFClientManager
@synthesize pogProfile = _pogProfile;
@synthesize traderPog = _traderPog;

- (id) init
{
    self = [super init];
    if(self)
    {
        _pogProfile = nil;
        _traderPog = nil;
        
        [self resetPogProfileWithIp:kPogProfileBaseURLString];
        [self resetTraderPogWithIp:kTraderPogBaseURLString];
    }
    return self;
}

- (void) dealloc
{
    [_traderPog unregisterHTTPOperationClass:[AFJSONRequestOperation class]];
    [_pogProfile unregisterHTTPOperationClass:[AFJSONRequestOperation class]];
}

- (void) resetPogProfileWithIp:(NSString *)serverIp
{
    if(_pogProfile)
    {
        [_pogProfile unregisterHTTPOperationClass:[AFJSONRequestOperation class]];
    }
    NSString* urlString = [NSString stringWithFormat:@"http://%@:%@/", serverIp, kPogProfilePort];
    NSLog(@"pogprofile client reset with server ip %@", urlString);    

    _pogProfile = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:urlString]];
    [_pogProfile registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    //  Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
    [_pogProfile setDefaultHeader:@"Accept" value:@"application/json"];
}

- (void) resetTraderPogWithIp:(NSString *)serverIp
{
    if(_traderPog)
    {
        [_traderPog unregisterHTTPOperationClass:[AFJSONRequestOperation class]];
    }
    NSString* urlString = [NSString stringWithFormat:@"http://%@:%@/", serverIp, kTraderPogPort];
    NSLog(@"traderpog client reset with server ip %@", urlString);    
    
    _traderPog = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:urlString]];
    [_traderPog registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    //  Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
    [_traderPog setDefaultHeader:@"Accept" value:@"application/json"];
    
    // Encode parameters in JSON format
    _traderPog.parameterEncoding = AFJSONParameterEncoding;
}

#pragma mark - singleton
static AFClientManager* _sharedInstance = nil;
+ (AFClientManager*)sharedInstance
{
	@synchronized(self)
	{
		if (!_sharedInstance)
		{
			_sharedInstance = [[AFClientManager alloc] init];
		}
        return _sharedInstance;
	}
}

+ (void) destroyInstance
{
    @synchronized(self)
    {
        _sharedInstance = nil;
    }
}

@end
