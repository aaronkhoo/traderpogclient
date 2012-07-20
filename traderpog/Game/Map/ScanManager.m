//
//  ScanManager.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/19/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "ScanManager.h"
#import "HiAccuracyLocator.h"

enum kScanStates
{
    kScanStateIdle = 0,
    kScanStateLocating,
    kScanStateScanning,
    
    kScanStateNum
};

@interface ScanManager ()
{
    ScanCompletionBlock _completion;
}
- (void) startLocate;
- (void) startScan;
- (void) abortLocateScan;
@end

@implementation ScanManager
@synthesize state = _state;
@synthesize locator = _locator;

- (id) init
{
    self = [super init];
    if(self)
    {
        _state = kScanStateIdle;
        _locator = [[HiAccuracyLocator alloc] init];
        _locator.delegate = self;
        _completion = nil;
    }
    return self;
}

- (BOOL) locateAndScanWithCompletion:(ScanCompletionBlock)completion
{
    BOOL success = NO;
    
    if(kScanStateIdle == [self state])
    {
        _completion = completion;
        [self startLocate];
    }
    
    return success;
}

#pragma mark - scan state processing
- (void) startLocate
{
    [self.locator startUpdatingLocation];
    _state = kScanStateLocating;
}

- (void) startScan
{
    // TODO: ask TradePostMgr to scan
    NSLog(@"scanning...");
    _state = kScanStateScanning;
}

- (void) abortLocateScan
{
    _state = kScanStateIdle;
    if(_completion)
    {
        _completion(NO);
    }    
}

#pragma mark - HiAccuracyLocatorDelegate
- (void) locator:(HiAccuracyLocator *)locator didLocateUser:(BOOL)didLocateUser
{
    if(didLocateUser)
    {
        [self startScan];
    }
    else 
    {
        // location failed
        [self abortLocateScan];
    }
}

#pragma mark - Singleton
static ScanManager* singleton = nil;
+ (ScanManager*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
			singleton = [[ScanManager alloc] init];
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
