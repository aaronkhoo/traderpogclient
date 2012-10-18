//
//  ScanManager.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/19/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HiAccuracyLocatorDelegate.h"
#import "HttpCallbackDelegate.h"
#import "NPCTradePost.h"
#import <CoreLocation/CoreLocation.h>

typedef void (^ScanCompletionBlock)(BOOL finished, NSArray* tradePosts, CLLocation* loc);

@class HiAccuracyLocator;
@class MapControl;
@interface ScanManager : NSObject<HttpCallbackDelegate,HiAccuracyLocatorDelegate>
{
    unsigned int _state;
    HiAccuracyLocator* _locator;
}
@property (nonatomic) unsigned int state;
@property (nonatomic,readonly) HiAccuracyLocator* locator;

- (BOOL) locateAndScanInMap:(MapControl*)map completion:(ScanCompletionBlock)completion;
- (void) clearForQuitGame;
- (NPCTradePost*) generateSinglePostAtCoordAndAngle:(CLLocationCoordinate2D)scanCoord
                                           curAngle:(float)curAngle
                                           randFrac:(float)randFrac;

// singleton
+(ScanManager*) getInstance;
+(void) destroyInstance;

@end
