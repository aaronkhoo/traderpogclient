//
//  ScanManager.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/19/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HiAccuracyLocatorDelegate.h"

typedef void (^ScanCompletionBlock)(BOOL finished, NSArray* tradePosts);

@class HiAccuracyLocator;
@class MapControl;
@interface ScanManager : NSObject<HiAccuracyLocatorDelegate>
{
    unsigned int _state;
    HiAccuracyLocator* _locator;
}
@property (nonatomic) unsigned int state;
@property (nonatomic,readonly) HiAccuracyLocator* locator;

- (BOOL) locateAndScanInMap:(MapControl*)map completion:(ScanCompletionBlock)completion;

// singleton
+(ScanManager*) getInstance;
+(void) destroyInstance;

@end
