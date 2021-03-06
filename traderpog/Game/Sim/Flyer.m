//
//  Flyer.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/21/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AFClientManager.h"
#import "AsyncHttpCallMgr.h"
#import "BeaconMgr.h"
#import "Flyer.h"
#import "FlyerType.h"
#import "FlyerTypes.h"
#import "FlyerLabFactory.h"
#import "FlyerUpgradePack.h"
#import "FlightPathOverlay.h"
#import "FlyerAnnotationView.h"
#import "GameManager.h"
#import "MetricLogger.h"
#import "NPCTradePost.h"
#import "TradePostMgr.h"
#import "Player.h"
#import "MKMapView+Pog.h"
#import "MKMapView+Game.h"
#import "TradeManager.h"
#import "ImageManager.h"
#import "GameNotes.h"
#import "DebugOptions.h"
#import "GameEventMgr.h"
#import "NSDictionary+Pog.h"
#import "SoundManager.h"
#import "ScanManager.h"
#include "MathUtils.h"

static NSString* const kKeyUserFlyerId = @"id";
static NSString* const kKeyFlyerId = @"flyer_info_id";
NSString* const kKeyFlyerTypeId = @"flyer_info_id";
static NSString* const kKeyFlyerTypeIndex = @"flyer_type_index";
static NSString* const kKeyVersion = @"version";
static NSString* const kKeyInventory = @"inventory";
static NSString* const kKeyPath = @"path";
NSString* const kKeyFlyerState = @"state";
static NSString* const kKeyStateBegin = @"stateBegin";
static NSString* const kKeyCurUpgradeTier = @"level";
static NSString* const kKeyCurColorIndex = @"colorindex";

@interface Flyer ()
{
    // internal
    NSString* _createdVersion;
    
    // last time a load-timer-changed notification was fired
    NSDate* _lastLoadTimerChanged;
}
- (CLLocationCoordinate2D) flyerCoordinateAtTimeSinceDeparture:(NSTimeInterval)elapsed;
- (CLLocationCoordinate2D) flyerCoordinateAtTimeAhead:(NSTimeInterval)timeAhead;
- (NSString*) nameOfFlyerState:(unsigned int)queryState;
@end

@implementation Flyer
@synthesize flyerTypeIndex = _flyerTypeIndex;
@synthesize userFlyerId = _userFlyerId;
@synthesize flightPathRender = _flightPathRender;
@synthesize coord = _coord;
@synthesize isNewFlyer = _isNewFlyer;
@synthesize isNewlyPurchased = _isNewlyPurchased;
@synthesize state = _state;
@synthesize stateBegin = _stateBegin;
@synthesize delegate = _delegate;
@synthesize initializeFlyerOnMap = _initializeFlyerOnMap;
@synthesize metersToDest = _metersToDest;
@synthesize inventory = _inventory;
@synthesize path = _path;
@synthesize gameEvent = _gameEvent;
@synthesize angle = _angle;

- (void) internalInitAtPost:(TradePost*)tradePost flyerTypeIndex:(NSInteger)flyerTypeIndex isNewPurchase:(BOOL)isNewPurchase
{
    _initializeFlyerOnMap = FALSE;
    
    _flyerTypeIndex = flyerTypeIndex;
    
    _metersToDest = 0.0;
    
    // init transient variables
    _coord = [tradePost coord];
    _flightPathRender = nil;
    _gameEvent = nil;
    _angle = 0.0f;
    
    // this flyer is newly created (see Flyer.h for more details)
    _isNewFlyer = YES;
    _isNewlyPurchased = isNewPurchase;
    
    _state = kFlyerStateInvalid;
    _stateBegin = nil;
    
    _inventory = [[FlyerInventory alloc] init];
    _path = [[FlyerPath alloc] initWithPost:tradePost];
    _curUpgradeTier = 0;
    _curColor = 0;
}

- (id) initWithPost:(TradePost *)tradePost flyerTypeIndex:(NSInteger)flyerTypeIndex isNewPurchase:(BOOL)isNewPurchase
{
    self = [super init];
    if(self)
    {
        [self internalInitAtPost:tradePost flyerTypeIndex:flyerTypeIndex isNewPurchase:isNewPurchase];
    }
    return self;
}

