//
//  AsyncHttpCallMgr.m
//  traderpog
//
//  Created by Aaron Khoo on 8/28/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AFClientManager.h"
#import "AsyncHttpCallMgr.h"

static int const maxRetry = 10;

@interface AsyncHttpCallMgr ()
{
    NSMutableArray* _callArray;
    NSCondition* _lock;
    BOOL _callsInProgress;
}
@end

@implementation AsyncHttpCallMgr
@synthesize delegate = _delegate;

- (id) init
{
    self = [super init];
    if(self)
    {
        _callArray = [[NSMutableArray alloc] init];
        _lock = [[NSCondition alloc] init];
        _callsInProgress = FALSE;
    }
    return self;
}

- (void) push:(AsyncHttpCall*) newCall
{
    @synchronized(self)
    {
        [_callArray addObject:newCall];   
    }
}

- (void) pop
{
    @synchronized(self)
    {
        [_callArray removeObjectAtIndex:0];
    }
}

- (void) makeAsyncHttpCall
{    
    AsyncHttpCall* nextCall = (AsyncHttpCall*)[_callArray objectAtIndex:0];
    
    if (nextCall.type == putType || nextCall.type == postType)
    {
        AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
        
        // Set the headers
        NSDictionary* headers = [nextCall headers];
        for (id key in headers)
        {
            [httpClient setDefaultHeader:(NSString*)key value:(NSString*)[headers objectForKey:key]];
        }
        
        // Make the call
        if (nextCall.type == putType)
        {
            // make a post request            
            [httpClient putPath:[nextCall path]
                     parameters:[nextCall parameters]
                        success:^(AFHTTPRequestOperation *operation, id responseObject){
                            NSLog(@"postPath call succeeded in AsyncHttpCallMgr");
                            [self pop];
                            [self.delegate didCompleteAsyncHttpCallback:TRUE];
                        }
                        failure:^(AFHTTPRequestOperation* operation, NSError* error){
                            NSLog(@"postPath call failed in AsyncHttpCallMgr");
                            nextCall.numTries++;
                            if ([nextCall numTries] >= maxRetry)
                            {
                                [self pop];
                            }
                            [self.delegate didCompleteAsyncHttpCallback:FALSE];
                        }
             ];
        }
        else if (nextCall.type == postType)
        {
            // make a post request
            [httpClient postPath:[nextCall path]
                     parameters:[nextCall parameters]
                        success:^(AFHTTPRequestOperation *operation, id responseObject){
                            NSLog(@"postPath call succeeded in AsyncHttpCallMgr");
                            [self pop];
                            [self.delegate didCompleteAsyncHttpCallback:TRUE];
                        }
                        failure:^(AFHTTPRequestOperation* operation, NSError* error){
                            NSLog(@"postPath call failed in AsyncHttpCallMgr");
                            nextCall.numTries++;
                            if ([nextCall numTries] >= maxRetry)
                            {
                                [self pop];
                            }
                            [self.delegate didCompleteAsyncHttpCallback:FALSE];
                        }
             ];
        }
        
        // Reset the headers
        for (id key in headers)
        {
            [httpClient setDefaultHeader:(NSString*)key value:nil];
        }
    }
    else
    {
        NSLog(@"Unknown http call type in makeAsyncHttpCall for AsyncHttpCallMgr class");
        [self pop];
    }
}

- (void) newAsyncHttpCall:(NSString*)path
           current_params:(NSDictionary*)params
          current_headers:(NSDictionary*)headers
              current_msg:(NSString*)msg
             current_type:(httpCallType)type
{
    AsyncHttpCall* newCall = [[AsyncHttpCall alloc] initWithValues:path
                                                    current_params:params
                                                   current_headers:headers
                                                       current_msg:msg
                                                      current_type:type];
    [self push:newCall];
    
    [self startCalls];
}

- (void) startCalls
{
    BOOL startCall = FALSE;
    
    [_lock lock];
    if (!_callsInProgress && [_callArray count] > 0)
    {
        _callsInProgress = TRUE;
        startCall = TRUE;
    }
    [_lock unlock];
    
    if (startCall)
    {
        [self makeAsyncHttpCall];
    }
}

#pragma mark - HttpCallbackDelegate
- (void) didCompleteAsyncHttpCallback:(BOOL)success
{
    if (success && [_callArray count] > 0)
    {
        [self makeAsyncHttpCall];
    }
    else
    {
        [_lock lock];
        _callsInProgress = FALSE;
        [_lock unlock];
    }
}

#pragma mark - Singleton
static AsyncHttpCallMgr* singleton = nil;
+ (AsyncHttpCallMgr*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
            // First, try to load the AsyncHttpCallMgr data from disk
            //singleton = [AsyncHttpCallMgr loadCachedAsyncHttpCallData];
            if (!singleton)
            {
                // OK, no saved data available. Go ahead and create a new AsyncHttpCallMgr instance.
                singleton = [[AsyncHttpCallMgr alloc] init];
            }
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
