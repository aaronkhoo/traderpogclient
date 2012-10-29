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

#if defined(FINAL) || defined(USE_PRODUCTION_SERVER)
static NSString* const kTraderPogBaseURLString = @"safe-chamber-1004.herokuapp.com";
static NSString* const kTraderPogPort = @"443";
#else
static NSString* const kTraderPogBaseURLString = @"strong-rain-5460.herokuapp.com";
static NSString* const kTraderPogPort = @"80";
#endif


@implementation AFClientManager
@synthesize traderPog = _traderPog;

- (id) init
{
    self = [super init];
    if(self)
    {
        _traderPog = nil;
        
        [self resetTraderPogWithIp:kTraderPogBaseURLString];
    }
    return self;
}

- (void) dealloc
{
    [_traderPog unregisterHTTPOperationClass:[AFJSONRequestOperation class]];
}

- (NSString*) getTraderPogURL
{
    return [NSString stringWithFormat:@"%@", kTraderPogBaseURLString];
}

- (void) resetTraderPogWithIp:(NSString *)serverIp
{
    if(_traderPog)
    {
        [_traderPog unregisterHTTPOperationClass:[AFJSONRequestOperation class]];
    }

#if defined(FINAL) || defined(USE_PRODUCTION_SERVER)
    NSString* urlString = [NSString stringWithFormat:@"https://%@:%@/", serverIp, kTraderPogPort];
#else
    NSString* urlString = [NSString stringWithFormat:@"http://%@:%@/", serverIp, kTraderPogPort];
#endif
    NSLog(@"traderpog client reset with server ip %@", urlString);
    
    _traderPog = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:urlString]];
    [_traderPog registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    //  Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
    [_traderPog setDefaultHeader:@"Accept" value:@"application/json"];
    [_traderPog setDefaultHeader:@"expected-traderpog-version" value:@"1.0"];
    
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
