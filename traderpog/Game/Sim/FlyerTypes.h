//
//  FlyerTypes.h
//  traderpog
//
//  Created by Aaron Khoo on 7/25/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerType.h"
#import <Foundation/Foundation.h>
#import "HttpCallbackDelegate.h"

// HACK (dev only; DO NOT SHIP)
// uncomment this to use local fallback flyer types
//#define USE_FALLBACKS (1)
// HACK

static NSString* const kFlyerTypes_ReceiveFlyers = @"FlyerTypes_ReceiveFlyers";

@interface FlyerTypes : NSObject<NSCoding>
{    
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<HttpCallbackDelegate>* _delegate;
}
@property (nonatomic,strong) NSMutableArray* flyerTypes;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegate;
@property (nonatomic,readonly) NSDate* lastUpdate;

// Public methods
- (BOOL) needsRefresh:(NSDate*) lastModifiedDate;
- (void) retrieveFlyersFromServer;
- (NSInteger) numFlyerTypes;

- (FlyerType*) getFlyerTypeById:(NSString*)flyerId;
- (NSInteger) getFlyerIndexById:(NSString*)flyerId;
- (FlyerType*) getFlyerTypeAtIndex:(NSInteger)index;
- (NSString*) sideImgForFlyerTypeAtIndex:(NSInteger)index;
- (NSString*) topImgForFlyerTypeAtIndex:(NSInteger)index;

// Returns an array of FlyerType
- (NSArray*) getFlyersForTier:(unsigned int)tier;

// singleton
+(FlyerTypes*) getInstance;
+(void) destroyInstance;

@end