- (id) initWithPostAndFlyer:(TradePost*)tradePost, NSInteger flyerTypeIndex
{
    self = [super init];
    if(self)
    {
        [self internalInitAtPost:tradePost flyerTypeIndex:flyerTypeIndex isNewPurchase:NO];
    }
    return self;
}

- (id) initWithDictionary:(NSDictionary*)dict
{
    self = [super init];
    if(self)
    {
        _initializeFlyerOnMap = FALSE;
        
        _userFlyerId = [NSString stringWithFormat:@"%d", [[dict valueForKeyPath:kKeyUserFlyerId] integerValue]];
        NSString* flyerTypeId = [NSString stringWithFormat:@"%d", [[dict valueForKeyPath:kKeyFlyerId] integerValue]];
        _flyerTypeIndex = [[FlyerTypes getInstance] getFlyerIndexById:flyerTypeId];
        
        NSArray* paths_array = [dict valueForKeyPath:@"flyer_paths"];
        NSDictionary* path_dict = [paths_array objectAtIndex:0];
        
        id stateObj = [dict valueForKeyPath:kKeyFlyerState];
        if(([NSNull null] == stateObj) || (!stateObj))
        {
            _state = kFlyerStateInvalid;
        }
        else
        {
            _state = [stateObj unsignedIntValue];
        }
        id stateBeginObj = [dict valueForKeyPath:kKeyStateBegin];
        if(([NSNull null] == stateBeginObj) || (!stateBeginObj))
        {
            _stateBegin = nil;
        }
        else
        {
            _stateBegin = stateBeginObj;
        }
        
        // Initialize inventory
        _inventory = [[FlyerInventory alloc] initWithDictionary:dict];
        
        // Initialize path
        _path = [[FlyerPath alloc] initWithDictionary:path_dict];

        id obj = [dict valueForKeyPath:kKeyCurUpgradeTier];
        if(([NSNull null] == obj) || (!obj))
        {
            _curUpgradeTier = 0;
        }
        else
        {
            _curUpgradeTier = [obj unsignedIntValue];
        }
        obj = [dict valueForKeyPath:kKeyCurColorIndex];
        if(([NSNull null] == obj) || (!obj))
        {
            _curColor = 0;
        }
        else
        {
            _curColor = [obj unsignedIntValue];
        }
        
        // init runtime transient vars
        _coord = _path.srcCoord;
        _flightPathRender = nil;
        _gameEvent = nil;
        _angle = 0.0f;
        
        // this flyer is loaded (see Flyer.h for more details)
        _isNewFlyer = NO;
        _isNewlyPurchased = NO;
        
        _metersToDest = 0.0;
    }
    return self;
}

#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_createdVersion forKey:kKeyVersion];
    [aCoder encodeInteger:_flyerTypeIndex forKey:kKeyFlyerTypeIndex];
    [aCoder encodeObject:_userFlyerId forKey:kKeyUserFlyerId];
    
    [aCoder encodeObject:_inventory forKey:kKeyInventory];
    [aCoder encodeObject:_path forKey:kKeyPath];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInt:_curUpgradeTier] forKey:kKeyCurUpgradeTier];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInt:_curColor] forKey:kKeyCurColorIndex];
    
    [aCoder encodeObject:[NSNumber numberWithUnsignedInt:_state] forKey:kKeyFlyerState];
    [aCoder encodeObject:_stateBegin forKey:kKeyStateBegin];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _createdVersion = [aDecoder decodeObjectForKey:kKeyVersion];
    _flyerTypeIndex = [aDecoder decodeIntegerForKey:kKeyFlyerTypeIndex];
    _userFlyerId = [aDecoder decodeObjectForKey:kKeyUserFlyerId];
    _inventory = [aDecoder decodeObjectForKey:kKeyInventory];
    _path = [aDecoder decodeObjectForKey:kKeyPath];
    NSNumber* curUpgradeObj = [aDecoder decodeObjectForKey:kKeyCurUpgradeTier];
    if(curUpgradeObj)
    {
        _curUpgradeTier = [curUpgradeObj unsignedIntValue];
    }
    else
    {
        _curUpgradeTier = 0;
    }
    NSNumber* curColorObj = [aDecoder decodeObjectForKey:kKeyCurColorIndex];
    if(curColorObj)
    {
        _curColor = [curColorObj unsignedIntValue];
    }
    else
    {
        _curColor = 0;
    }
    
    NSNumber* stateObj = [aDecoder decodeObjectForKey:kKeyFlyerState];
    if(stateObj)
    {
        _state = [stateObj unsignedIntValue];
    }
    else
    {
        _state = kFlyerStateIdle;
    }
    _stateBegin = [aDecoder decodeObjectForKey:kKeyStateBegin];
    
    _initializeFlyerOnMap = FALSE;
    _metersToDest = 0.0;
    
    // init runtime transient vars
    _coord = _path.srcCoord;
    _flightPathRender = nil;
    _gameEvent = nil;
    _angle = 0.0f;
    
    // this flyer is loaded (see Flyer.h for more details)
    _isNewFlyer = NO;
    _isNewlyPurchased = NO;
    
    return self;
}

