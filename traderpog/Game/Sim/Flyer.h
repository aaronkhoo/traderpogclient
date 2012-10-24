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
extern NSString* const kKeyFlyerState;
extern NSString* const kKeyFlyerTypeId;

enum _FlyerStates
{
    kFlyerStateIdle = 0,
    kFlyerStateEnroute,
    kFlyerStateWaitingToLoad,
    kFlyerStateLoading,
    kFlyerStateLoaded,
    kFlyerStateWaitingToUnload,
    kFlyerStateUnloading,
    
    kFlyerStateNum,
    kFlyerStateInvalid
};

@class TradePost;
@class FlightPathOverlay;
@class TradeItemType;
@class FlyerAnnotationView;
@class GameEvent;
@class FlyerUpgradePack;
@interface Flyer : NSObject<NSCoding, MKAnnotation, MapAnnotationProtocol>
{
    BOOL _initializeFlyerOnMap;
    NSInteger _flyerTypeIndex;
    NSString* _userFlyerId;
    CLLocationDistance _metersToDest;
    
    // this is only ever TRUE when this flyer has just been newly created
    // in all other cases (including when it is initWithDictionary, it is FALSE)
    BOOL _isNewFlyer;

    // this is only ever TRUE when this flyer is created from FlyerBuy in the game
    BOOL _isNewlyPurchased;
    
    // flyer sim state
    unsigned int _state;
    NSDate* _stateBegin;
    
    FlyerInventory* _inventory;
    FlyerPath* _path;
    
    // FlyerLab beefs
    unsigned int _curUpgradeTier;   // starts at 0 (no upgrade)
    unsigned int _curColor;         // starts at 0
    
    // transient variables (not saved; reconstructed after load)
    CLLocationCoordinate2D _coord;
    FlightPathOverlay* _flightPathRender;
    GameEvent* _gameEvent;
    float _angle;   // the heading angle x-positive is 0, clockwise
    
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<HttpCallbackDelegate>* _delegate;
}
@property (nonatomic,readonly) NSInteger flyerTypeIndex;
@property (nonatomic,readonly) NSString* userFlyerId;
@property (nonatomic,strong) FlightPathOverlay* flightPathRender;
@property (nonatomic) CLLocationCoordinate2D coord;
@property (nonatomic) BOOL initializeFlyerOnMap;
@property (nonatomic,readonly) BOOL isNewFlyer;
@property (nonatomic,readonly) BOOL isNewlyPurchased;
@property (nonatomic) unsigned int state;
@property (nonatomic,strong) NSDate* stateBegin;
@property (nonatomic) CLLocationDistance metersToDest;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegate;
@property (nonatomic,readonly) FlyerInventory* inventory;
@property (nonatomic,readonly) FlyerPath* path;
@property (nonatomic,strong) GameEvent* gameEvent;
@property (nonatomic) float angle;

- (id) initWithPostAndFlyer:(TradePost*)tradePost, NSInteger flyerTypeIndex;
- (id) initWithPost:(TradePost *)tradePost flyerTypeIndex:(NSInteger)flyerTypeIndex isNewPurchase:(BOOL)isNewPurchase;
- (void) createNewUserFlyerOnServer;
- (id) initWithDictionary:(NSDictionary*)dict;
- (void) createFlightPathRenderingForFlyer;
- (void) initFlyerOnMap;
- (BOOL) departForPostId:(NSString *)postId;
- (void) updateAtDate:(NSDate *)currentTime;
- (NSTimeInterval) timeTillDest;
- (BOOL) gotoState:(unsigned int)newState;
- (float) getFlyerLoadDuration;
- (NSString*) displayNameOfFlyerState;
- (void) refreshIndexFromFlyerTypeId:(NSString*)flyerTypeId;

// flyer attributes
- (void) applyUpgradeTier:(unsigned int)tier;
- (NSInteger) getFlyerSpeed;
- (unsigned int) curUpgradeTier;
- (unsigned int) nextUpgradeTier;
- (void) applyColor:(unsigned int)colorIndex;
- (unsigned int) curColor;

// map
- (void) refreshImageInAnnotationView:(FlyerAnnotationView*)annotationView;
- (UIImage*) imageForCurrentState;
@end
