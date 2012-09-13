//
//  Flyer.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/21/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlyerInventory.h"
#import "FlyerPath.h"
#import "HttpCallbackDelegate.h"
#import "MapProtocols.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MKAnnotation.h>

static NSString* const kFlyer_CreateNewFlyer = @"Flyer_CreateNewFlyer";
static NSString* const kFlyer_CreateNewFlyerPath = @"Flyer_CreateNewFlyerPath";

enum _FlyerStates
{
    kFlyerStateIdle = 0,
    kFlyerStateEnroute,
    kFlyerStateWaitingToLoad,
    kFlyerStateLoading,
    kFlyerStateLoaded,
    kFlyerStateWaitingToUnload,
    kFlyerStateUnloading,
    kFlyerStateUnloaded,
    
    kFlyerStateNum
};

@class TradePost;
@class FlightPathOverlay;
@class TradeItemType;
@class FlyerAnnotationView;
@interface Flyer : NSObject<NSCoding, MKAnnotation, MapAnnotationProtocol>
{
    BOOL _initializeFlyerOnMap;
    NSInteger _flyerTypeIndex;
    NSString* _userFlyerId;
    CLLocationDistance _metersToDest;
    
    // this is only ever TRUE when this flyer has just been newly created
    // in all other cases (including when it is initWithDictionary, it is FALSE)
    BOOL _isNewFlyer;
    BOOL _isAtOwnPost;
    
    // flyer sim state
    unsigned int _state;
    NSDate* _stateBegin;
    
    FlyerInventory* _inventory;
    FlyerPath* _path;
    
    // transient variables (not saved; reconstructed after load)
    CLLocationCoordinate2D _coord;
    FlightPathOverlay* _flightPathRender;
    CGAffineTransform _transform;
    
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<HttpCallbackDelegate>* _delegate;
}
@property (nonatomic,readonly) NSString* userFlyerId;
@property (nonatomic,strong) FlightPathOverlay* flightPathRender;
@property (nonatomic) CLLocationCoordinate2D coord;
@property (nonatomic) CGAffineTransform transform;
@property (nonatomic) BOOL initializeFlyerOnMap;
@property (nonatomic,readonly) BOOL isNewFlyer;
@property (nonatomic) BOOL isAtOwnPost;
@property (nonatomic) unsigned int state;
@property (nonatomic,strong) NSDate* stateBegin;
@property (nonatomic) CLLocationDistance metersToDest;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegate;
@property (nonatomic,readonly) FlyerInventory* inventory;
@property (nonatomic,readonly) FlyerPath* path;

- (id) initWithPostAndFlyer:(TradePost*)tradePost, NSInteger flyerTypeIndex;
- (void) createNewUserFlyerOnServer;
- (id) initWithDictionary:(NSDictionary*)dict;
- (void) createFlightPathRenderingForFlyer;
- (void) initFlyerOnMap;
- (BOOL) departForPostId:(NSString *)postId;
- (void) updateAtDate:(NSDate *)currentTime;
- (NSTimeInterval) timeTillDest;

// map
- (void) refreshImageInAnnotationView:(FlyerAnnotationView*)annotationView;
- (UIImage*) imageForCurrentState;
@end