- (float) getFlyerLoadDuration
{
    FlyerType* current = [[[FlyerTypes getInstance] flyerTypes] objectAtIndex:_flyerTypeIndex];
    return (float)([current loadtime]);
}

- (void) updateUserFlyer:(NSDictionary*)parameters
{
    NSString *setdoneUrl = [NSString stringWithFormat:@"users/%d/user_flyers/%@", [[Player getInstance] playerId], _userFlyerId];
    NSString* msg = [[NSString alloc] initWithFormat:@"Updating user flyer %@ failed", _userFlyerId];
    [[AsyncHttpCallMgr getInstance] newAsyncHttpCall:setdoneUrl
                                      current_params:parameters
                                     current_headers:nil
                                         current_msg:msg
                                        current_type:putType];
}


- (void)updateUserFlyerUpgradeTier
{
    NSMutableDictionary* parameters = [NSMutableDictionary dictionaryWithCapacity:1];
    [parameters setValue:[NSNumber numberWithUnsignedInt:_curUpgradeTier] forKey:kKeyCurUpgradeTier];
    [self updateUserFlyer:parameters];
}

- (void)updateUserFlyerColorindex
{
    NSMutableDictionary* parameters = [NSMutableDictionary dictionaryWithCapacity:1];
    [parameters setValue:[NSNumber numberWithUnsignedInt:_curColor] forKey:kKeyCurColorIndex];
    [self updateUserFlyer:parameters];
}

- (void) createNewUserFlyerOnServer
{
    // post parameters
    NSString *userFlyerPath = [NSString stringWithFormat:@"users/%d/user_flyers", [[Player getInstance] playerId]];
    FlyerType* current  = [[[FlyerTypes getInstance] flyerTypes] objectAtIndex:_flyerTypeIndex];
    NSString* flyerId = [current flyerId];
    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                flyerId, kKeyFlyerId,
                                nil];
    
    // make a post request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    [httpClient setDefaultHeader:@"Init-Post-Id" value:[_path curPostId]];
    [httpClient postPath:userFlyerPath
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject){
                     _userFlyerId = [NSString stringWithFormat:@"%d", [[responseObject valueForKeyPath:kKeyUserFlyerId] integerValue]];
                     [self.delegate didCompleteHttpCallback:kFlyer_CreateNewFlyer, TRUE];
                 }
                 failure:^(AFHTTPRequestOperation* operation, NSError* error){
                     UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                       message:@"Unable to create flyer. Please try again later."
                                                                      delegate:nil
                                                             cancelButtonTitle:@"OK"
                                                             otherButtonTitles:nil];
                     
                     [message show];
                     [self.delegate didCompleteHttpCallback:kFlyer_CreateNewFlyer, FALSE];
                 }
     ];
    [httpClient setDefaultHeader:@"Init-Post-Id" value:nil];
}

