//
//  FlyerTypes.h
//  traderpog
//
//  Created by Aaron Khoo on 7/25/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpCallbackDelegate.h"

static NSString* const kFlyerTypes_ReceiveFlyers = @"FlyerTypes_ReceiveFlyers";

@interface FlyerTypes : NSObject
{
    NSMutableArray* _flyerTypes;
    NSDate* _lastUpdate;
    
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<HttpCallbackDelegate>* _delegate;
}
@property (nonatomic,strong) NSMutableArray* flyerTypes;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegate;

// Public methods
- (BOOL) needsRefresh;
- (void) retrieveFlyersFromServer;

// Returns an array of FlyerType
- (NSArray*) getFlyersForTier:(unsigned int)tier;

// singleton
+(FlyerTypes*) getInstance;
+(void) destroyInstance;

@end