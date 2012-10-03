//
//  PlayerSales.h
//  traderpog
//
//  Created by Aaron Khoo on 10/2/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpCallbackDelegate.h"

static NSString* const kPlayerSales_ReceiveSales = @"PlayerSales_ReceiveSales";

@interface PlayerSales : NSObject<NSCoding>
{    
    NSDate* _lastUpdate;
    
    BOOL _hasSales;
    NSUInteger _bucks;
    NSMutableArray* _fbidArray;
    NSUInteger _nonNamedCount;
    
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<HttpCallbackDelegate>* _delegate;
}
@property (nonatomic) BOOL hasSales;
@property (nonatomic) NSUInteger bucks;
@property (nonatomic, strong) NSMutableArray* fbidArray;
@property (nonatomic) NSUInteger nonNamedCount;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegate;

- (BOOL) needsRefresh;
- (void) retrieveSalesFromServer;
- (void) resolveSales;

// singleton
+(PlayerSales*) getInstance;
+(void) destroyInstance;

@end