// Create flight-path rendering for flyer
- (void) createFlightPathRenderingForFlyer
{    
    // create renderer
    if ([_path curPostId])
    {
        // If a current post is specified, then use that post's coordinates.
        // Otherwise, the srcCoords are already specified. This happens when the source post is
        // an NPC post that isn't stored on the server.
        TradePost* post = [[TradePostMgr getInstance] getTradePostWithId:[_path curPostId]];
        _path.srcCoord = [post coord];
    }
    if ([_path nextPostId])
    {
        // Same as above
        TradePost* post = [[TradePostMgr getInstance] getTradePostWithId:[_path nextPostId]];
        _path.destCoord = [post coord];
    }
    
    self.flightPathRender = [[FlightPathOverlay alloc] initWithSrcCoord:[_path srcCoord] destCoord:[_path destCoord]];
    
    float angle = [MKMapView angleBetweenCoordinateA:[_path srcCoord] coordinateB:[_path destCoord]];
    [self setAngle:angle];
}

- (void) refreshIndexFromFlyerTypeId:(NSString*)flyerTypeId
{
    _flyerTypeIndex = [[FlyerTypes getInstance] getFlyerIndexById:flyerTypeId];
}


#pragma mark - flyer attributes
- (void) applyUpgradeTier:(unsigned int)tier
{
    unsigned int newTier = MIN(tier, [[FlyerLabFactory getInstance] maxUpgradeTier]);
    _curUpgradeTier = newTier;
    [self updateUserFlyerUpgradeTier];
    [[NSNotificationCenter defaultCenter] postNotificationName:kGameNoteFlyerStateChanged object:self];

    NSLog(@"Flyer Upgraded to Tier %d", newTier);
}

- (NSInteger) getFlyerSpeed
{
    FlyerType* current  = [[[FlyerTypes getInstance] flyerTypes] objectAtIndex:_flyerTypeIndex];
    NSInteger speed = [current speed];
    
    if(_curUpgradeTier)
    {
        FlyerUpgradePack* upgrade = [[FlyerLabFactory getInstance] upgradeForTier:_curUpgradeTier];
        float fSpeed = ((float)speed) * [upgrade speedFactor];
        speed = (unsigned int)fSpeed;
    }
    
    if([[DebugOptions getInstance] speed100x])
    {
        speed *= 2000;
    }
    
    return speed;
}

- (unsigned int) curUpgradeTier
{
    return _curUpgradeTier;
}

- (unsigned int) nextUpgradeTier
{
    unsigned int result = [[FlyerLabFactory getInstance] nextUpgradeTierForTier:_curUpgradeTier];
    return result;
}

- (void) applyColor:(unsigned int)colorIndex
{
    _curColor = MIN(colorIndex, [[FlyerLabFactory getInstance] maxColorIndex]);
    [self updateUserFlyerColorindex];
    [[NSNotificationCenter defaultCenter] postNotificationName:kGameNoteFlyerStateChanged object:self];
}

- (unsigned int) curColor
{
    return _curColor;
}

- (unsigned int) remainingCapacity
{
    unsigned int totalNum = [self.inventory numItems] + [self.inventory orderNumItems];
    FlyerUpgradePack* upgrade = [[FlyerLabFactory getInstance] upgradeForTier:[self curUpgradeTier]];
    FlyerType* flyerType = [[FlyerTypes getInstance] getFlyerTypeAtIndex:[self flyerTypeIndex]];
    unsigned int cap = ((float)[flyerType capacity]) * [upgrade capacityFactor];
    unsigned int result = 0;
    if(totalNum < cap)
    {
        result = cap - totalNum;
    }
    return result;
}

#pragma mark - flight public

