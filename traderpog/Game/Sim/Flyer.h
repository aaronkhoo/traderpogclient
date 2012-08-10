//
//  Flyer.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/21/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpCallbackDelegate.h"
#import "MapProtocols.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MKAnnotation.h>

static NSString* const kFlyer_CreateNewFlyer = @"Flyer_CreateNewFlyer";
static NSString* const kFlyer_CreateNewFlyerPath = @"Flyer_CreateNewFlyerPath";

@class TradePost;
@class FlightPathOverlay;
@interface Flyer : NSObject<MKAnnotation, MapAnnotationProtocol>
{
    BOOL _initializeFlyerOnMap;
    NSInteger _flyerTypeIndex;
    NSString* _userFlyerId;
    NSString* _flyerPathId;
    NSString* _curPostId;
    NSString* _nextPostId;

    // transient variables (not saved; reconstructed after load)
    CLLocationCoordinate2D _coord;
    FlightPathOverlay* _flightPathRender;
    CGAffineTransform _transform;
    
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<HttpCallbackDelegate>* _delegate;
}
@property (nonatomic,strong) NSString* curPostId;
@property (nonatomic,strong) NSString* nextPostId;
@property (nonatomic,strong) FlightPathOverlay* flightPathRender;
@property (nonatomic) CLLocationCoordinate2D coord;
@property (nonatomic) CGAffineTransform transform;
@property (nonatomic) BOOL initializeFlyerOnMap;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegate;

- (id) initWithPostAndFlyer:(TradePost*)tradePost, NSInteger flyerTypeIndex;
- (void) createNewUserFlyerOnServer;
- (BOOL) departForPostId:(NSString*)postId;
- (void) updateAtDate:(NSDate*)currentTime;
- (id) initWithDictionary:(NSDictionary*)dict;
- (CLLocationCoordinate2D) flyerCoordinateNow;
- (void) createRenderingForFlyer;

@end
