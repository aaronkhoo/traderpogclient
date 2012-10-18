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

static NSString* const kFlyerTypes_ReceiveFlyers = @"FlyerTypes_ReceiveFlyers";

@interface FlyerTypes : NSObject<NSCoding>
{    
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<HttpCallbackDelegate>* _delegate;
}
@property (nonatomic,strong) NSMutableArray* flyerTypes;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegate;

// Public methods
- (BOOL) needsRefresh:(NSDate*) lastModifiedDate;
- (void) retrieveFlyersFromServer;

- (FlyerType*) getFlyerTypeById:(NSString*)flyerId;
- (NSInteger) getFlyerIndexById:(NSString*)flyerId;

// Returns an array of FlyerType
- (NSArray*) getFlyersForTier:(unsigned int)tier;

// returns a type-name that can be used to lookup flyer info from flyerlab.plist
- (NSString*) getFlyerLabNameForFlyerTypeIndex:(NSInteger)flyerTypeIndex;

// singleton
+(FlyerTypes*) getInstance;
+(void) destroyInstance;

@end