// called for restored flyers when game reboots
- (void) initFlyerOnMap
{
    [_path initFlyerPathOnMap];
    if(![self initializeFlyerOnMap])
    {
        // init flight-state with all necessary info in place
        // Flyer initWithDictionary may get called prior to TradePostMgr receiving its server data;
        // so, this code here ensures dependent data (like coords that depend on postIds) are correctly setup
        if (_path.doneWithCurrentPath)
        {
            TradePost* curPost = [[TradePostMgr getInstance] getTradePostWithId:_path.curPostId];
            if([curPost flyerAtPost] ||
               (([curPost isMemberOfClass:[MyTradePost class]]) &&
                ([self.inventory numItems])))
            {
                // if current post already has a flyer, OR
                // if my path is done at MyPost, but I still have items on my flyer for some reason,
                // create an npc post near it and put me there
                float curAngle = RandomFrac() * 2.0f * M_PI;
                float randFrac = RandomFrac();
                NPCTradePost* newPost = [[ScanManager getInstance] generateSinglePostAtCoordAndAngle:[curPost coord]
                                                                                            curAngle:curAngle
                                                                                            randFrac:randFrac];
                
                // Set the current path to use it
                self.path.curPostId = [newPost postId];
                self.path.srcCoord = newPost.coord;
                curPost = newPost;
            }
            [self setCoordinate:_path.srcCoord];
            
            // if state is invalid, this is a restore on a newly installed phone
            // since server doesn't store state, state is dependent on whether flyer is arriving at a MyTradePost or a ForeignPost
            if(kFlyerStateInvalid == [self state])
            {
                if([curPost isMemberOfClass:[MyTradePost class]])
                {
                    // if my post, skip forward to unloading done because player had already made the earnings
                    [self gotoState:kFlyerStateIdle];
                }
                else
                {
                    // otherwise, skip to Loaded to keep it simple
                    [self gotoState:kFlyerStateLoaded];
                }
            }
            
            // attach myself to the post I'm at
            curPost.flyerAtPost = self;
        }
        else
        {
            CLLocationCoordinate2D curCoord = [self flyerCoordinateNow];
            [self setCoordinate:curCoord];
            [self createFlightPathRenderingForFlyer];
            [self gotoState:kFlyerStateEnroute];
            [[[GameManager getInstance] gameViewController].mapControl addAnnotationForFlyer:self];
        }
        self.initializeFlyerOnMap = TRUE;
    }
    
    // if newly purchased, unset it because after this, the flyer is ready for primetime
    if(_isNewlyPurchased)
    {
        _isNewlyPurchased = NO;
    }
}

- (BOOL) departForPostId:(NSString *)postId
{
    BOOL success = NO;
  
    {
        success = [_path departForPostId:postId userFlyerId:_userFlyerId];
        if (success)
        {
            TradePost* curPost = [[TradePostMgr getInstance] getTradePostWithId:_path.curPostId];
            curPost.flyerAtPost = nil;
            
            [_inventory updateFlyerInventoryOnServer:_userFlyerId];
            [self createFlightPathRenderingForFlyer];
            [self gotoState:kFlyerStateEnroute];
            [[[[GameManager getInstance] gameViewController] mapControl] addAnnotationForFlyer:self];
            
            // Log the departure
            NSString* currentPostType;
            if([curPost isMemberOfClass:[MyTradePost class]])
            {
                currentPostType = @"Self";
            }
            else if([curPost isMemberOfClass:[NPCTradePost class]])
            {
                currentPostType = @"NPC";
            }
            else
            {
                if ([[BeaconMgr getInstance] isPostABeacon:curPost.postId])
                {
                    currentPostType = @"Beacon";
                }
                else
                {
                    currentPostType = @"Foreign";
                }
            }
            [MetricLogger logDepartEvent:[[[[FlyerTypes getInstance] flyerTypes] objectAtIndex:_flyerTypeIndex] flyerId]
                                postType:currentPostType];
        }
    }
    return success;
}

- (void) completeFlyerPath
{
    NSLog(@"Flyer path completed");
    
    // track distance
    CLLocationDistance routeDist = metersDistance([_path srcCoord], [_path destCoord]);
    [_inventory incrementTravelDistance:routeDist];
    
    // Log arrival
    [MetricLogger logArriveEvent:routeDist numItems:[_inventory numItems] itemType:[_inventory itemId]];
    
    // ask TradeManager to handle arrival
    TradePost* arrivalPost = [[TradePostMgr getInstance] getTradePostWithId:[_path nextPostId]];
    if([arrivalPost isMemberOfClass:[MyTradePost class]])
    {
        [self gotoState:kFlyerStateWaitingToUnload];
    }
    else
    {
        [self gotoState:kFlyerStateWaitingToLoad];
    }
    MapControl* mapControl = [[[GameManager getInstance] gameViewController] mapControl];
    [mapControl deselectAnnotation:arrivalPost animated:NO];
    [[TradeManager getInstance] flyer:self didArriveAtPost:arrivalPost];
    _metersToDest = 0.0;
    [_path completeFlyerPath:_userFlyerId];
    [_inventory updateFlyerInventoryOnServer:_userFlyerId];
    [mapControl dismissFlightPathForFlyer:self];
    self.flightPathRender = nil;
    [mapControl dismissAnnotationForFlyer:self];
    arrivalPost.flyerAtPost = self;
    
    // restore to background_default music
    [[SoundManager getInstance] playMusic:@"background_default" doLoop:YES];
}

