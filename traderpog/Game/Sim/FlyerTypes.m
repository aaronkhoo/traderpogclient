//
//  FlyerTypes.m
//  traderpog
//
//  Created by Aaron Khoo on 7/25/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerTypes.h"
#import "FlyerType.h"
#import "AFClientManager.h"

static double const refreshTime = -(60 * 15);

@implementation FlyerTypes
@synthesize delegate = _delegate;
@synthesize flyerTypes = _flyerTypes;

- (id) init
{
    self = [super init];
    if(self)
    {
        _lastUpdate = nil;
        _flyerTypes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (BOOL) needsRefresh
{
    return (!_lastUpdate) || ([_lastUpdate timeIntervalSinceNow] < refreshTime);
}

- (void) createFlyerArray:(id)responseObject
{
    for (NSDictionary* flyer in responseObject)
    {
        FlyerType* current = [[FlyerType alloc] initWithDictionary:flyer];
        [_flyerTypes addObject:current];
    }
}

- (void) retrieveFlyersFromServer
{    
    // make a post request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    [httpClient getPath:@"flyer_infos.json" 
             parameters:nil
                success:^(AFHTTPRequestOperation *operation, id responseObject){                     
                    NSLog(@"Retrieved: %@", responseObject);
                    [self createFlyerArray:responseObject];
                    _lastUpdate = [NSDate date];
                    [self.delegate didCompleteHttpCallback:kFlyerTypes_ReceiveFlyers, TRUE];
                }
                failure:^(AFHTTPRequestOperation* operation, NSError* error){
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                      message:@"Unable to create retrieve flyers. Please try again later."
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    
                    [message show];
                    [self.delegate didCompleteHttpCallback:kFlyerTypes_ReceiveFlyers, FALSE];
                }
     ];
}

- (NSArray*) getFlyersForTier:(unsigned int)tier
{
    NSMutableArray* flyerArray = [[NSMutableArray alloc] init];
    for (FlyerType* flyer in _flyerTypes)
    {
        if ([flyer tier] == tier)
        {
            [flyerArray addObject:flyer];
        }
    }
    return (NSArray*)flyerArray;
}

#pragma mark - Singleton
static FlyerTypes* singleton = nil;
+ (FlyerTypes*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
            singleton = [[FlyerTypes alloc] init];
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
