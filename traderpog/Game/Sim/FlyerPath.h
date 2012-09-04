//
//  FlyerPath.h
//  traderpog
//
//  Created by Aaron Khoo on 9/2/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import "TradePost.h"

@interface FlyerPath : NSObject<NSCoding>
{
    NSString* _flyerPathId;
    
    NSDate* _departureDate;
    
    NSString* _curPostId;
    NSString* _nextPostId;
    CLLocationCoordinate2D _srcCoord;
    CLLocationCoordinate2D _destCoord;
    
    CLLocationDistance _metersToDest;

    BOOL _doneWithCurrentPath;
}
@property (nonatomic,strong) NSString* curPostId;
@property (nonatomic,strong) NSString* nextPostId;
@property (nonatomic,strong) NSDate* departureDate;
@property (nonatomic) CLLocationCoordinate2D srcCoord;
@property (nonatomic) CLLocationCoordinate2D destCoord;
@property (nonatomic) BOOL updatingFlyerPathOnServer;
@property (nonatomic) BOOL doneWithCurrentPath;
@property (nonatomic) CLLocationDistance metersToDest;

- (id) initWithPost:(TradePost*)tradePost;
- (id) initWithDictionary:(NSDictionary*)dict;
- (void) initFlyerPathOnMap;

- (BOOL) departForPostId:(NSString *)postId userFlyerId:(NSString*)userFlyerId;
- (void) completeFlyerPath:(NSString*)userFlyerId;
- (BOOL) isEnrouteWhenLoaded;
- (BOOL) isEnroute;

@end