static const NSTimeInterval kMinFlightTime = 3; // seconds

// returns a speed such that travel time is at least min-flighttime
- (float) adjustedSpeedForRouteDist:(CLLocationDistance)dist
{
    float speed = [self getFlyerSpeed];
    NSTimeInterval routeTime = dist / speed;
    if(routeTime < kMinFlightTime)
    {
        speed = dist / ((float)kMinFlightTime);
    }
    return speed;
}

- (void) updateAtDate:(NSDate *)currentTime
{
    if(!_initializeFlyerOnMap)
    {
        // do nothing for flyer not yet initialized on the map
    }
    else
    {
        if(!_path.doneWithCurrentPath)
        {
            // enroute
            NSTimeInterval elapsed = -[_path.departureDate timeIntervalSinceNow];
            CLLocationDistance routeDist = metersDistance([_path srcCoord], [_path destCoord]);
            float speed = [self adjustedSpeedForRouteDist:routeDist];
            if(speed < [self getFlyerSpeed])
            {
                // adjusts flight-time by changing elapsed
                elapsed *= (speed / [self getFlyerSpeed]);
            }
            CLLocationCoordinate2D curCoord = [self flyerCoordinateAtTimeSinceDeparture:elapsed];
            [self setCoordinate:curCoord];
            
            if([self flightPathRender])
            {
                [self.flightPathRender setCurCoord:curCoord];
            }
            
            self.metersToDest = routeDist - (elapsed * [self getFlyerSpeed]);
            if(self.metersToDest <= 0.0)
            {
                [self completeFlyerPath];
            }
        }
        else if((kFlyerStateUnloading == [self state]) || (kFlyerStateLoading == [self state]))
        {
            NSTimeInterval elapsed = [currentTime timeIntervalSinceDate:_stateBegin];
            if(elapsed > [self getFlyerLoadDuration])
            {
                // done
                if(kFlyerStateUnloading == [self state])
                {
                    [self gotoState:kFlyerStateIdle];
                }
                else
                {
                    [self gotoState:kFlyerStateLoaded];
                }
            }
            else
            {
                NSTimeInterval noteElapsed = [currentTime timeIntervalSinceDate:_lastLoadTimerChanged];
                if(noteElapsed >= 1.0f)
                {
                    _lastLoadTimerChanged = currentTime;
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGameNoteFlyerLoadTimerChanged object:self];
                }
            }
        }
    }
}

- (NSTimeInterval) timeTillDest
{
    CLLocationDistance routeDist = metersDistance([_path srcCoord], [_path destCoord]);
    NSTimeInterval time = [self metersToDest] / [self adjustedSpeedForRouteDist:routeDist];
    if(time <= 0.0)
    {
        time = 0.0;
    }
    return time;
}

- (void) refreshImageInAnnotationView:(FlyerAnnotationView *)annotationView
{
    UIImage* image = [self imageForCurrentState];
    if(kFlyerStateEnroute == [self state])
    {
        [annotationView setOrientedImage:image];
    }
    else
    {
        [annotationView setImage:image];
    }
}

- (UIImage*) imageForCurrentState
{
    NSString* imageName;
    if(kFlyerStateEnroute == [self state])
    {
        NSString* flyerTypeName = [[FlyerTypes getInstance] topImgForFlyerTypeAtIndex:[self flyerTypeIndex]];
        imageName = [[FlyerLabFactory getInstance] topImageForFlyerTypeNamed:flyerTypeName tier:[self curUpgradeTier] colorIndex:[self curColor]];
    }
    else
    {
        NSString* flyerTypeName = [[FlyerTypes getInstance] sideImgForFlyerTypeAtIndex:[self flyerTypeIndex]];
        imageName = [[FlyerLabFactory getInstance] sideImageForFlyerTypeNamed:flyerTypeName tier:[self curUpgradeTier] colorIndex:[self curColor]];
    }
    UIImage* image = [[ImageManager getInstance] getImage:imageName];
    return image;
}

- (NSString*) displayNameOfFlyerState
{
    NSString* result = nil;
    unsigned int queryState = [self state];
    if(kFlyerStateNum > queryState)
    {
        NSString* const names[kFlyerStateNum] =
        {
            @"Ready",
            @"Enroute",
            @"Waiting",
            @"Loading",
            @"Ready",
            @"Waiting",
            @"Unloading",
        };
        
        result = names[queryState];
    }
    else
    {
        result = @"";
    }
    return result;
}

#pragma mark - flight private
static CLLocationDistance metersDistance(CLLocationCoordinate2D originCoord, CLLocationCoordinate2D destCoord)
{
    MKMapPoint origin = MKMapPointForCoordinate(originCoord);
    MKMapPoint dest = MKMapPointForCoordinate(destCoord);
    CLLocationDistance dist = MKMetersBetweenMapPoints(origin, dest);
    
    return dist;
}

- (CLLocationCoordinate2D) flyerCoordinateAtTimeSinceDeparture:(NSTimeInterval)elapsed
{
    CLLocationCoordinate2D coordNow = [_path srcCoord];
    if([_path departureDate] != nil)
    {
        CLLocationDistance distMeters = metersDistance([_path srcCoord], [_path destCoord]);
        MKMapPoint srcPoint = MKMapPointForCoordinate([_path srcCoord]);
        MKMapPoint destPoint = MKMapPointForCoordinate([_path destCoord]);
        MKMapPoint routeVec = MKMapPointMake(destPoint.x - srcPoint.x, destPoint.y - srcPoint.y);
        double distPoints = sqrt((routeVec.x * routeVec.x) + (routeVec.y * routeVec.y));
        MKMapPoint routeVecNormalized = MKMapPointMake(routeVec.x / distPoints, routeVec.y / distPoints);
        
        CLLocationDistance distTraveledMeters = [self getFlyerSpeed] * elapsed;
        if(distTraveledMeters < distMeters)
        {
            double distTraveledPoints = (distTraveledMeters / distMeters) * distPoints;
            MKMapPoint curPoint = MKMapPointMake(srcPoint.x + (distTraveledPoints * routeVecNormalized.x),
                                                 srcPoint.y + (distTraveledPoints * routeVecNormalized.y));
            coordNow = MKCoordinateForMapPoint(curPoint);
        }
        else 
        {
            // flyer is already at destination, just return the destination coordinate
            coordNow = [_path destCoord];
        }
    }
    return coordNow;    
}

- (CLLocationCoordinate2D) flyerCoordinateNow
{
    NSTimeInterval elapsed = -[_path.departureDate timeIntervalSinceNow];
    CLLocationCoordinate2D coordNow = [self flyerCoordinateAtTimeSinceDeparture:elapsed];
    return coordNow;
}

- (CLLocationCoordinate2D) flyerCoordinateAtTimeAhead:(NSTimeInterval)timeAhead
{
    NSTimeInterval elapsed = -[_path.departureDate timeIntervalSinceNow];
    elapsed += timeAhead;
    CLLocationCoordinate2D coordNow = [self flyerCoordinateAtTimeSinceDeparture:elapsed];
    return coordNow;
}

// returns YES if state changed; NO if no change;
- (BOOL) gotoState:(unsigned int)newState
{
    BOOL changed = NO;
    
    if([self state] != newState)
    {
        // enforce state transition rules
        BOOL canChange = NO;
        switch(newState)
        {
            case kFlyerStateIdle:
                if((kFlyerStateUnloading == [self state]) ||
                   (kFlyerStateInvalid == [self state]))
                {
                    canChange = YES;
                }
                break;
                
            case kFlyerStateEnroute:
                if((kFlyerStateIdle == [self state]) ||
                   (kFlyerStateLoaded == [self state]) ||
                   (kFlyerStateInvalid == [self state]))
                {
                    canChange = YES;
                }
                break;
                
            case kFlyerStateWaitingToLoad:
                if((kFlyerStateEnroute == [self state]) ||
                   (kFlyerStateInvalid == [self state]))
                {
                    canChange = YES;
                }
                
            case kFlyerStateLoading:
                if(kFlyerStateWaitingToLoad == [self state])
                {
                    canChange = YES;
                }
                break;
                
            case kFlyerStateLoaded:
                if((kFlyerStateLoading == [self state]) ||
                   (kFlyerStateInvalid == [self state]))
                {
                    canChange = YES;
                }
                break;
                
            case kFlyerStateWaitingToUnload:
                if((kFlyerStateEnroute == [self state]) ||
                   (kFlyerStateInvalid == [self state]))
                {
                    canChange = YES;
                }
                break;
                
            case kFlyerStateUnloading:
                if(kFlyerStateWaitingToUnload == [self state])
                {
                    canChange = YES;
                }
                break;
                
            default:
                // do nothing
                break;
        }
        
        if(canChange)
        {
            NSLog(@"FlyerState Changed: %@ to %@", [self nameOfFlyerState:[self state]], [self nameOfFlyerState:newState]);
            if((kFlyerStateLoading == newState) || (kFlyerStateUnloading == newState))
            {
                _lastLoadTimerChanged = [NSDate date];
                [[NSNotificationCenter defaultCenter] postNotificationName:kGameNoteFlyerLoadTimerChanged object:self];
            }
            
            // game events
            if(kFlyerStateLoaded == newState)
            {                
                self.gameEvent = [[GameEventMgr getInstance] queueEventWithType:kGameEvent_LoadingCompleted atCoord:[self coord]];
            }
            else if((kFlyerStateIdle == newState) && (kFlyerStateUnloading == [self state]))
            {
                // display notification, but don't show alert icon (so, set gameEvent as nil)
                [[GameEventMgr getInstance] queueEventWithType:kGameEvent_UnloadingCompleted atCoord:[self coord]];
                self.gameEvent = nil;
            }
            else if((kFlyerStateWaitingToLoad == newState) || (kFlyerStateWaitingToUnload == newState))
            {
                self.gameEvent = [[GameEventMgr getInstance] queueEventWithType:kGameEvent_FlyerArrival atCoord:[self coord]];
            }
            else
            {
                self.gameEvent = nil;
            }
            
            self.state = newState;
            self.stateBegin = [NSDate date];
            changed = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:kGameNoteFlyerStateChanged object:self];
            
        }
        else
        {
            NSLog(@"FlyerState Warning: cannot go from %@ to %@", [self nameOfFlyerState:[self state]], [self nameOfFlyerState:newState]);
        }
    }
    return changed;
}

- (NSString*) nameOfFlyerState:(unsigned int)queryState
{
    NSString* result = nil;
    if(kFlyerStateNum > queryState)
    {
        NSString* const names[kFlyerStateNum] =
        {
            @"kFlyerStateIdle",
            @"kFlyerStateEnroute",
            @"kFlyerStateWaitingToLoad",
            @"kFlyerStateLoading",
            @"kFlyerStateLoaded",
            @"kFlyerStateWaitingToUnload",
            @"kFlyerStateUnloading",
        };
        
        result = names[queryState];
    }
    else
    {
        result = @"kFlyerStateInvalid";
    }
    return result;
}



#pragma mark - MKAnnotation delegate
- (CLLocationCoordinate2D) coordinate
{
    return [self coord];
}

- (void) setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    self.coord = newCoordinate;
}

#pragma mark - MapAnnotationProtocol
- (MKAnnotationView*) annotationViewInMap:(MKMapView *)mapView
{
    FlyerAnnotationView* annotationView = (FlyerAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:kFlyerAnnotationViewReuseId];
    if(annotationView)
    {
        annotationView.annotation = self;
    }
    else
    {
        annotationView = [[FlyerAnnotationView alloc] initWithAnnotation:self];
    }
    
    // set image
    [self refreshImageInAnnotationView:annotationView];

    if([mapView isPreviewMap])
    {
        // for preview map, annotation views are disabled
        // countdown not shown
        annotationView.enabled = NO;
        [annotationView showCountdown:NO];
    }
    else
    {
        // otherwise, follow these rules
        if([_path isEnroute])
        {
            [annotationView showCountdown:YES];
        }
        else
        {
            [annotationView showCountdown:NO];
        }
    }

    return annotationView;
}


@end
